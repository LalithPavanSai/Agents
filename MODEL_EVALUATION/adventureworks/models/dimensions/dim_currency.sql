{{
    config(
        materialized='incremental',
        unique_key=['currency_alternate_key', 'effective_start_date'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with source as (
    select * from {{ ref('stg_sales__currency') }}
)

{% if is_incremental() %}

, changed as (
    select s.*
    from source s
    inner join {{ this }} d
        on s.currency_code = d.currency_alternate_key
        and d.is_current = true
    where s.currency_hashdiff != d.currency_hashdiff
),

new_records as (
    select s.*
    from source s
    left join {{ this }} d on s.currency_code = d.currency_alternate_key
    where d.currency_alternate_key is null
),

records_to_close as (
    select
        d.currency_key,
        d.currency_alternate_key,
        d.currency_name,
        d.currency_hashdiff,
        d.effective_start_date,
        c.effective_start_date   as effective_end_date,
        false                    as is_current,
        d.record_source,
        d.load_dts
    from {{ this }} d
    inner join changed c
        on d.currency_alternate_key = c.currency_code
    where d.is_current = true
),

incoming as (
    select * from changed
    union all
    select * from new_records
),

new_versions as (
    select
        (select coalesce(max(currency_key), 0) from {{ this }})
            + row_number() over (order by currency_code) as currency_key,
        currency_code            as currency_alternate_key,
        currency_name,
        currency_hashdiff,
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
    row_number() over (order by currency_code) as currency_key,
    currency_code           as currency_alternate_key,
    currency_name,
    currency_hashdiff,
    effective_start_date,
    cast('9999-12-31' as timestamp) as effective_end_date,
    true                    as is_current,
    record_source,
    load_dts
from source

{% endif %}
