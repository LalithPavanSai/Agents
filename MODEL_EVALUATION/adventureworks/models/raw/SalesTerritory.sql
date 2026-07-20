{{ config(materialized='table') }}

select
    territoryid,
    name,
    countryregioncode,
    "group",
    salesytd,
    saleslastyear,
    costytd,
    costlastyear,
    rowguid,
    modifieddate,
    'csv:Sales.SalesTerritory' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/SalesTerritory.csv',
    header = false,
    delim = '\t',
    names = [
        'territoryid',
        'name',
        'countryregioncode',
        'group',
        'salesytd',
        'saleslastyear',
        'costytd',
        'costlastyear',
        'rowguid',
        'modifieddate'
    ]
)

