{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('SpecialOffer') }}
),

typed as (
    select
        cast(specialofferid as integer) as special_offer_id,
        cast(description as varchar) as description,
        cast(discountpct as decimal(19, 4)) as discount_pct,
        cast(type as varchar) as offer_type,
        cast(category as varchar) as offer_category,
        cast(startdate as timestamp) as start_date,
        cast(enddate as timestamp) as end_date,
        cast(minqty as integer) as min_qty,
        cast(maxqty as integer) as max_qty,
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
        coalesce(nullif(upper(trim(cast(special_offer_id as varchar))), ''), 'NULL')
    ) as special_offer_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(special_offer_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(description as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(discount_pct as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(offer_type as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(offer_category as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(start_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(end_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(min_qty as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(max_qty as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as special_offer_hashdiff,
    special_offer_id,
    description,
    discount_pct,
    offer_type,
    offer_category,
    start_date,
    end_date,
    min_qty,
    max_qty,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
