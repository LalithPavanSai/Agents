{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('SalesOrderHeader') }}
),

typed as (
    select
        cast(salesorderid as integer) as sales_order_id,
        cast(revisionnumber as smallint) as revision_number,
        cast(orderdate as timestamp) as order_date,
        cast(duedate as timestamp) as due_date,
        cast(shipdate as timestamp) as ship_date,
        cast(status as smallint) as status,
        cast(onlineorderflag as boolean) as online_order_flag,
        cast(salesordernumber as varchar) as sales_order_number,
        cast(purchaseordernumber as varchar) as purchase_order_number,
        cast(accountnumber as varchar) as account_number,
        cast(customerid as integer) as customer_id,
        cast(salespersonid as integer) as sales_person_id,
        cast(territoryid as integer) as territory_id,
        cast(billtoaddressid as integer) as bill_to_address_id,
        cast(shiptoaddressid as integer) as ship_to_address_id,
        cast(shipmethodid as integer) as ship_method_id,
        cast(creditcardid as integer) as credit_card_id,
        cast(creditcardapprovalcode as varchar) as credit_card_approval_code,
        cast(currencyrateid as integer) as currency_rate_id,
        cast(subtotal as decimal(19, 4)) as subtotal,
        cast(taxamt as decimal(19, 4)) as tax_amount,
        cast(freight as decimal(19, 4)) as freight_amount,
        cast(totaldue as decimal(19, 4)) as total_due,
        cast(comment as varchar) as comment,
        cast(rowguid as varchar) as rowguid,
        cast(modifieddate as timestamp) as modified_date,
        cast(record_source as varchar) as record_source,
        cast(load_dts as timestamp) as load_dts
    from source
),

derived as (
    select
        *,
        cast(strftime(order_date, '%Y%m%d') as integer) as order_date_key,
        cast(strftime(due_date, '%Y%m%d') as integer) as due_date_key,
        cast(strftime(ship_date, '%Y%m%d') as integer) as ship_date_key,
        modified_date as effective_start_date,
        cast('9999-12-31' as timestamp) as effective_end_date,
        true as is_current
    from typed
)

select
    sha256(
        coalesce(nullif(upper(trim(cast(sales_order_number as varchar))), ''), 'NULL')
    ) as sales_order_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(sales_order_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(revision_number as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(order_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(due_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(ship_date as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(status as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(online_order_flag as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sales_order_number as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(purchase_order_number as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(account_number as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(customer_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(sales_person_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(territory_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(bill_to_address_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(ship_to_address_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(ship_method_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(credit_card_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(credit_card_approval_code as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(currency_rate_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(subtotal as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(tax_amount as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(freight_amount as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(total_due as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(comment as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as sales_order_header_hashdiff,
    sales_order_id,
    revision_number,
    order_date_key,
    due_date_key,
    ship_date_key,
    order_date,
    due_date,
    ship_date,
    status,
    online_order_flag,
    sales_order_number,
    purchase_order_number,
    account_number,
    customer_id,
    sales_person_id,
    territory_id,
    bill_to_address_id,
    ship_to_address_id,
    ship_method_id,
    credit_card_id,
    credit_card_approval_code,
    currency_rate_id,
    subtotal,
    tax_amount,
    freight_amount,
    total_due,
    comment,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
