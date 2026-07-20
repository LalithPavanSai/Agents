{{ config(materialized='table') }}

with source_file as (
    select content
    from read_text('C:/Users/189186/Documents/dbt_manual_july/data/ProductModel.csv')
),

split_records as (
    select regexp_replace(record, '^[\r\n]+|[\r\n]+$', '', 'g') as record
    from source_file, unnest(string_split(content, '&|')) as t(record)
),

records as (
    select record
    from split_records
    where trim(record) <> ''
),

parsed as (
    select string_split(record, '+|') as fields
    from records
)

select
    list_extract(fields, 1) as productmodelid,
    list_extract(fields, 2) as name,
    list_extract(fields, 3) as catalogdescription,
    list_extract(fields, 4) as instructions,
    list_extract(fields, 5) as rowguid,
    list_extract(fields, 6) as modifieddate,
    'csv:Production.ProductModel' as record_source,
    current_timestamp as load_dts
from parsed

