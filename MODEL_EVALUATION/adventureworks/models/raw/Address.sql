{{ config(materialized='table') }}

select
    addressid,
    addressline1,
    addressline2,
    city,
    stateprovinceid,
    postalcode,
    spatiallocation,
    rowguid,
    modifieddate,
    'csv:Person.Address' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/Address.csv',
    header = false,
    delim = '\t',
    names = [
        'addressid',
        'addressline1',
        'addressline2',
        'city',
        'stateprovinceid',
        'postalcode',
        'spatiallocation',
        'rowguid',
        'modifieddate'
    ]
)

