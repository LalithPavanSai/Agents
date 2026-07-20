{{
    config(
        materialized='incremental',
        unique_key=['geography_alternate_key', 'effective_start_date'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with addr as (
    select * from {{ ref('stg_person__address') }}
),

sp as (
    select
        state_province_id,
        state_province_code,
        state_province_name,
        country_region_code,
        territory_id
    from {{ ref('stg_person__state_province') }}
    where is_current = true
),

cr as (
    select
        country_region_code,
        country_region_name
    from {{ ref('stg_person__country_region') }}
    where is_current = true
),

source as (
    select
        a.address_id,
        a.city,
        sp.state_province_code,
        sp.state_province_name,
        cr.country_region_code,
        cr.country_region_name  as english_country_region_name,
        a.postal_code,
        sp.territory_id         as sales_territory_id,
        a.address_hashdiff      as geography_hashdiff,
        a.effective_start_date,
        a.record_source,
        a.load_dts
    from addr a
    left join sp  on a.state_province_id = sp.state_province_id
    left join cr  on sp.country_region_code = cr.country_region_code
)

{% if is_incremental() %}

, changed as (
    select s.*
    from source s
    inner join {{ this }} d
        on s.address_id = d.geography_alternate_key
        and d.is_current = true
    where s.geography_hashdiff != d.geography_hashdiff
),

new_records as (
    select s.*
    from source s
    left join {{ this }} d on s.address_id = d.geography_alternate_key
    where d.geography_alternate_key is null
),

records_to_close as (
    select
        d.geography_key,
        d.geography_alternate_key,
        d.city,
        d.state_province_code,
        d.state_province_name,
        d.country_region_code,
        d.english_country_region_name,
        d.postal_code,
        d.sales_territory_id,
        d.geography_hashdiff,
        d.effective_start_date,
        c.effective_start_date   as effective_end_date,
        false                    as is_current,
        d.record_source,
        d.load_dts
    from {{ this }} d
    inner join changed c
        on d.geography_alternate_key = c.address_id
    where d.is_current = true
),

incoming as (
    select * from changed
    union all
    select * from new_records
),

new_versions as (
    select
        (select coalesce(max(geography_key), 0) from {{ this }})
            + row_number() over (order by address_id) as geography_key,
        address_id               as geography_alternate_key,
        city,
        state_province_code,
        state_province_name,
        country_region_code,
        english_country_region_name,
        postal_code,
        sales_territory_id,
        geography_hashdiff,
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
    row_number() over (order by address_id) as geography_key,
    address_id               as geography_alternate_key,
    city,
    state_province_code,
    state_province_name,
    country_region_code,
    english_country_region_name,
    postal_code,
    sales_territory_id,
    geography_hashdiff,
    effective_start_date,
    cast('9999-12-31' as timestamp) as effective_end_date,
    true                     as is_current,
    record_source,
    load_dts
from source

{% endif %}
