{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('ProductSubcategory') }}
),

typed as (
    select
        cast(productsubcategoryid as integer) as product_subcategory_id,
        cast(productcategoryid as integer) as product_category_id,
        cast(name as varchar) as subcategory_name,
        cast(rowguid as varchar) as rowguid,
        cast(modifieddate as timestamp) as modified_date,
        cast(record_source as varchar) as record_source,
        cast(load_dts as timestamp) as load_dts
    from source
),

derived as (
    select
        *,
        modified_date as effective_start_date,
        cast('9999-12-31' as timestamp) as effective_end_date,
        true as is_current
    from typed
)

select
    sha256(
        coalesce(nullif(upper(trim(cast(product_subcategory_id as varchar))), ''), 'NULL')
    ) as product_subcategory_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(product_subcategory_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(product_category_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(subcategory_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as product_subcategory_hashdiff,
    product_subcategory_id,
    product_category_id,
    subcategory_name,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
