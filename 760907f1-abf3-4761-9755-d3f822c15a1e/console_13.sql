select   to_char(CAST(date_trunc('quarter', current_date)  + interval '3 months'  AS date) - interval '1 day', 'YYYYMMDD')::integer --as Q0_max_day
union
select to_char(CAST(date_trunc('quarter', current_date)  AS date) - interval '1 day', 'YYYYMMDD')::integer --as Q1_max_day
union
select to_char(CAST(date_trunc('quarter', current_date)  - interval '3 months'  AS date) - interval '1 day', 'YYYYMMDD')::integer --as Q2_max_day
union
select to_char(CAST(date_trunc('quarter', current_date)  - interval '6 months'  AS date) - interval '1 day', 'YYYYMMDD')::integer; --as Q3_max_day

