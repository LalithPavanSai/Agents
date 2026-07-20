{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('Customer') }}
),

typed as (
    select
        cast(customerid as integer) as customer_id,
        cast(personid as integer) as person_id,
        cast(storeid as integer) as store_id,
        cast(territoryid as integer) as territory_id,
        cast(accountnumber as varchar) as account_number,
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
        coalesce(nullif(upper(trim(cast(customer_id as varchar))), ''), 'NULL')
    ) as customer_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(customer_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(person_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(store_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(territory_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(account_number as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as customer_hashdiff,
    customer_id,
    person_id,
    store_id,
    territory_id,
    account_number,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
