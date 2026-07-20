{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('CountryRegion') }}
),

typed as (
    select
        cast(countryregioncode as varchar) as country_region_code,
        cast(name as varchar) as country_region_name,
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
        coalesce(nullif(upper(trim(cast(country_region_code as varchar))), ''), 'NULL')
    ) as country_region_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(country_region_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(country_region_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as country_region_hashdiff,
    country_region_code,
    country_region_name,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
