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
 20250601 - 20251130
        create temp table t_yc as
        select *
        from data_marts.f_yield_capture yc
        where yc.status_date_id between :in_start_date_id and :in_end_date_id
--           and yc.account_id = any ('{68698,63384,63109,63706}')
          and yc.account_id = any ('{63109}')
          and yc.multileg_reporting_type in ('1', '2')
          and yc.is_marketable = 'N'
          and yc.order_price >= 1
          and yc.parent_order_id is null
          and yc.instrument_type_id = 'E';

        insert into t_yc
        select str.*
        from t_yc as par
                 join data_marts.f_yield_capture str on (str.parent_order_id = par.order_id)
        where str.status_date_id between :in_start_date_id and :in_end_date_id
--           and str.account_id = any ('{68698,63384,63109,63706}')
          and str.account_id = any ('{63109}')
          and str.parent_order_id is not null;


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
/*
               tf.trading_firm_name                                                as "Trading Firm",
               a.account_name                                                      as "Account",
               yc.client_order_id                                                  as "Cl Ord ID",
               orig.client_order_id                                                as "Orig Cl Ord ID",
               ot.order_type_name                                                  as "Ord Type",
               coalesce(exd.ex_destination_desc, co.ex_destination)                as "Ex Dest",
               dts.target_strategy_name                                            as "Sub Strategy",
               case
                   when co.open_close = 'O' then 'Open'
                   when co.open_close = 'C' then 'Close'
                   else '' end                                                     as "O/C",


               cf.customer_or_firm_name                                            as "Cust/Firm",
               co.clearing_firm_id                                                 as "CMTA",
               yc.client_id                                                        as "Client ID",   -- not d_client as we do not have d_client anymore
               hsd.opra_symbol                                                     as "OSI Symbol",
               hsd.underlying_symbol                                               as "Root Symbol",
               to_char(hsd.maturity_date, 'MM/DD/YYYY')                            as "Expiration",  --MM/DD/YYY?? It was not mentioned
               hsd.put_call                                                        as "Put/Call",
               hsd.strike_px                                                       as "Strike",
               case when yc.multileg_reporting_type = '1' then 'N' else 'Y' end    as "Is Mleg",
               case when yc.cross_order_id is not null then 'Y' else 'N' end       as "Is Cross",
               tif.tif_name                                                        as "TIF",
               co.max_floor                                                        as "Max Floor",
               case
                   when co.exec_instruction like '1%' then 'NH' -- Not Held
                   when co.exec_instruction like '5%' then 'H' -- Held
                   else 'NH'
                   end                                                             as "Held Status",
               coalesce(fm_ex.tag_6376, fm_co.tag_6376)                            as "Alternative Compliance ID",
               coalesce(fm_ex.tag_376, fm_co.tag_6376)                             as "Compliance ID",
               coalesce(fm_ex.tag_21, fm_co.tag_21)                                as "Handling Instructions",
               coalesce(fm_ex.tag_18, fm_co.tag_18)                                as "Execution Instructions",
               co.co_client_leg_ref_id                                             as "Leg ID",
               lst_ex.exec_text                                                    as "Free Text"
 */
        from /*data_marts.f_yield_capture*/ t_yc as yc
                                                join dwh.d_account a on (a.account_id = yc.account_id)
                                                join dwh.client_order co
                                                     on (co.create_date_id between :in_start_date_id and :in_end_date_id and
                                                         co.create_date_id = yc.status_date_id and
                                                         co.order_id = yc.order_id)
            --                   left join lateral  (select orig.client_order_id
-- 			                            from dwh.client_order orig
-- 			                           where orig.create_date_id between in_start_date_id and in_end_date_id and
-- 			                               orig.create_date_id = yc.status_date_id and
-- 			                               orig.order_id = co.orig_order_id
-- 			                          limit 1) orig on true
--                  join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
--                  left join dwh.d_time_in_force tif on tif.is_active and tif.tif_id = yc.time_in_force_id
--                  left join dwh.d_order_type ot on ot.order_type_id = yc.order_type_id
                                                join dwh.historic_security_definition_all hsd
                                                     on (hsd.instrument_id = yc.instrument_id)
            --                  left join dwh.d_target_strategy dts on (dts.target_strategy_id = yc.sub_strategy_id)
--                  left join dwh.d_ex_destination exd on (exd.ex_destination_code = co.ex_destination and
--                                                         coalesce(exd.exchange_id, '') =
--                                                         coalesce(yc.exchange_id, '') and
--                                                         exd.instrument_type_id = yc.instrument_type_id and
--                                                         exd.is_active)
--                  left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = co.customer_or_firm_id)
                                                left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
                                                left join lateral
            (
            select os.order_status_description--, ex.exec_text, ex.fix_message_id, ex.exec_date_id
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
        --                  left join lateral (select fix_message ->> '6376' as tag_6376,
--                                            fix_message ->> '376'  as tag_376,
--                                            fix_message ->> '21'   as tag_21,
--                                            fix_message ->> '18'   as tag_18
--                                     from fix_capture.fix_message_json fm
--                                     where fm.fix_message_id = co.fix_message_id
--                                       and fm.date_id = co.create_date_id
--                                       and fm.date_id between in_start_date_id and in_end_date_id
--                                     limit 1) fm_co on true
--                  left join lateral (select fix_message ->> '6376' as tag_6376,
--                                            fix_message ->> '376'  as tag_376,
--                                            fix_message ->> '21'   as tag_21,
--                                            fix_message ->> '18'   as tag_18
--                                     from fix_capture.fix_message_json fm
--                                     where fm.fix_message_id = lst_ex.fix_message_id
--                                       and fm.date_id = lst_ex.exec_date_id
--                                       and fm.date_id between in_start_date_id and in_end_date_id
--                                     limit 1) fm_ex on true
        where true
--           and yc.status_date_id between :in_start_date_id and :in_end_date_id
--           and yc.account_id = any ('{68698,63384,63109,63706}')
--           and yc.multileg_reporting_type in ('1', '2')
--           and is_marketable = 'N'
--           and order_price >= 1
--         order by co.create_date_id, co.order_id;

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
        from trash.so_equity_non_marketable_jun_nov
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

-- EVERYTHING BELOW IS NOT FROM THIS TASK

create or replace function trash.so_parent_order(in_cnt int4 default 1000)
    returns int4
    language plpgsql
as
$$
DECLARE
    -- variables
    l_order_list int8[];
BEGIN

    select array_agg(order_id)
    into l_order_list
    from (select order_id
          from trash.so_f_parent_order tf
          where not tf.is_processed
          order by order_id asc
          limit in_cnt) x;
    perform data_marts.load_parent_order_inc(in_parent_order_ids := l_order_list, in_date_id := 20251128);

    update trash.so_f_parent_order tf
    set is_processed = true
    where tf.order_id = any (l_order_list)
      and not tf.is_processed;

    raise notice 'processed: - %', array_length(l_order_list, 1);
    return array_length(l_order_list, 1);
END
$$;
