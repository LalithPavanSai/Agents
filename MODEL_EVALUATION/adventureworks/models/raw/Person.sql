{{ config(materialized='table') }}

select
    businessentityid,
    persontype,
    namestyle,
    title,
    firstname,
    middlename,
    lastname,
    suffix,
    emailpromotion,
    additionalcontactinfo,
    demographics,
    rowguid,
    replace(modifieddate, '&|', '') as modifieddate,
    'csv:Person.Person' as record_source,
    current_timestamp as load_dts
from read_csv(
    'C:/Users/189186/Documents/dbt_manual_july/data/Person.csv',
    header = false,
    delim = '+|',
    names = [
        'businessentityid',
        'persontype',
        'namestyle',
        'title',
        'firstname',
        'middlename',
        'lastname',
        'suffix',
        'emailpromotion',
        'additionalcontactinfo',
        'demographics',
        'rowguid',
        'modifieddate'
    ]
)

