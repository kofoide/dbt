with gs as (
    select
        the_date::date
    from generate_series('2022-01-01', '2025-12-31', interval '1 day') as s(the_date)
)
,

-- This should probably be a table in your system
holiday as (
    select
        '2022-12-25'::date as the_date,
        'X-mas'::varchar(100) as holiday
)
,

-- basic information about the day
basic as (
    select
        b.the_date,
        date_part('year', b.the_date)::int as year_int,
        date_part('isoyear', b.the_date)::int as year_iso_int,
        date_part('quarter', b.the_date)::int as quarter_of_year_int,
        date_part('month', b.the_date)::int as month_of_year_int,
        date_part('week', b.the_date)::int as week_iso_of_year_int,
        date_part('doy', b.the_date)::int as day_of_year_int,
        (b.the_date - date_trunc('quarter', b.the_date)::date) as day_of_quarter_int,
        date_part('day', b.the_date)::int as day_of_month_int,
        date_part('dow', b.the_date)::int as day_of_week_int,
        to_char(b.the_date, 'Day') as day_of_week_name,
        date_trunc('year', b.the_date)::date as year_first_date,
        (date_trunc('year', b.the_date)::date +interval '1 year - 1 day')::DATE AS year_final_date,
        date_trunc('quarter', b.the_date)::date as quarter_first_date,
        (date_trunc('year', b.the_date)::date +interval '3 month - 1 day')::DATE AS quarter_final_date,
        date_trunc('month', b.the_date)::date as month_first_date,
        (date_trunc('month', b.the_date)::date +interval '1 month - 1 day')::DATE AS month_final_date,
        date_trunc('week', b.the_date)::date as week_first_date,
        (date_trunc('week', b.the_date)::date +interval '1 week - 1 day')::DATE AS week_final_date,
        case
            when date_part('isodow', b.the_date)::int in (6, 7) then true
            else false
        end as is_weekend,
        case
            when h.the_date is not null then true
            else false
        end as is_holiday,
        h.holiday
    from
        gs as b
        left join holiday as h on b.the_date = h.the_date
)
,

base as (
    select
        b.*,

        year_int::varchar(4) as year_string,
        year_iso_int::varchar(4) as year_iso_string,
        quarter_of_year_int::varchar(1) as quarter_of_year_string,
        lpad(month_of_year_int::varchar(2), 2, ' ') as month_of_year_string,
        lpad(week_iso_of_year_int::varchar(2), 2, ' ') as week_iso_of_year_string,
        lpad(day_of_year_int::varchar(3), 3, ' ') as day_of_year_string,
        lpad(day_of_quarter_int::varchar(2), 2, ' ') as day_of_quarter_string,
        lpad(day_of_month_int::varchar(2), 2, ' ') as day_of_month_string,
        day_of_week_int::varchar(1) as day_of_week_string,

        case
            when is_weekend or is_holiday then 0
            else 1
        end as business_day_int
    from basic as b
)
,

relative_period as (
    select
        *,
    
        dense_rank() over(order by year_int, quarter_of_year_int) as quarter_rank,
        dense_rank() over(order by year_int, month_of_year_int) as month_rank,
        dense_rank() over(order by year_int, week_iso_of_year_int) as week_iso_rank
    from base
)

, today as (
select
    today.the_date as today_date,
    today.year_int as today_year_int,
    today.year_iso_int as today_year_iso_int,
    today.quarter_of_year_int as today_quarter_of_year_int,
    today.month_of_year_int as today_month_of_year_int,
    today.week_iso_of_year_int as today_week_iso_of_year_int,
    today.day_of_year_int as today_day_of_year_int,
    today.day_of_quarter_int as today_day_of_quarter_int,
    today.day_of_month_int as today_day_of_month_int,
    today.day_of_week_int as today_day_of_week_int,

    rp.quarter_rank as today_quarter_rank,
    rp.month_rank as today_month_rank,
    rp.week_iso_rank as today_week_iso_rank

from
    base as today
    inner join relative_period as rp on today.the_date = rp.the_date
where
    today.the_date = current_date
)
,

setup as (
select 
    b.the_date,
    b.is_weekend,
    b.is_holiday,
    case when b.is_weekend and not b.is_holiday then true else false end as is_business_day,

-- *******************************
-- YEAR
    b.year_int,
    b.year_string,
    b.year_int - t.today_year_int as year_relative_int,

-- Label for Number of Years Relative to the Current Year
    (case
        when (b.year_int - t.today_year_int) = 0 then 'Current Year'
        when (b.year_int - t.today_year_int) = 1 then 'Next Year'
        when (b.year_int - t.today_year_int) = -1 then 'Previous Year'
        when (b.year_int - t.today_year_int) > 0 then (b.year_int - t.today_year_int)::varchar(50) || ' Years From Now'
        else abs(b.year_int - t.today_year_int)::varchar(50) || ' Years Ago'
    end)::varchar(50) as year_relative_label,

    b.year_first_date,
    b.year_final_date,
-- *******************************

-- *******************************
-- YEAR ISO
    b.year_iso_int,
    b.year_iso_string,
    b.year_iso_int - t.today_year_iso_int as year_iso_relative_int,

-- Label for Number of Years Relative to the Current Year
    (case
        when (b.year_iso_int - t.today_year_iso_int) = 0 then 'Current Year'
        when (b.year_iso_int - t.today_year_iso_int) = 1 then 'Next Year'
        when (b.year_iso_int - t.today_year_iso_int) = -1 then ' Previous Year'
        when (b.year_iso_int - t.today_year_iso_int) > 0 then (b.year_iso_int - t.today_year_iso_int)::varchar(50) || ' Years From Now'
        else abs(b.year_iso_int - t.today_year_iso_int)::varchar(50) || ' Years Ago'
    end)::varchar(50) as year_iso_relative_label,

/*
    b.year_first_date,
    b.year_final_date,

-- Is the DayOfYear for This date in the YTD zone  
    case
        when b.day_of_year_int <= t.today_day_of_year_int then true
        else false
    end as is_ytd_range
*/
-- *******************************

-- *******************************
-- QUARTER
    b.quarter_of_year_int,
    b.quarter_of_year_string,
    rp.quarter_rank - t.today_quarter_rank as quarter_relative_int,

    (case
        when (rp.quarter_rank - t.today_quarter_rank) = 0 then ' Current Quarter'
        when (rp.quarter_rank - t.today_quarter_rank) < 0 then ' ' || b.year_string || ' Quarter ' || b.quarter_of_year_string
        else b.year_string || ' Quarter ' || b.quarter_of_year_string
    end)::varchar(50) as quarter_relative_label,

    b.quarter_first_date,
    b.quarter_final_date,

    case
        when b.day_of_quarter_int <= t.today_day_of_quarter_int then true
        else false
    end as is_qtd_range,
-- *******************************

-- *******************************
-- MONTH
    b.month_of_year_int,
    b.month_of_year_string,

    case
        when (rp.month_rank - t.today_month_rank) = 0 then 'Current Month'
        when (rp.month_rank - t.today_month_rank) = -1 then ' Previous Month'
        when (rp.month_rank - t.today_month_rank) < -1 then ' Previous Month'
        when (rp.month_rank - t.today_month_rank) = 1 then 'Next Month'
    end as month_relative_label,
            

    b.month_first_date,
    b.month_final_date,

    case
        when b.day_of_month_int <= t.today_day_of_month_int then true
        else false
    end as is_mtd_range,
-- *******************************

-- *******************************
-- DAY
    b.day_of_week_name,
    b.day_of_year_int,
    b.day_of_quarter_int,
    b.day_of_month_int,
    b.day_of_week_int,

    (t.today_date - b.the_date) * -1 as day_relative_int,

    -- Calendar Year Day
    -- Using today as the target, is the_date in the Calendar YTD zone
    make_date(t.today_year_int, b.month_of_year_int, b.day_of_month_int) <= t.today_date as is_calendar_ytd,
    -- number of buseinss days that have gone by this calendar year
    sum(b.business_day_int) over(partition by b.year_int order by b.the_date rows between unbounded preceding and current row) as calendar_year_business_days_passed,
    -- number of business days remaining this calendar year
    sum(b.business_day_int) over(partition by b.year_int order by b.the_date rows between current row and unbounded following) as calendar_year_business_days_remaining,

    -- Quarter Day
    make_date(t.today_year_int, b.month_of_year_int, b.day_of_month_int) <= t.today_date and t.today_quarter_of_year_int = b.quarter_of_year_int as is_quarter_ytd,
    sum(b.business_day_int) over(partition by rp.quarter_rank order by b.the_date rows between unbounded preceding and current row) as quarter_business_days_passed,
    sum(b.business_day_int) over(partition by rp.quarter_rank order by b.the_date rows between current row and unbounded following) as quarter_business_days_remaining
-- *******************************
from
    base as b
    inner join relative_period as rp on b.the_date = rp.the_date
    cross join today as t
)

select *
from setup
order by the_date
