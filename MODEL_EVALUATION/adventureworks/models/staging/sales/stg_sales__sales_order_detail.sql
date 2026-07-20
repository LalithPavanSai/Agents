{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('SalesOrderDetail') }}
),

typed as (
    select
        cast(salesorderid as integer) as sales_order_id,
        cast(salesorderdetailid as integer) as sales_order_detail_id,
        cast(carriertrackingnumber as varchar) as carrier_tracking_number,
        cast(orderqty as smallint) as order_qty,
        cast(productid as integer) as product_id,
        cast(specialofferid as integer) as special_offer_id,
        cast(unitprice as decimal(19, 4)) as unit_price,
        cast(unitpricediscount as decimal(19, 4)) as unit_price_discount,
        cast(linetotal as decimal(19, 4)) as line_total,
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
            coalesce(nullif(upper(trim(cast(sales_order_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sales_order_detail_id as varchar))), ''), 'NULL')
        )
    ) as sales_order_detail_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(sales_order_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sales_order_detail_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(carrier_tracking_number as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(order_qty as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(special_offer_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(unit_price as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(unit_price_discount as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(line_total as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as sales_order_detail_hashdiff,
    sales_order_id,
    sales_order_detail_id,
    carrier_tracking_number,
    order_qty,
    product_id,
    special_offer_id,
    unit_price,
    unit_price_discount,
    line_total,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
