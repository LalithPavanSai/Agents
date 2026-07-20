{{ config(materialized='table') }}

select
    countryregioncode,
    name,
    modifieddate,
    'csv:Person.CountryRegion' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/CountryRegion.csv',
    header = false,
    delim = '\t',
    names = [
        'countryregioncode',
        'name',
        'modifieddate'
    ]
)

