{{ config(materialized='table') }}

select
    productid,
    startdate,
    enddate,
    listprice,
    modifieddate,
    'csv:Production.ProductListPriceHistory' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/ProductListPriceHistory.csv',
    header = false,
    delim = '\t',
    names = [
        'productid',
        'startdate',
        'enddate',
        'listprice',
        'modifieddate'
    ]
)

