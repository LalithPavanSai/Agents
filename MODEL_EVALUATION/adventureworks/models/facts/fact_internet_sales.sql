{{
    config(
        materialized='incremental',
        unique_key=['sales_order_number', 'sales_order_line_number'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with sod as (
    select * from {{ ref('stg_sales__sales_order_detail') }}
),

soh as (
    select * from {{ ref('stg_sales__sales_order_header') }}
    where is_current = true
),

stg_prod as (
    select product_id, product_number
    from {{ ref('stg_production__product') }}
    where is_current = true
),

stg_cust as (
    select customer_id, account_number
    from {{ ref('stg_sales__customer') }}
    where is_current = true
),

pch as (
    select
        product_id,
        standard_cost,
        start_date,
        coalesce(end_date, cast('9999-12-31' as timestamp)) as end_date
    from {{ ref('stg_production__product_cost_history') }}
),

dim_prod as (
    select product_key, product_alternate_key
    from {{ ref('dim_product') }}
    where is_current = true
),

dim_cust as (
    select customer_key, customer_alternate_key
    from {{ ref('dim_customer') }}
    where is_current = true
),

dim_promo as (
    select promotion_key, promotion_alternate_key
    from {{ ref('dim_promotion') }}
    where is_current = true
),

dim_terr as (
    select sales_territory_key, sales_territory_alternate_key
    from {{ ref('dim_sales_territory') }}
    where is_current = true
),

dim_curr_usd as (
    select currency_key
    from {{ ref('dim_currency') }}
    where is_current = true
    and upper(currency_alternate_key) = 'USD'
    limit 1
),

fact_lines as (
    select
        
        coalesce(dp.product_key,   0)  as product_key,

        
        soh.order_date_key,
        soh.due_date_key,
        coalesce(soh.ship_date_key, 0) as ship_date_key,

        coalesce(dc.customer_key,  0)  as customer_key,
        coalesce(dpr.promotion_key, 0) as promotion_key,

        
        
        case
            when soh.currency_rate_id is null
                then coalesce((select currency_key from dim_curr_usd), 0)
            else 0
        end                            as currency_key,

        coalesce(dt.sales_territory_key, 0) as sales_territory_key,

        
        soh.sales_order_number,
        cast(sod.sales_order_detail_id as integer) as sales_order_line_number,
        cast(soh.revision_number as integer)       as revision_number,
        soh.purchase_order_number                  as customer_po_number,
        sod.carrier_tracking_number,

        
        soh.order_date,
        soh.due_date,
        soh.ship_date,

        
        cast(sod.order_qty as integer)              as order_quantity,

        cast(sod.unit_price as decimal(19, 4))      as unit_price,

        
        cast(sod.unit_price * sod.order_qty as decimal(19, 4)) as extended_amount,

        
        cast(sod.unit_price_discount as decimal(7, 4)) as unit_price_discount_pct,

        
        cast(
            sod.unit_price_discount * sod.unit_price * sod.order_qty
        as decimal(19, 4))                          as discount_amount,

        
        
        cast(
            coalesce(pch_join.standard_cost, 0)
        as decimal(19, 4))                          as product_standard_cost,

        
        cast(
            coalesce(pch_join.standard_cost, 0) * sod.order_qty
        as decimal(19, 4))                          as total_product_cost,

        
        cast(sod.line_total as decimal(19, 4))      as sales_amount,

        
        
        cast(
            case
                when soh.subtotal > 0
                then soh.tax_amount * (sod.line_total / soh.subtotal)
                else 0
            end
        as decimal(19, 4))                          as tax_amt,

        cast(
            case
                when soh.subtotal > 0
                then soh.freight_amount * (sod.line_total / soh.subtotal)
                else 0
            end
        as decimal(19, 4))                          as freight,

        
        greatest(soh.modified_date, sod.modified_date) as modified_date_watermark,
        sod.record_source,
        sod.load_dts

    from sod

    
    inner join soh
        on sod.sales_order_id = soh.sales_order_id

    
    left join pch pch_join
        on sod.product_id   = pch_join.product_id
        and soh.order_date >= pch_join.start_date
        and soh.order_date  < pch_join.end_date

    
    left join stg_prod sp
        on sod.product_id = sp.product_id

    
    left join stg_cust sc
        on soh.customer_id = sc.customer_id

    
    left join dim_prod  dp   on sp.product_number            = dp.product_alternate_key
    left join dim_cust  dc   on sc.account_number            = dc.customer_alternate_key
    left join dim_promo dpr  on sod.special_offer_id         = dpr.promotion_alternate_key
    left join dim_terr  dt   on soh.territory_id             = dt.sales_territory_alternate_key

    {% if is_incremental() %}
    
    
    
    
    
    where not exists (
        select 1
        from {{ this }} existing
        where existing.sales_order_number     = soh.sales_order_number
          and existing.sales_order_line_number = sod.sales_order_detail_id
    )
    {% endif %}
)

select * from fact_lines
