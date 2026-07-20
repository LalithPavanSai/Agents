{{ config(materialized='view') }}

with source as (
    select *
    from {{ ref('SalesReason') }}
),

typed as (
    select
        cast(salesreasonid as integer) as sales_reason_id,
        cast(name as varchar) as reason_name,
        cast(reasontype as varchar) as reason_type,
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
        coalesce(nullif(upper(trim(cast(sales_reason_id as varchar))), ''), 'NULL')
    ) as sales_reason_hk,
    sha256(
        concat_ws(
            '||',
            coalesce(nullif(upper(trim(cast(sales_reason_id as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(reason_name as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(reason_type as varchar))), ''), 'NULL'),
            coalesce(nullif(upper(trim(cast(modified_date as varchar))), ''), 'NULL')
        )
    ) as sales_reason_hashdiff,
    sales_reason_id,
    reason_name,
    reason_type,
    modified_date,
    record_source,
    load_dts,
    effective_start_date,
    effective_end_date,
    is_current
from derived
