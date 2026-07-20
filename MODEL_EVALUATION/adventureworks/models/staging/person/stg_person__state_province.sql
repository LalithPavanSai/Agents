{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('StateProvince') }}
),

typed as (
    select
        cast(stateprovinceid as integer) as state_province_id,
        cast(stateprovincecode as varchar) as state_province_code,
        cast(countryregioncode as varchar) as country_region_code,
        cast(isonlystateprovinceflag as boolean) as is_only_state_province_flag,
        cast(name as varchar) as state_province_name,
        cast(territoryid as integer) as territory_id,
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
        coalesce(nullif(upper(trim(cast(state_province_id as varchar))), ''), 'NULL')
    ) as state_province_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(state_province_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(state_province_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(country_region_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(is_only_state_province_flag as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(state_province_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(territory_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as state_province_hashdiff,
    state_province_id,
    state_province_code,
    country_region_code,
    is_only_state_province_flag,
    state_province_name,
    territory_id,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
