{{
    config(
        materialized='incremental',
        unique_key=['customer_alternate_key', 'effective_start_date'],
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

with cust as (
    select * from {{ ref('stg_sales__customer') }}
),

person as (
    select
        business_entity_id,
        person_type,
        title,
        first_name,
        middle_name,
        last_name,
        suffix,
        email_promotion
    from {{ ref('stg_person__person') }}
    where is_current = true
),

email as (
    select
        business_entity_id,
        email_address
    from {{ ref('stg_person__email_address') }}
    where is_current = true
    qualify row_number() over (partition by business_entity_id order by email_address_id) = 1
),

bea as (
    select
        business_entity_id,
        address_id
    from {{ ref('stg_person__business_entity_address') }}
    where is_current = true
    qualify row_number() over (partition by business_entity_id order by address_id) = 1
),

addr as (
    select
        address_id,
        city,
        state_province_id,
        postal_code
    from {{ ref('stg_person__address') }}
    where is_current = true
),

sp as (
    select
        state_province_id,
        state_province_code,
        country_region_code
    from {{ ref('stg_person__state_province') }}
    where is_current = true
),

cr as (
    select
        country_region_code,
        country_region_name   as english_country_region_name
    from {{ ref('stg_person__country_region') }}
    where is_current = true
),

geo as (
    select
        geography_alternate_key,
        geography_key
    from {{ ref('dim_geography') }}
    where is_current = true
),

source as (
    select
        c.customer_id,
        c.account_number,
        c.territory_id,
        p.person_type,
        p.title,
        p.first_name,
        p.middle_name,
        p.last_name,
        p.suffix,
        p.email_promotion,
        e.email_address,
        a.city,
        sp.state_province_code,
        cr.english_country_region_name,
        a.postal_code,
        g.geography_key,
        
        sha256(
            concat_ws(
                '||',
                coalesce(nullif(upper(trim(cast(c.account_number as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(c.territory_id as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(p.title as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(p.first_name as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(p.middle_name as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(p.last_name as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(p.suffix as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(e.email_address as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(a.city as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(sp.state_province_code as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(cr.english_country_region_name as varchar))), ''), 'NULL'),
                coalesce(nullif(upper(trim(cast(a.postal_code as varchar))), ''), 'NULL')
            )
        )                       as customer_hashdiff,
        c.effective_start_date,
        c.record_source,
        c.load_dts
    from cust c
    left join person p   on c.person_id           = p.business_entity_id
    left join email  e   on c.person_id           = e.business_entity_id
    left join bea    b   on c.person_id           = b.business_entity_id
    left join addr   a   on b.address_id          = a.address_id
    left join sp         on a.state_province_id   = sp.state_province_id
    left join cr         on sp.country_region_code = cr.country_region_code
    left join geo    g   on a.address_id          = g.geography_alternate_key
),

{% if is_incremental() %}

changed as (
    select s.*
    from source s
    inner join {{ this }} d
        on s.account_number = d.customer_alternate_key
        and d.is_current = true
    where s.customer_hashdiff != d.customer_hashdiff
),

new_records as (
    select s.*
    from source s
    left join {{ this }} d on s.account_number = d.customer_alternate_key
    where d.customer_alternate_key is null
),

records_to_close as (
    select
        d.customer_key,
        d.customer_alternate_key,
        d.geography_key,
        d.person_type,
        d.title,
        d.first_name,
        d.middle_name,
        d.last_name,
        d.suffix,
        d.email_promotion,
        d.email_address,
        d.city,
        d.state_province_code,
        d.english_country_region_name,
        d.postal_code,
        d.customer_hashdiff,
        d.effective_start_date,
        c.effective_start_date   as effective_end_date,
        false                    as is_current,
        d.record_source,
        d.load_dts
    from {{ this }} d
    inner join changed c
        on d.customer_alternate_key = c.account_number
    where d.is_current = true
),

incoming as (
    select * from changed
    union all
    select * from new_records
),

new_versions as (
    select
        (select coalesce(max(customer_key), 0) from {{ this }})
            + row_number() over (order by i.customer_id) as customer_key,
        i.account_number         as customer_alternate_key,
        i.geography_key,
        i.person_type,
        i.title,
        i.first_name,
        i.middle_name,
        i.last_name,
        i.suffix,
        i.email_promotion,
        i.email_address,
        i.city,
        i.state_province_code,
        i.english_country_region_name,
        i.postal_code,
        i.customer_hashdiff,
        i.effective_start_date,
        cast('9999-12-31' as timestamp) as effective_end_date,
        true                     as is_current,
        i.record_source,
        i.load_dts
    from incoming i
)

select * from records_to_close
union all
select * from new_versions

{% else %}

final as (
    select
        row_number() over (order by customer_id) as customer_key,
        account_number           as customer_alternate_key,
        geography_key,
        person_type,
        title,
        first_name,
        middle_name,
        last_name,
        suffix,
        email_promotion,
        email_address,
        city,
        state_province_code,
        english_country_region_name,
        postal_code,
        customer_hashdiff,
        effective_start_date,
        cast('9999-12-31' as timestamp) as effective_end_date,
        true                     as is_current,
        record_source,
        load_dts
    from source
)

select * from final

{% endif %}
