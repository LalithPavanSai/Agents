{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('SpecialOfferProduct') }}
),

typed as (
    select
        cast(specialofferid as integer) as special_offer_id,
        cast(productid as integer) as product_id,
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
            coalesce(nullif(upper(trim(cast(special_offer_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_id as varchar))), ''), 'NULL')
        )
    ) as special_offer_product_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(special_offer_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as special_offer_product_hashdiff,
    special_offer_id,
    product_id,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
