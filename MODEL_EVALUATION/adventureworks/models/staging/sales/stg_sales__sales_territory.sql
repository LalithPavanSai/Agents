{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('SalesTerritory') }}
),

typed as (
    select
        cast(territoryid as integer) as territory_id,
        cast(name as varchar) as territory_name,
        cast(countryregioncode as varchar) as country_region_code,
        cast("group" as varchar) as territory_group,
        cast(salesytd as decimal(19, 4)) as sales_ytd,
        cast(saleslastyear as decimal(19, 4)) as sales_last_year,
        cast(costytd as decimal(19, 4)) as cost_ytd,
        cast(costlastyear as decimal(19, 4)) as cost_last_year,
        cast(rowguid as varchar) as rowguid,
        cast(modifieddate as timestamp) as modified_date,
        cast(record_source as varchar) as record_source,
        cast(load_dts as timestamp) as load_dts
    from source
),

derived as (
    select
        *,
        modified_date as effective_start_date,
        cast('9999-12-31' as timestamp) as effective_end_date,
        true as is_current
    from typed
)

select
    sha256(
        coalesce(nullif(upper(trim(cast(territory_id as varchar))), ''), 'NULL')
    ) as sales_territory_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(territory_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(territory_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(country_region_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(territory_group as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sales_ytd as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sales_last_year as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(cost_ytd as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(cost_last_year as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as sales_territory_hashdiff,
    territory_id,
    territory_name,
    country_region_code,
    territory_group,
    sales_ytd,
    sales_last_year,
    cost_ytd,
    cost_last_year,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
