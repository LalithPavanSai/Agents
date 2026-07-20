{{ config(materialized='table') }}

with date_spine as (
    select cast(date_value as date) as full_date
    from range(date '2001-01-01', date '2015-01-01', interval '1 day') t(date_value)
)

select
    cast(strftime(full_date, '%Y%m%d') as integer) as date_key,
    full_date as full_date_alternate_key,
    cast(dayofweek(full_date) as tinyint) as day_number_of_week,
    strftime(full_date, '%A') as day_name_of_week,
    cast(dayofmonth(full_date) as tinyint) as day_number_of_month,
    cast(dayofyear(full_date) as smallint) as day_number_of_year,
    cast(weekofyear(full_date) as tinyint) as week_number_of_year,
    strftime(full_date, '%B') as month_name,
    cast(month(full_date) as tinyint) as month_number_of_year,
    cast(quarter(full_date) as tinyint) as calendar_quarter,
    cast(year(full_date) as smallint) as calendar_year,
    cast(case when month(full_date) <= 6 then 1 else 2 end as tinyint) as calendar_semester
from date_spine
