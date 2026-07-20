{{ config(materialized='table') }}

select
    salesorderid,
    salesreasonid,
    modifieddate,
    'csv:Sales.SalesOrderHeaderSalesReason' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/SalesOrderHeaderSalesReason.csv',
    header = false,
    delim = '\t',
    names = [
        'salesorderid',
        'salesreasonid',
        'modifieddate'
    ]
)

