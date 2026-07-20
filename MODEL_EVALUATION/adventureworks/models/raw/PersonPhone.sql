{{ config(materialized='table') }}

select
    businessentityid,
    phonenumber,
    phonenumbertypeid,
    replace(modifieddate, '&|', '') as modifieddate,
    'csv:Person.PersonPhone' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/PersonPhone.csv',
    header = false,
    delim = '+|',
    names = [
        'businessentityid',
        'phonenumber',
        'phonenumbertypeid',
        'modifieddate'
    ]
)

