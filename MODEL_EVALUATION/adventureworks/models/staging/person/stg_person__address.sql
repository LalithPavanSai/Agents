{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('Address') }}
),

typed as (
    select
        cast(addressid as integer) as address_id,
        cast(addressline1 as varchar) as address_line1,
        cast(addressline2 as varchar) as address_line2,
        cast(city as varchar) as city,
        cast(stateprovinceid as integer) as state_province_id,
        cast(postalcode as varchar) as postal_code,
        cast(spatiallocation as varchar) as spatial_location,
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
        coalesce(nullif(upper(trim(cast(address_id as varchar))), ''), 'NULL')
    ) as address_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(address_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(address_line1 as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(address_line2 as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(city as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(state_province_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(postal_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as address_hashdiff,
    address_id,
    address_line1,
    address_line2,
    city,
    state_province_id,
    postal_code,
    spatial_location,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
