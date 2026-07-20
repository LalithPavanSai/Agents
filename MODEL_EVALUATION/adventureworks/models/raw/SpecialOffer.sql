{{ config(materialized='table') }}

select
    specialofferid,
    description,
    discountpct,
    type,
    category,
    startdate,
    enddate,
    minqty,
    maxqty,
    rowguid,
    modifieddate,
    'csv:Sales.SpecialOffer' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/SpecialOffer.csv',
    header = false,
    delim = '\t',
    names = [
        'specialofferid',
        'description',
        'discountpct',
        'type',
        'category',
        'startdate',
        'enddate',
        'minqty',
        'maxqty',
        'rowguid',
        'modifieddate'
    ]
)

