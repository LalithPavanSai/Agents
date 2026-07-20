{{ config(materialized='table') }}

select
    stateprovinceid,
    stateprovincecode,
    countryregioncode,
    isonlystateprovinceflag,
    name,
    territoryid,
    rowguid,
    modifieddate,
    'csv:Person.StateProvince' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/StateProvince.csv',
    header = false,
    delim = '\t',
    names = [
        'stateprovinceid',
        'stateprovincecode',
        'countryregioncode',
        'isonlystateprovinceflag',
        'name',
        'territoryid',
        'rowguid',
        'modifieddate'
    ]
)

