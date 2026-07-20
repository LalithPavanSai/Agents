{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('EmailAddress') }}
),

typed as (
    select
        cast(businessentityid as integer) as business_entity_id,
        cast(emailaddressid as integer) as email_address_id,
        cast(emailaddress as varchar) as email_address,
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
            coalesce(nullif(upper(trim(cast(email_address_id as varchar))), ''), 'NULL')
        )
    ) as email_address_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(business_entity_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(email_address_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(email_address as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as email_address_hashdiff,
    business_entity_id,
    email_address_id,
    email_address,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
