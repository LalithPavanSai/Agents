{{ config(materialized='table') }}

select
    salesorderid,
    salesorderdetailid,
    carriertrackingnumber,
    orderqty,
    productid,
    specialofferid,
    unitprice,
    unitpricediscount,
    linetotal,
    rowguid,
    modifieddate,
    'csv:Sales.SalesOrderDetail' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/SalesOrderDetail.csv',
    header = false,
    delim = '\t',
    names = [
        'salesorderid',
        'salesorderdetailid',
        'carriertrackingnumber',
        'orderqty',
        'productid',
        'specialofferid',
        'unitprice',
        'unitpricediscount',
        'linetotal',
        'rowguid',
        'modifieddate'
    ]
)

