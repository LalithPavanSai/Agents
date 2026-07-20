{{ config(materialized='table') }}

select
    businessentityid,
    addressid,
    addresstypeid,
    rowguid,
    replace(modifieddate, '&|', '') as modifieddate,
    'csv:Person.BusinessEntityAddress' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/BusinessEntityAddress.csv',
    header = false,
    delim = '+|',
    names = [
        'businessentityid',
        'addressid',
        'addresstypeid',
        'rowguid',
        'modifieddate'
    ]
)

