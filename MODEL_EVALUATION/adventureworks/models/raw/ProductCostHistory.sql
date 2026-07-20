{{ config(materialized='table') }}

select
    productid,
    startdate,
    enddate,
    standardcost,
    modifieddate,
    'csv:Production.ProductCostHistory' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/ProductCostHistory.csv',
    header = false,
    delim = '\t',
    names = [
        'productid',
        'startdate',
        'enddate',
        'standardcost',
        'modifieddate'
    ]
)

