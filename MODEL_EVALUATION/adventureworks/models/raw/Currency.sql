{{ config(materialized='table') }}

select
    currencycode,
    name,
    modifieddate,
    'csv:Sales.Currency' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/Currency.csv',
    header = false,
    delim = '\t',
    names = [
        'currencycode',
        'name',
        'modifieddate'
    ]
)

