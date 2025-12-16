        select array_agg(account_id)
        from dwh.d_account
        where true
            and account_name = any('{FUTCRET,MIRARET,MRSC,SAXORET}'); -- {68698,63384,63109,63706}
/*
select
    case
     when f_str.order_type_id = '1' then 'Y'
     when f_str.side = '1' and f_str.order_price >= f_str.nbbo_ask_price then 'Y'
     when f_str.side <> '1' and f_str.order_price <= f_str.nbbo_bid_price then 'Y'
     else 'N'
   end::bpchar as is_marketable,
    *
     from data_marts.f_yield_capture f_str
    inner join data_marts.f_yield_capture f_par on f_par.order_id=f_str.parent_order_id and f_par.status_date_id = f_str.status_date_id
    where f_str.parent_order_id is not null
    and f_str.account_id = any ('{68698,63384,63109,63706}')
-- 	and i.symbol != any(l_array_symbol)--not in ('ZVZZT', 'ZWZZT', 'CBO', 'CBX', 'IBO', 'IGZ', 'ZBZX', 'ZTEST', 'ZTST', 'ZZZ', 'ZZK', 'ZVV')
	and f_str.status_date_id between :in_start_date_id and :in_end_date_id
	and f_par.status_date_id between :in_start_date_id and :in_end_date_id
   and (f_str.parent_order_id = 18591858221 or f_par.order_id = 18591858221)

 ;
*/
select * from dwh.d_account
where account_name = 'FUTCRET'




create index on t_report ("Order ID", "Parent Order ID")
select *
into trash.so_equity_non_marketable
from t_report
create index on trash.so_equity_non_marketable ("Order ID")

select * from trash.so_equity_non_marketable
order by "Order ID";


----
select * from t_yc
    where status_date_id between :in_start_date_id and :in_end_date_id
-- create temp table t_yc as
-- insert into t_yc
    select *
from data_marts.f_yield_capture yc
where yc.status_date_id between :in_start_date_id and :in_end_date_id
  and yc.account_id = any ('{68698,63384,63109,63706}')
  and yc.multileg_reporting_type in ('1', '2')
  and yc.is_marketable = 'N'
  and yc.order_price >= 1
  and yc.parent_order_id is null
  and yc.instrument_type_id = 'E';

insert into t_yc
select str.*
from t_yc as par
         join data_marts.f_yield_capture str on (str.parent_order_id = par.order_id --and str.status_date_id = par.status_date_id
             )
where true
  and par.status_date_id between :in_start_date_id and :in_end_date_id
  and str.status_date_id between :in_start_date_id and :in_end_date_id
  and str.account_id = any ('{68698,63384,63109,63706}')
  and str.parent_order_id is not null;

select *
into  trash.so_to_delete
from t_yc;

create index on t_yc (status_date_id);

create table trash.so_equity_non_marketable_jun_nov as
select case when yc.parent_order_id is null then 'Parent' else 'Child' end as "Row Type",
       to_char(co.create_time, 'MM/DD/YYYY')                               as "Create Date",
       to_char(co.create_time, 'HH24:MI:SS.US')                            as "Create Time",
       to_char(yc.routed_time, 'HH24:MI:SS.US')                            as "Routed Time",
       to_char(yc.routed_time, 'MM/DD/YYYY')                               as "Event Date",
       to_char(yc.exec_time, 'HH24:MI:SS.US')                              as "Event Time",
       yc.parent_order_id                                                  as "Parent Order ID",
       yc.order_id                                                         as "Order ID",
       lst_ex.order_status_description                                     as "Order Status",
       case
           when hsd.instrument_type_id = 'E' then 'Equity'
           when hsd.instrument_type_id = 'O' then 'Option'
           end                                                             as "Sec Type",
       case
           when yc.side = '1' then 'Buy'
           when yc.side in ('2', '5', '6') then 'Sell'
           else ''
           end                                                             as "Side",
       hsd.display_instrument_id                                           as "Symbol",
       yc.order_qty                                                        as "Order Qty",
       yc.order_price                                                      as "Price",
       yc.day_cum_qty                                                      as "Ex Qty",
       round(yc.avg_px, 6)                                                 as "Avg Px",
       yc.day_leaves_qty                                                   as "Lvs Qty",
       ex.exchange_name                                                    as "Exchange Name",
       yc.nbbo_bid_price                                                   as "NBBO Bid Px",
       yc.nbbo_bid_quantity                                                as "NBBO Bid Qty",
       yc.nbbo_ask_price                                                   as "NBBO Ask Px",
       yc.nbbo_ask_quantity                                                as "NBBO Ask Qty"
from trash.so_to_delete as yc
--          join dwh.d_account a on (a.account_id = yc.account_id)
         join dwh.client_order co
              on (co.create_date_id between :in_start_date_id and :in_end_date_id and
                  co.create_date_id = yc.status_date_id and
                  co.order_id = yc.order_id)
         join dwh.historic_security_definition_all hsd
              on (hsd.instrument_id = yc.instrument_id)
         left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
         left join lateral
    (
    select os.order_status_description
    from dwh.execution ex
             left join dwh.d_order_status os on (os.order_status = ex.order_status and os.is_active)
             left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
    where ex.order_id = yc.order_id
      and ex.exec_date_id between :in_start_date_id and :in_end_date_id
      and ex.exec_date_id = yc.status_date_id
      and ex.order_status <> '3'
    order by ex.exec_id desc
    limit 1
    ) lst_ex on true
where true;


create index on trash.so_equity_non_marketable_jun_nov ("Order ID");
select count(*) from trash.so_equity_non_marketable_jun_nov;


select *
from trash.so_equity_non_marketable_data(20251201, 20251205, '{68698,63384,63109,63706}'::int4[]);

drop function if exists trash.so_equity_non_marketable_data;
create or replace function trash.so_equity_non_marketable_data(in_start_date_id int4, in_end_date_id int4, in_account_ids int4[])
    returns int4
    language plpgsql
as
$fx$
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    drop table if exists t_yc;

    create temp table t_yc as
    select *
    from data_marts.f_yield_capture yc
    where yc.status_date_id between in_start_date_id and in_end_date_id
      and yc.account_id = any (in_account_ids)
      and yc.multileg_reporting_type in ('1', '2')
      and yc.is_marketable = 'N'
      and yc.order_price >= 1
      and yc.parent_order_id is null
      and yc.instrument_type_id = 'E';

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' parent completed', l_row_cnt, 'O')
    into l_step_id;

    insert into t_yc
    select str.*
    from t_yc as par
             join data_marts.f_yield_capture str on (str.parent_order_id = par.order_id)
    where str.status_date_id between in_start_date_id and in_end_date_id
      and str.account_id = any (in_account_ids)
      and str.parent_order_id is not null;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' street completed', l_row_cnt, 'O')
    into l_step_id;

    create index on t_yc (status_date_id);

    drop table if exists trash.so_equity_non_marketable;
    create table trash.so_equity_non_marketable as
    select case when yc.parent_order_id is null then 'Parent' else 'Child' end as "Row Type",
           to_char(co.create_time, 'MM/DD/YYYY')                               as "Create Date",
           to_char(co.create_time, 'HH24:MI:SS.US')                            as "Create Time",
           to_char(yc.routed_time, 'HH24:MI:SS.US')                            as "Routed Time",
           to_char(yc.routed_time, 'MM/DD/YYYY')                               as "Event Date",
           to_char(yc.exec_time, 'HH24:MI:SS.US')                              as "Event Time",
           yc.parent_order_id                                                  as "Parent Order ID",
           yc.order_id                                                         as "Order ID",
           lst_ex.order_status_description                                     as "Order Status",
           case
               when hsd.instrument_type_id = 'E' then 'Equity'
               when hsd.instrument_type_id = 'O' then 'Option'
               end                                                             as "Sec Type",
           case
               when yc.side = '1' then 'Buy'
               when yc.side in ('2', '5', '6') then 'Sell'
               else ''
               end                                                             as "Side",
           hsd.display_instrument_id                                           as "Symbol",
           yc.order_qty                                                        as "Order Qty",
           yc.order_price                                                      as "Price",
           yc.day_cum_qty                                                      as "Ex Qty",
           round(yc.avg_px, 6)                                                 as "Avg Px",
           yc.day_leaves_qty                                                   as "Lvs Qty",
           ex.exchange_name                                                    as "Exchange Name",
           yc.nbbo_bid_price                                                   as "NBBO Bid Px",
           yc.nbbo_bid_quantity                                                as "NBBO Bid Qty",
           yc.nbbo_ask_price                                                   as "NBBO Ask Px",
           yc.nbbo_ask_quantity                                                as "NBBO Ask Qty"
    from t_yc as yc
             join dwh.client_order co
                  on (co.create_date_id between in_start_date_id and in_end_date_id and
                      co.create_date_id = yc.status_date_id and
                      co.order_id = yc.order_id)
             join dwh.historic_security_definition_all hsd
                  on (hsd.instrument_id = yc.instrument_id)
             left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
             left join lateral
        (
        select os.order_status_description
        from dwh.execution ex
                 left join dwh.d_order_status os on (os.order_status = ex.order_status and os.is_active)
                 left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
        where ex.order_id = yc.order_id
          and ex.exec_date_id between in_start_date_id and in_end_date_id
          and ex.exec_date_id = yc.status_date_id
          and ex.order_status <> '3'
        order by ex.exec_id desc
        limit 1
        ) lst_ex on true
    where true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' report COMPLETED =======', l_row_cnt, 'O')
    into l_step_id;
    create index on trash.so_equity_non_marketable ("Order ID");
    return l_row_cnt;
end;
$fx$;



create or replace function trash.so_print_report()
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$$
declare

begin
    return query
        select 'Row Type,Create Date,Create Time,Routed Time,Event Date,Event Time,Parent Order ID,Order ID,Order Status,Sec Type,Side,Symbol,Order Qty,Price,Ex Qty,Avg Px,Lvs Qty,Exchange Name,NBBO Bid Px,NBBO Bid Qty,NBBO Ask Px,NBBO Ask Qty';
    return query
        select array_to_string(ARRAY [
                                   "Row Type",
                                   "Create Date",
                                   "Create Time",
                                   "Routed Time",
                                   "Event Date",
                                   "Event Time",
                                   "Parent Order ID"::text,
                                   "Order ID"::text,
                                   "Order Status",
                                   "Sec Type",
                                   "Side",
                                   "Symbol",
                                   "Order Qty"::text,
                                   "Price"::text,
                                   "Ex Qty"::text,
                                   "Avg Px"::text,
                                   "Lvs Qty"::text,
                                   "Exchange Name",
                                   "NBBO Bid Px"::text,
                                   "NBBO Bid Qty"::text,
                                   "NBBO Ask Px"::text,
                                   "NBBO Ask Qty"::text
                                   ], ',', '')
        from trash.so_equity_non_marketable
        where "Symbol" not in
              ('ZVZZT', 'ZWZZT', 'CBO', 'CBX', 'IBO', 'IGZ', 'ZBZX', 'ZTEST', 'ZTST', 'ZZZ', 'ZZK', 'ZVV')
        order by "Order ID";
end;
$$;

select * from trash.so_print_report()


select distinct on (date_id) date_id,
                             case
                                 when exists (select null
                                              from consolidator.consolidator_message cmi
                                              where cmi.date_id = cm.date_id) then true
                                 else false end as is_present
from consolidator.consolidator_message cm
where cm.date_id between 20250715 and 20250730;


SELECT pid, age(clock_timestamp(), query_start), usename, query, state
FROM pg_stat_activity
WHERE state not like 'idle%' AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY query_start desc;

SELECT pg_cancel_backend(2973438)

2973438