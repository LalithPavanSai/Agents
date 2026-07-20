{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('BusinessEntityAddress') }}
),

typed as (
    select
        cast(businessentityid as integer) as business_entity_id,
        cast(addressid as integer) as address_id,
        cast(addresstypeid as integer) as address_type_id,
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
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(business_entity_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(address_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(address_type_id as varchar))), ''), 'NULL')
        )
    ) as business_entity_address_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(business_entity_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(address_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(address_type_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as business_entity_address_hashdiff,
    business_entity_id,
    address_id,
    address_type_id,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
