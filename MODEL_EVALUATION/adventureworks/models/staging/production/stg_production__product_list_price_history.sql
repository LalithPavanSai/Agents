{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('ProductListPriceHistory') }}
),

typed as (
    select
        cast(productid as integer) as product_id,
        cast(startdate as timestamp) as start_date,
        cast(enddate as timestamp) as end_date,
        cast(listprice as decimal(19, 4)) as list_price,
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
            coalesce(nullif(upper(trim(cast(product_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(start_date as varchar))), ''), 'NULL')
        )
    ) as product_list_price_history_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(product_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(start_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(end_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(list_price as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as product_list_price_history_hashdiff,
    product_id,
    start_date,
    end_date,
    list_price,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
