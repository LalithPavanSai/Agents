{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('ProductModel') }}
),

typed as (
    select
        cast(productmodelid as integer) as product_model_id,
        cast(name as varchar) as model_name,
        cast(catalogdescription as varchar) as catalog_description,
        cast(instructions as varchar) as instructions,
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
        coalesce(nullif(upper(trim(cast(product_model_id as varchar))), ''), 'NULL')
    ) as product_model_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(product_model_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(model_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(catalog_description as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(instructions as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(rowguid as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as product_model_hashdiff,
    product_model_id,
    model_name,
    catalog_description,
    instructions,
    rowguid,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
