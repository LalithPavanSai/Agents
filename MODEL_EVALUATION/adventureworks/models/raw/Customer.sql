{{ config(materialized='table') }}

select
    customerid,
    personid,
    storeid,
    territoryid,
    accountnumber,
    rowguid,
    modifieddate,
    'csv:Sales.Customer' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/Customer.csv',
    header = false,
    delim = '\t',
    names = [
        'customerid',
        'personid',
        'storeid',
        'territoryid',
        'accountnumber',
        'rowguid',
        'modifieddate'
    ]
)

