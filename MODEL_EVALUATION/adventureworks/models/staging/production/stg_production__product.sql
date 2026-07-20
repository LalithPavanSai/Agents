{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('Product') }}
),

typed as (
    select
        cast(productid as integer) as product_id,
        cast(name as varchar) as product_name,
        cast(productnumber as varchar) as product_number,
        cast(makeflag as boolean) as make_flag,
        cast(finishedgoodsflag as boolean) as finished_goods_flag,
        cast(color as varchar) as color,
        cast(safetystocklevel as smallint) as safety_stock_level,
        cast(reorderpoint as smallint) as reorder_point,
        cast(standardcost as decimal(19, 4)) as standard_cost,
        cast(listprice as decimal(19, 4)) as list_price,
        cast(size as varchar) as size,
        cast(sizeunitmeasurecode as varchar) as size_unit_measure_code,
        cast(weightunitmeasurecode as varchar) as weight_unit_measure_code,
        cast(weight as decimal(8, 2)) as weight,
        cast(daystomanufacture as integer) as days_to_manufacture,
        cast(productline as varchar) as product_line,
        cast(class as varchar) as product_class,
        cast(style as varchar) as style,
        cast(productsubcategoryid as integer) as product_subcategory_id,
        cast(productmodelid as integer) as product_model_id,
        cast(sellstartdate as timestamp) as sell_start_date,
        cast(sellenddate as timestamp) as sell_end_date,
        cast(discontinueddate as timestamp) as discontinued_date,
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
        coalesce(nullif(upper(trim(cast(product_number as varchar))), ''), 'NULL')
    ) as product_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(product_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_number as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(make_flag as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(finished_goods_flag as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(color as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(safety_stock_level as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(reorder_point as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(standard_cost as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(list_price as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(size as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(size_unit_measure_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(weight_unit_measure_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(weight as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(days_to_manufacture as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_line as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_class as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(style as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_subcategory_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_model_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sell_start_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sell_end_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(discontinued_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as product_hashdiff,
    product_id,
    product_name,
    product_number,
    make_flag,
    finished_goods_flag,
    color,
    safety_stock_level,
    reorder_point,
    standard_cost,
    list_price,
    size,
    size_unit_measure_code,
    weight_unit_measure_code,
    weight,
    days_to_manufacture,
    product_line,
    product_class,
    style,
    product_subcategory_id,
    product_model_id,
    sell_start_date,
    sell_end_date,
    discontinued_date,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
