{{ config(materialized='table') }}

select
    businessentityid,
    emailaddressid,
    emailaddress,
    rowguid,
    replace(modifieddate, '&|', '') as modifieddate,
    'csv:Person.EmailAddress' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/EmailAddress.csv',
    header = false,
    delim = '+|',
    names = [
        'businessentityid',
        'emailaddressid',
        'emailaddress',
        'rowguid',
        'modifieddate'
    ]
)

