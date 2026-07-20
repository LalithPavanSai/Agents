{{ config(materialized='table') }}

select
    productsubcategoryid,
    productcategoryid,
    name,
    rowguid,
    modifieddate,
    'csv:Production.ProductSubcategory' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/ProductSubcategory.csv',
    header = false,
    delim = '\t',
    names = [
        'productsubcategoryid',
        'productcategoryid',
        'name',
        'rowguid',
        'modifieddate'
    ]
)

