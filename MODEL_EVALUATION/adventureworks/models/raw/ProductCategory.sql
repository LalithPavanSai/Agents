{{ config(materialized='table') }}

select
    productcategoryid,
    name,
    rowguid,
    modifieddate,
    'csv:Production.ProductCategory' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/ProductCategory.csv',
    header = false,
    delim = '\t',
    names = [
        'productcategoryid',
        'name',
        'rowguid',
        'modifieddate'
    ]
)

