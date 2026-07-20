{{
    config(
        materialized='incremental',
        unique_key=['promotion_alternate_key', 'effective_start_date'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with source as (
    select * from {{ ref('stg_sales__special_offer') }}
)

{% if is_incremental() %}

, changed as (
    select s.*
    from source s
    inner join {{ this }} d
        on s.special_offer_id = d.promotion_alternate_key
        and d.is_current = true
    where s.special_offer_hashdiff != d.promotion_hashdiff
),

new_records as (
    select s.*
    from source s
    left join {{ this }} d on s.special_offer_id = d.promotion_alternate_key
    where d.promotion_alternate_key is null
),

records_to_close as (
    select
        d.promotion_key,
        d.promotion_alternate_key,
        d.english_promotion_name,
        d.discount_pct,
        d.english_promotion_type,
        d.english_promotion_category,
        d.start_date,
        d.end_date,
        d.min_qty,
        d.max_qty,
        d.promotion_hashdiff,
        d.effective_start_date,
        c.effective_start_date   as effective_end_date,
        false                    as is_current,
        d.record_source,
        d.load_dts
    from {{ this }} d
    inner join changed c
        on d.promotion_alternate_key = c.special_offer_id
    where d.is_current = true
),

incoming as (
    select * from changed
    union all
    select * from new_records
),

new_versions as (
    select
        (select coalesce(max(promotion_key), 0) from {{ this }})
            + row_number() over (order by special_offer_id) as promotion_key,
        special_offer_id         as promotion_alternate_key,
        description              as english_promotion_name,
        discount_pct,
        offer_type               as english_promotion_type,
        offer_category           as english_promotion_category,
        start_date,
        end_date,
        min_qty,
        max_qty,
        special_offer_hashdiff   as promotion_hashdiff,
        effective_start_date,
        cast('9999-12-31' as timestamp) as effective_end_date,
        true                     as is_current,
        record_source,
        load_dts
    from incoming
)

select * from records_to_close
union all
select * from new_versions

{% else %}

select
    row_number() over (order by special_offer_id) as promotion_key,
    special_offer_id         as promotion_alternate_key,
    description              as english_promotion_name,
    discount_pct,
    offer_type               as english_promotion_type,
    offer_category           as english_promotion_category,
    start_date,
    end_date,
    min_qty,
    max_qty,
    special_offer_hashdiff   as promotion_hashdiff,
    effective_start_date,
    cast('9999-12-31' as timestamp) as effective_end_date,
    true                     as is_current,
    record_source,
    load_dts
from source

{% endif %}
