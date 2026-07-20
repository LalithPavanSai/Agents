{{ config(materialized='table') }}

select
    salesreasonid,
    name,
    reasontype,
    modifieddate,
    'csv:Sales.SalesReason' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/SalesReason.csv',
    header = false,
    delim = '\t',
    names = [
        'salesreasonid',
        'name',
        'reasontype',
        'modifieddate'
    ]
)

