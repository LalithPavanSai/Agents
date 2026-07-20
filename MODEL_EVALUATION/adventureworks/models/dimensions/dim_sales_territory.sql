{{
    config(
        materialized='incremental',
        unique_key=['sales_territory_alternate_key', 'effective_start_date'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with territory as (
    select * from {{ ref('stg_sales__sales_territory') }}
),

country as (
    select
        country_region_code,
        country_region_name
    from {{ ref('stg_person__country_region') }}
    where is_current = true
),

source as (
    select
        t.territory_id,
        t.territory_name,
        t.country_region_code,
        coalesce(c.country_region_name, t.country_region_code) as sales_territory_country,
        t.territory_group,
        t.sales_ytd,
        t.sales_last_year,
        t.cost_ytd,
        t.cost_last_year,
        t.sales_territory_hashdiff,
        t.effective_start_date,
        t.effective_end_date,
        t.is_current,
        t.record_source,
        t.load_dts
    from territory t
    left join country c on t.country_region_code = c.country_region_code
)

{% if is_incremental() %}

, changed as (
    select s.*
    from source s
    inner join {{ this }} d
        on s.territory_id = d.sales_territory_alternate_key
        and d.is_current = true
    where s.sales_territory_hashdiff != d.sales_territory_hashdiff
),

new_records as (
    select s.*
    from source s
    left join {{ this }} d on s.territory_id = d.sales_territory_alternate_key
    where d.sales_territory_alternate_key is null
),

records_to_close as (
    select
        d.sales_territory_key,
        d.sales_territory_alternate_key,
        d.sales_territory_region,
        d.sales_territory_country,
        d.sales_territory_group,
        d.sales_ytd,
        d.sales_last_year,
        d.cost_ytd,
        d.cost_last_year,
        d.sales_territory_hashdiff,
        d.effective_start_date,
        c.effective_start_date   as effective_end_date,
        false                    as is_current,
        d.record_source,
        d.load_dts
    from {{ this }} d
    inner join changed c
        on d.sales_territory_alternate_key = c.territory_id
    where d.is_current = true
),

incoming as (
    select * from changed
    union all
    select * from new_records
),

new_versions as (
    select
        (select coalesce(max(sales_territory_key), 0) from {{ this }})
            + row_number() over (order by territory_id) as sales_territory_key,
        territory_id             as sales_territory_alternate_key,
        territory_name           as sales_territory_region,
        sales_territory_country,
        territory_group          as sales_territory_group,
        sales_ytd,
        sales_last_year,
        cost_ytd,
        cost_last_year,
        sales_territory_hashdiff,
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
    row_number() over (order by territory_id) as sales_territory_key,
    territory_id             as sales_territory_alternate_key,
    territory_name           as sales_territory_region,
    sales_territory_country,
    territory_group          as sales_territory_group,
    sales_ytd,
    sales_last_year,
    cost_ytd,
    cost_last_year,
    sales_territory_hashdiff,
    effective_start_date,
    cast('9999-12-31' as timestamp) as effective_end_date,
    true                     as is_current,
    record_source,
    load_dts
from source

{% endif %}
