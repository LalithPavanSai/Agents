{{
    config(
        materialized='incremental',
        unique_key=['product_alternate_key', 'effective_start_date'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with product as (
    select * from {{ ref('stg_production__product') }}
),

subcategory as (
    select
        product_subcategory_id,
        subcategory_name,
        product_category_id
    from {{ ref('stg_production__product_subcategory') }}
    where is_current = true
),

category as (
    select
        product_category_id,
        category_name
    from {{ ref('stg_production__product_category') }}
    where is_current = true
),

model as (
    select
        product_model_id,
        model_name,
        catalog_description
    from {{ ref('stg_production__product_model') }}
    where is_current = true
),

source as (
    select
        p.product_id,
        p.product_number,
        p.product_name         as english_product_name,
        p.standard_cost,
        p.finished_goods_flag,
        p.color,
        p.safety_stock_level,
        p.reorder_point,
        p.list_price,
        p.size,
        p.size_unit_measure_code,
        p.weight_unit_measure_code,
        p.weight,
        p.days_to_manufacture,
        p.product_line,
        p.product_class        as class,
        p.style,
        p.sell_start_date      as start_date,
        p.sell_end_date        as end_date,
        case
            when p.sell_end_date is null or p.sell_end_date > current_date then 'Current'
            else 'Expired'
        end                    as status,
        p.product_subcategory_id,
        coalesce(sc.subcategory_name, 'NA')  as product_subcategory_name,
        coalesce(cat.category_name, 'NA')    as product_category_name,
        coalesce(m.model_name, 'NA')         as model_name,
        coalesce(m.catalog_description, '')  as english_description,
        p.product_hashdiff,
        p.effective_start_date,
        p.record_source,
        p.load_dts
    from product p
    left join subcategory sc  on p.product_subcategory_id = sc.product_subcategory_id
    left join category    cat on sc.product_category_id   = cat.product_category_id
    left join model       m   on p.product_model_id       = m.product_model_id
)

{% if is_incremental() %}

, changed as (
    select s.*
    from source s
    inner join {{ this }} d
        on s.product_number = d.product_alternate_key
        and d.is_current = true
    where s.product_hashdiff != d.product_hashdiff
),

new_records as (
    select s.*
    from source s
    left join {{ this }} d on s.product_number = d.product_alternate_key
    where d.product_alternate_key is null
),

records_to_close as (
    select
        d.product_key,
        d.product_alternate_key,
        d.english_product_name,
        d.standard_cost,
        d.finished_goods_flag,
        d.color,
        d.safety_stock_level,
        d.reorder_point,
        d.list_price,
        d.size,
        d.size_unit_measure_code,
        d.weight_unit_measure_code,
        d.weight,
        d.days_to_manufacture,
        d.product_line,
        d.class,
        d.style,
        d.start_date,
        d.end_date,
        d.status,
        d.product_subcategory_id,
        d.product_subcategory_name,
        d.product_category_name,
        d.model_name,
        d.english_description,
        d.product_hashdiff,
        d.effective_start_date,
        c.effective_start_date   as effective_end_date,
        false                    as is_current,
        d.record_source,
        d.load_dts
    from {{ this }} d
    inner join changed c
        on d.product_alternate_key = c.product_number
    where d.is_current = true
),

incoming as (
    select * from changed
    union all
    select * from new_records
),

new_versions as (
    select
        (select coalesce(max(product_key), 0) from {{ this }})
            + row_number() over (order by product_id) as product_key,
        product_number           as product_alternate_key,
        english_product_name,
        standard_cost,
        finished_goods_flag,
        color,
        safety_stock_level,
        reorder_point,
        list_price,
        size,
        size_unit_measure_code,
        weight_unit_measure_code,
        weight,
        days_to_manufacture,
        product_line,
        class,
        style,
        start_date,
        end_date,
        status,
        product_subcategory_id,
        product_subcategory_name,
        product_category_name,
        model_name,
        english_description,
        product_hashdiff,
        effective_start_date,
        cast('9999-12-31' as timestamp) as effective_end_date,
        true                     as is_current,
        record_source,
        load_dts
    from incoming
)

select * from records_to_close
union all
select * from new_versions

{% else %}

select
    row_number() over (order by product_id) as product_key,
    product_number           as product_alternate_key,
    english_product_name,
    standard_cost,
    finished_goods_flag,
    color,
    safety_stock_level,
    reorder_point,
    list_price,
    size,
    size_unit_measure_code,
    weight_unit_measure_code,
    weight,
    days_to_manufacture,
    product_line,
    class,
    style,
    start_date,
    end_date,
    status,
    product_subcategory_id,
    product_subcategory_name,
    product_category_name,
    model_name,
    english_description,
    product_hashdiff,
    effective_start_date,
    cast('9999-12-31' as timestamp) as effective_end_date,
    true                     as is_current,
    record_source,
    load_dts
from source

{% endif %}
