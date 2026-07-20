{{
    config(
        materialized='incremental',
        unique_key=['sales_order_number', 'sales_order_line_number', 'sales_reason_key'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with sohsr as (
    
    select
        sales_order_id,
        sales_reason_id,
        record_source,
        load_dts
    from {{ ref('stg_sales__sales_order_header_sales_reason') }}
),

soh as (
    
    select
        sales_order_id,
        sales_order_number
    from {{ ref('stg_sales__sales_order_header') }}
    where is_current = true
),

sod as (
    
    select
        sales_order_id,
        sales_order_detail_id as sales_order_line_number
    from {{ ref('stg_sales__sales_order_detail') }}
),

dim_reason as (
    select
        sales_reason_key,
        sales_reason_alternate_key
    from {{ ref('dim_sales_reason') }}
    where is_current = true
),

expanded as (
    select
        soh.sales_order_number,
        sod.sales_order_line_number,
        coalesce(dr.sales_reason_key, 0)  as sales_reason_key,
        sohsr.record_source,
        sohsr.load_dts
    from sohsr
    
    inner join soh
        on sohsr.sales_order_id = soh.sales_order_id
    
    inner join sod
        on sohsr.sales_order_id = sod.sales_order_id
    
    left join dim_reason dr
        on sohsr.sales_reason_id = dr.sales_reason_alternate_key

    {% if is_incremental() %}
    
    where not exists (
        select 1
        from {{ this }} existing
        where existing.sales_order_number      = soh.sales_order_number
          and existing.sales_order_line_number = sod.sales_order_line_number
          and existing.sales_reason_key        = coalesce(dr.sales_reason_key, 0)
    )
    {% endif %}
)

select * from expanded
