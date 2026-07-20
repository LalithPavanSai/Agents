{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('Person') }}
),

typed as (
    select
        cast(businessentityid as integer) as business_entity_id,
        cast(persontype as varchar) as person_type,
        cast(namestyle as boolean) as name_style,
        cast(title as varchar) as title,
        cast(firstname as varchar) as first_name,
        cast(middlename as varchar) as middle_name,
        cast(lastname as varchar) as last_name,
        cast(suffix as varchar) as suffix,
        cast(emailpromotion as integer) as email_promotion,
        cast(additionalcontactinfo as varchar) as additional_contact_info,
        cast(demographics as varchar) as demographics,
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
        coalesce(nullif(upper(trim(cast(business_entity_id as varchar))), ''), 'NULL')
    ) as person_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(business_entity_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(person_type as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(name_style as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(title as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(first_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(middle_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(last_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(suffix as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(email_promotion as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as person_hashdiff,
    business_entity_id,
    person_type,
    name_style,
    title,
    first_name,
    middle_name,
    last_name,
    suffix,
    email_promotion,
    additional_contact_info,
    demographics,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
