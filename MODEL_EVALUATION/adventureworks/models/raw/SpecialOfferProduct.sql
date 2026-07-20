{{ config(materialized='table') }}

select
    specialofferid,
    productid,
    rowguid,
    modifieddate,
    'csv:Sales.SpecialOfferProduct' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/SpecialOfferProduct.csv',
    header = false,
    delim = '\t',
    names = [
        'specialofferid',
        'productid',
        'rowguid',
        'modifieddate'
    ]
)

