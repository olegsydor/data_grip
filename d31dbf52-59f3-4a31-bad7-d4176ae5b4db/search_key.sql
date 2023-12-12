create or replace function trash.get_order_id_by_nk1(
    in_create_date_id int4, --index1
    in_client_order_id varchar(256), --index1
    in_fix_connection_id int4 --index1
)
    returns int8
    language sql
as
$$
select co.order_id
from dwh.client_order co
where co.create_date_id = in_create_date_id
  and co.fix_connection_id = in_fix_connection_id
  and co.client_order_id = in_client_order_id
    limit 1;
$$;


create function public.get_single_order_id(
    in_create_date_id int4,
    in_client_order_id varchar(256),
    in_fix_connection_id int4
)
    returns int8
    language plpgsql
as
$$
    -- SO
begin
    return (select co.order_id
            from dwh.client_order co
            where co.create_date_id = in_create_date_id
              and co.fix_connection_id = in_fix_connection_id
              and co.client_order_id = in_client_order_id
            limit 1);
end;
$$;

create function public.get_single_order_id(
    in_create_date_id int4,
    in_client_order_id varchar(256),
    in_fix_connection_id int4,
    in_side char default null::char,
    in_account_id int4 default null::int4
)
    returns int8
    language plpgsql
as
$$
    -- SO
begin
    return (select co.order_id
            from dwh.client_order co
            where co.create_date_id = in_create_date_id
              and co.fix_connection_id = in_fix_connection_id
              and co.client_order_id = in_client_order_id
              and case when in_side is null then true else co.side = in_side end
              and case when in_account_id is null then true else co.account_id = in_account_id end
            limit 1);
end;
$$;

do
$$
    declare
        ftr          record;
        ret_order_id int8;
        st_time      timestamp;
        fin_time     timestamp;
    begin
        st_time := clock_timestamp();
        raise notice 'st_time - %', st_time;
        for ftr in (select date_id, fix_connection_id, client_order_id, side, account_id
                    from dwh.flat_trade_record
                    where date_id = 20231025
                    and multileg_reporting_type = '1'
                    and side = '1'
                    limit 2)
            loop
            raise notice '%, %, %, %, %', ftr.date_id, ftr.fix_connection_id, ftr.client_order_id, ftr.side, ftr.account_id;
                select *
                into ret_order_id
                from public.get_single_order_id(ftr.date_id, ftr.client_order_id, ftr.fix_connection_id);--, ftr.side, ftr.account_id);
            end loop;
        fin_time := clock_timestamp();
        raise notice 'fin_time - %, durability - %', fin_time, fin_time - st_time;
    end;
$$
select * from public.get_single_order_id(in_create_date_id := 20231025, in_client_order_id := 'STE-58542624', in_fix_connection_id := 1389, in_side := '1', in_account_id := 66297);

select * from public.get_single_order_id(in_create_date_id := 20231025, in_client_order_id := 'STE-58542624', in_fix_connection_id := 1389, in_side := '1');

select * from public.get_single_order_id(in_create_date_id := 20231025, in_client_order_id := 'STE-58542624', in_fix_connection_id := 1389);


select key, colmn.each -> 'cnt' as cnt, colmn.each -> 'opt_customer_firm' as opt_customer_firm
from (select (jsonb_each(stats::jsonb)).*
      from trash.oh_data_observability_stats) x
         cross join lateral jsonb_array_elements(x.value) colmn(each);


create function dash360.report_surveillance_auction(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$

BEGIN
    return query
        select 'Trading Firm,Account,Ord Type,Ord Status,Event Date,Routed Time,Cl Ord ID,Side,Ord Qty,Ex Qty,Symbol,Price,Avg Px,Ex Dest,Sub Strategy,TIF,Client ID';

    return query
        select tf.trading_firm_name || ',' ||
               ac.account_name || ',' ||
               ot.order_type_short_name || ',' ||
               case ds.order_status
                   when '2' then 'filled'
                   when '4' then 'cancelled'
                   when '3' then 'done for day'
                   else coalesce(ds.order_status, '') end || ',' ||--ord status
               to_char(cl.create_time, 'YYYY-MM-DD') || ',' ||--Date
               to_char(cl.create_time, 'YYYY-MM-DD HH24:MI:SS:FF3') || ',' ||
               cl.client_order_id || ',' ||
               case cl.side
                   when '1' then 'Buy'
                   when '2' then 'Sell'
                   when '5' then 'Sell Short'
                   when '6' then 'Sell short'
                   else '' end || ',' ||
               cl.order_qty || ',' ||
               coalesce(ds.day_cum_qty::text, '') || ',' || --Ex Qty
               i.symbol || ',' ||
               cl.price || ',' ||
               coalesce(round(ds.day_avg_px, 4)::text, '') || ',' || --Avg Px
               case cl.ex_destination
                   when '39' then 'ARCA'
                   when '54' then 'BATS'
                   when 'XNYS' then 'NYSE'
                   when 'O' then 'NASDAQ'
                   when 'XASE' then 'AMEX'
                   when 'A' then 'AMEX'
                   else '' end || ',' ||
               cl.sub_strategy_desc || ',' ||
               tif.tif_name || ',' ||
               coalesce(cl.client_id::text, '')

        from dwh.client_order cl
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                 inner join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
                 inner join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
                 left join lateral (select fix_message ->> '9355' as t9355
                                    from fix_capture.fix_message_json fmj
                                    where true
                                      and fmj.date_id = cl.create_date_id
                                      and fmj.fix_message_id = cl.fix_message_id
                                      and fmj.date_id between in_start_date_id and in_end_date_id
                                    limit 1) fmj on true
                 inner join dwh.d_account ac on cl.account_id = ac.account_id and ac.is_active
                 inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 inner join lateral (select (array_agg(order_status order by exec_id desc))[1] as       order_status,
                                            sum(ex.last_qty * ex.last_px) / nullif(sum(ex.last_qty), 0) day_avg_px,
                                            sum(ex.last_qty)                                            day_cum_qty
                                     from dwh.execution ex
                                     where ex.order_id = cl.order_id
                                       and ex.exec_date_id = cl.create_date_id
                                       and ex.exec_date_id between in_start_date_id and in_end_date_id
                                       and ex.is_busted <> 'Y'
                                       and ex.exec_type in ('F', 'G')
                                     limit 1) ds on true
        where cl.create_date_id between in_start_date_id and in_end_date_id
          and cl.parent_order_id is null
          and cl.trans_type <> 'F'
          and cl.multileg_reporting_type in ('1', '2')
--    and cl.client_order_id in ('NHS.RT.ry920.2bg', 'NHS.RT.ry920.2bk', 'NHS.RT.ry920.2bo', 'NHS.RT.ry920.2bq', 'NHS.RT.ry920.2bs')
          and (
                (cl.ex_destination in ('39', '54', 'O', 'XNYS', 'A', 'XASE') and cl.order_type_id in ('B', '5') and
                 cl.time_in_force_id = '0')
                or (cl.ex_destination = '39' and cl.order_type_id in ('1', '2') and cl.time_in_force_id = '7')
                or (cl.ex_destination = '54' and cl.order_type_id in ('1', '2') and cl.time_in_force_id = '7' and
                    cl.routing_instr_side = 'B')
                or (cl.ex_destination = 'O' and cl.order_type_id in ('1', '2') and cl.time_in_force_id = '3' and
                    t9355 = 'C'))
          and ((cl.ex_destination in ('A', 'XNYS', 'XASE') and cl.create_time::time > '15:44:59'::time)
            or (cl.ex_destination = 'O' and cl.create_time::time > '15:49:59'::time)
            or (cl.ex_destination = '54' and cl.create_time::time > '15:54:59'::time)
            or (cl.ex_destination = '39' and cl.create_time::time > '15:58'::time)
            );
end;
$fx$

select * from dash360.report_surveillance_auction(20230607, 20230607)

NHS.RT.ry920.2bk
NHS.RT.ry920.2bo
NHS.RT.ry920.2bq
NHS.RT.ry920.2bs

select cl.order_id from dwh.client_order cl
join dwh.execution ex on ex.order_id = cl.order_id and ex.exec_date_id = cl.create_date_id
where cl.create_date_id = 20231102
and ex.is_busted = 'N'
and ex.exec_type in ('F', 'G')


select (array_agg(order_status order by exec_id desc))[1] as order_status,
       sum(ex.last_qty * ex.last_px) / sum(ex.last_qty) day_avg_px,
       sum(ex.last_qty)                                 day_cum_qty
from dwh.execution ex
where ex.order_id = 13605379387
  and ex.exec_date_id = 20231102
limit 1


drop function public.get_cross_order_id;
create or replace function public.get_cross_order_id(
    in_create_date_id int4,
    in_client_order_id varchar(256),
    in_fix_connection_id int4,
    in_co_client_leg_ref_id character varying(30) default null,
    in_parent_client_order_id varchar(256) default null,
    in_transaction_id int8 default null
)
    returns int8
    language plpgsql
as
$$
    -- SO
begin
    return (select co.order_id
            from dwh.client_order co
                     left join lateral ( select par.client_order_id as parent_client_order_id
                                         from dwh.client_order par
                                         where par.order_id = co.parent_order_id
                                           and par.create_date_id <= co.create_date_id
                                           and case
                                                   when in_parent_client_order_id is null then 1 = 2
                                                   else par.client_order_id = in_parent_client_order_id end
                                         limit 1) par on true
            where co.create_date_id = in_create_date_id
              and cross_order_id is not null
              and co.client_order_id = in_client_order_id
              and co.fix_connection_id = in_fix_connection_id
              and case
                      when in_co_client_leg_ref_id is null then co_client_leg_ref_id is null
                      else co.co_client_leg_ref_id = in_co_client_leg_ref_id end
              and case
                      when in_parent_client_order_id is not null
                          then par.parent_client_order_id = in_parent_client_order_id
                      else par.parent_client_order_id is null end
              and case
                      when in_transaction_id is null then co.transaction_id is null
                      else co.transaction_id = in_transaction_id end);
exception
    when others then return -5;

end;
$$;



do
$$
    declare
        rec          record;
        st_time      timestamp;
        fin_time     timestamp;
        ret_order_id int8;
    begin
        st_time := clock_timestamp();
        raise notice 'sql st_time - %', st_time;
        for rec in (select co.create_date_id,
                           co.client_order_id,
                           co.co_client_leg_ref_id,
                           co.fix_connection_id,
                           par.client_order_id as parent_client_order_id,
                           co.transaction_id
                    from dwh.client_order co
                             join dwh.client_order par
                                  on par.order_id = co.parent_order_id and par.create_date_id <= co.create_date_id
                    where co.create_date_id = 20231109
                      and co.cross_order_id is not null)
            loop
                select *
                into ret_order_id
                from public.get_cross_order_id(
                        in_create_date_id := rec.create_date_id,
                        in_client_order_id := rec.client_order_id,
                        in_fix_connection_id := rec.fix_connection_id,
                        in_co_client_leg_ref_id := rec.co_client_leg_ref_id,
                        in_parent_client_order_id := rec.parent_client_order_id);
                if ret_order_id < 0 then
                    raise notice '%, %, %, %, %', rec.create_date_id, rec.client_order_id, rec.fix_connection_id, rec.co_client_leg_ref_id, rec.parent_client_order_id;
                end if;
            end loop;
        fin_time := clock_timestamp();
        raise notice 'fin_time - %, durability - %', fin_time, fin_time - st_time;
    end;
$$;


select create_date_id, client_order_id, co_client_leg_ref_id, parent_client_order_id, fix_connection_id, *--count(*)
from dwh.client_order co
         join lateral ( select par.client_order_id as parent_client_order_id
                             from dwh.client_order par
                             where par.order_id = co.parent_order_id
                               and par.create_date_id <= co.create_date_id
                                and par.client_order_id = '13838274028009422848'
-- limit 1
             ) par
on true
where co.create_date_id = 20231109
  and co.cross_order_id is not null
   and co.client_order_id = 'DPAA0050-20231109'
  and co.fix_connection_id = 6736
   and parent_client_order_id = '13838274028009422848'
group by create_date_id, client_order_id, co_client_leg_ref_id, parent_client_order_id, fix_connection_id
having count(*) > 1;


20231109, DPAA0050-20231109, 6736, <NULL>, 13838274028009422848
20231109, DPAA0050-20231109, 6736, <NULL>, 3959170225
select co.client_order_id
     , co.create_date_id
     , co.parent_order_id
     , co.co_client_leg_ref_id
       , par.client_order_id
--       , count(*)
, *
from dwh.client_order co
join dwh.client_order par on par.order_id = co.parent_order_id
where co.create_date_id = 20231106
  and co.cross_order_id is not null
  and co.client_order_id = 'FNAA1621-20231106'
--   and account_id = 34069
  and co_client_leg_ref_id is null
group by client_order_id,
         create_date_id,
         parent_order_id,
         co_client_leg_ref_id
having count(*) > 1;

select * from public.get_cross_order_id(
    in_create_date_id := 20231106,
    in_client_order_id := 'CQBD7139-20231106' ,
    in_account_id := 34069,
    in_co_client_leg_ref_id := null
);


select
    cl.order_id,
    cro.order_id,
    cl.client_order_id
     , cl.create_date_id
     , cl.cross_order_id
     , cl.co_client_leg_ref_id
     , cro.client_order_id
 , *
--   , count(*)
from dwh.client_order cl
left join dwh.client_order cro on cro.cross_order_id = cl.cross_order_id and cro.order_id <> cl.order_id and cro.create_date_id = cl.create_date_id and cro.client_order_id = '37890738359458'
where cl.create_date_id = 20230912
  and cl.cross_order_id is not null
  and cl.client_order_id = '37890738359454'
  and cro.client_order_id = '37890738359458'
  and cl.co_client_leg_ref_id is null
  and cl.fix_connection_id = 944
    and cl.client_order_id in ('37890738359454'	,
'37890738359458'	,
'37898254562526'	,
'37898254562530'	,
'37898254562554'	,
'37898254565724'	,
'37898254565742'	,
'37898254566934'	,
'37898254566938'	,
'37898254572875'	,
'37898254572879'	,
'37898254572930'	,
'37898254572934'	,
'37905770749732'	,
'37913286960493'	,
'37913286960497'	,
'37913286960520'	,
'37913286960524'	,
'37924292807070'	,
'37924292807074'
)
group by cl.client_order_id,
         cl.create_date_id,
         cl.parent_order_id,
         cl.co_client_leg_ref_id,
         cl.cross_order_id,
         par.client_order_id
having count(*) > 1;



create function public.get_multileg_order_id(
    in_create_date_id int4,
    in_client_order_id varchar(256),
    in_co_client_leg_ref_id character varying(30) default null
)
    returns int8
    language plpgsql
as
$$
    -- SO
begin
    return (select co.order_id
            from dwh.client_order co
            where co.create_date_id = in_create_date_id
              and multileg_reporting_type <> '1'
              and co.client_order_id = in_client_order_id
              and case
                      when in_co_client_leg_ref_id is null then co_client_leg_ref_id is null
                      else co.co_client_leg_ref_id = in_co_client_leg_ref_id end
            limit 1);
end;
$$;

select * from public.get_multileg_order_id(20231106, 'CO41ORRF38K', null)


select * from fix_capture.fix_message_json fmj
where fmj.fix_message_id in (28069640855,
28069640867,
28069640886,
28069640840)


select create_date_id
     , client_order_id
     , co_client_leg_ref_id
--      , account_id
--      , count(*)
     , open_close
      , *
from dwh.client_order
where true
--   and client_order_id in ('1000015532419', 'RFQDD-56406', '7k003SXvw000001', 'DPAA3896-20231017')
  and cross_order_id is not null
  and client_order_id = 'DPAA2666-20231103'
  and create_date_id >= 20231101
group by create_date_id, client_order_id, co_client_leg_ref_id, open_close--, account_id
having count(*) > 1


select create_date_id, client_order_id, co_client_leg_ref_id, transaction_id, fix_connection_id, side,
       count(*)
from dwh.client_order
         where multileg_reporting_type = '1'
         and create_date_id = 20231107
group by create_date_id, client_order_id, co_client_leg_ref_id, transaction_id, fix_connection_id, side
having count(*) > 1
-- limit 1

select * from public.get_cross_order_id(
    in_create_date_id := 20231109,
    in_client_order_id := 'DPAA0050-20231109',
    in_fix_connection_id := 6736,
    in_co_client_leg_ref_id :=  null,
    in_parent_client_order_id := '13838274028009422848'
)
20231109, DPAA0050-20231109, 6736, <NULL>, 13838274028009422848;


select co.order_id, *
            from dwh.client_order co
                     left join lateral ( select par.client_order_id as parent_client_order_id
                                         from dwh.client_order par
                                         where par.order_id = co.parent_order_id
                                           and par.create_date_id <= co.create_date_id
                                           and par.client_order_id = '13838274028009422848'
                                         limit 1) par on true
            where co.create_date_id = 20231109
              and cross_order_id is not null
              and co.client_order_id = 'DPAA0050-20231109'
              and co.fix_connection_id = 6736
              and case
                      when in_co_client_leg_ref_id is null then co_client_leg_ref_id is null
                      else co.co_client_leg_ref_id = in_co_client_leg_ref_id end


create or replace function public.get_single_order_id(in_create_date_id integer, in_client_order_id character varying,
                                                      in_fix_connection_id integer,
                                                      in_side character default null::character(1)
)
    returns bigint
    language plpgsql
as
$fx$
    -- https://dashfinancial.atlassian.net/browse/DS-7457 SO 20231108
begin
    return (select co.order_id
            from dwh.client_order co
            where co.create_date_id = in_create_date_id
              and co.fix_connection_id = in_fix_connection_id
              and co.client_order_id = in_client_order_id
              and case when in_side is null then true else co.side = in_side end
            limit 1);
end;
$fx$
;
comment on function public.get_single_order_id is 'Getting order_id for single orders';


create or replace function public.get_multileg_order_id(in_create_date_id integer, in_client_order_id character varying,
                                                        in_fix_connection_id integer,
                                                        in_co_client_leg_ref_id character varying,
                                                        in_transaction_id int8)
    returns bigint
    language plpgsql
as
$function$
    -- https://dashfinancial.atlassian.net/browse/DS-7457 SO 20231108
begin
    return (select co.order_id
            from dwh.client_order co
            where co.create_date_id = in_create_date_id
              and multileg_reporting_type <> '1'
              and co.client_order_id = in_client_order_id
              and case
                      when in_transaction_id is null then co.transaction_id is null
                      else co.transaction_id = in_transaction_id end
              and co.fix_connection_id = in_fix_connection_id
              and case
                      when in_co_client_leg_ref_id is null then co_client_leg_ref_id is null
                      else co.co_client_leg_ref_id = in_co_client_leg_ref_id end
            limit 1);
end;
$function$
;
comment on function public.get_multileg_order_id is 'Getting order_id for multileg orders';


select * from public.get_multileg_order_id(in_create_date_id := 20230914, in_client_order_id := 'CO21KJ948EQ',
                                                        in_fix_connection_id := 3514,
                                                        in_co_client_leg_ref_id := null,
                                                        in_transaction_id := null);

select * from public.get_multileg_order_id(in_create_date_id := 20230914, in_client_order_id := 'CO71KJ97CM9',
                                                        in_fix_connection_id := 3514,
                                                        in_co_client_leg_ref_id := '3757',
                                                        in_transaction_id := 470052314935);

select * from public.get_single_order_id(in_create_date_id := 20231107, in_client_order_id := 'FOAK3578-20231107',
                                                      in_fix_connection_id := 2300);

select * from public.get_single_order_id(in_create_date_id := 20231107, in_client_order_id := 'EGAI4399-20231107',
                                                      in_fix_connection_id := 828, in_side := '2')



create function trash.get_business_date_back_sql(in_date date default ('now'::text)::date, in_offset integer default 0,
                                                 ignore_banking_holiday boolean default true)
    returns date
    language sql
    immutable
as
$function$

select generated.holiday_date as workday
from (select generate_series(dday - 8, dday, interval '1d')::date as holiday_date
      from (select $1 - $2 as dday) x) generated
         left join public.holiday_calendar h on (generated.holiday_date = h.holiday_date)
         left join public.banking_holiday_calendar bh on (generated.holiday_date = bh.banking_holiday_date)
where h.holiday_date is null
  and case when ignore_banking_holiday = false then bh.banking_holiday_date is null else true end
  and extract(isodow from generated.holiday_date) < 6
order by generated.holiday_date desc
limit 1;

$function$
;


create function trash.get_business_date_back_plpgsql(in_date date default ('now'::text)::date,
                                                     in_offset integer default 0,
                                                     ignore_banking_holiday boolean default true)
    returns date
    language plpgsql
    immutable
as
$function$
begin
    return (select generated.holiday_date as workday
            from (select generate_series(dday - 8, dday, interval '1d')::date as holiday_date
                  from (select $1 - $2 as dday) x) generated
                     left join public.holiday_calendar h on (generated.holiday_date = h.holiday_date)
                     left join public.banking_holiday_calendar bh on (generated.holiday_date = bh.banking_holiday_date)
            where h.holiday_date is null
              and case when ignore_banking_holiday = false then bh.banking_holiday_date is null else true end
              and extract(isodow from generated.holiday_date) < 6
            order by generated.holiday_date desc
            limit 1);
end
$function$
;


do
$$
    declare
        rec      record;
        st_time  timestamp;
        fin_time timestamp;
        ret_date date;
    begin
        st_time := clock_timestamp();
        raise notice 'st_time - %', st_time;
        for rec in (select * from generate_series('2020-06-01'::date, '2020-06-30'::date, interval '1 day') as dt)
            loop
                raise notice '%', rec.dt;
                select *
                into ret_date
                from trash.get_business_date_back_plpgsql(rec.dt::date);
            end loop;
        fin_time := clock_timestamp();
        raise notice 'fin_time - %, durability - %', fin_time, fin_time - st_time;
    end;
$$;


CREATE OR REPLACE FUNCTION trash.get_gth_date_id_by_instrument_type_sql(in_timestamp timestamp without time zone,
                                                                        in_instrument_type_id character)
    RETURNS integer
    LANGUAGE sql
    IMMUTABLE
AS
$function$
select case
           when to_char(in_timestamp, 'HH24')::int >= 19 and in_instrument_type_id in ('O', 'M')
               then trash.get_dateid_sql(trash.get_business_date_sql(in_timestamp::date, 1, true))
           else trash.get_dateid_sql(trash.get_business_date_sql(in_timestamp::date, 0, true))
           end;

$function$
;


CREATE OR REPLACE FUNCTION trash.get_gth_date_id_by_instrument_type_plpgsql(in_timestamp timestamp without time zone,
                                                                        in_instrument_type_id character)
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
    begin
return (select case
           when to_char(in_timestamp, 'HH24')::int >= 19 and in_instrument_type_id in ('O', 'M')
               then trash.get_dateid_plpgsql(trash.get_business_date_plpgsql(in_timestamp::date, 1, true))
           else trash.get_dateid_plpgsql(trash.get_business_date_plpgsql(in_timestamp::date, 0, true))
           end);
end;
$function$
;



create or replace function trash.get_dateid_sql(period date)
 returns integer
 language sql
 immutable
as $function$
    select to_char($1,'YYYYMMDD')::int as date_id;
$function$
;

create or replace drop function trash.get_dateid_plpgsql(period date)
    returns integer
    language plpgsql

as
$function$
begin
    return (select to_char($1, 'YYYYMMDD')::int as date_id);
end;
$function$
;



CREATE OR REPLACE FUNCTION trash.get_business_date_sql(in_date date DEFAULT ('now'::text)::date, in_offset integer DEFAULT 0, ignore_banking_holiday boolean DEFAULT true)
 RETURNS date
 LANGUAGE sql
 IMMUTABLE
AS $function$
SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday , dday+ 8 , interval '1d')::date AS holiday_date
	    FROM (SELECT $1 + $2 AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h on (generated.holiday_date = h.holiday_date)
	LEFT   JOIN public.banking_holiday_calendar bh  on (generated.holiday_date = bh.banking_holiday_date )
	WHERE  h.holiday_date IS null and (bh.banking_holiday_date is null or ignore_banking_holiday)
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date
	LIMIT  1;
$function$
;


CREATE OR REPLACE FUNCTION trash.get_business_date_plpgsql(in_date date DEFAULT ('now'::text)::date, in_offset integer DEFAULT 0, ignore_banking_holiday boolean DEFAULT true)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
    begin
        return (
SELECT generated.holiday_date AS workday
	FROM  (
	    SELECT generate_series(dday , dday+ 8 , interval '1d')::date AS holiday_date
	    FROM (SELECT $1 + $2 AS dday) x
	    ) generated
	LEFT   JOIN public.holiday_calendar h on (generated.holiday_date = h.holiday_date)
	LEFT   JOIN public.banking_holiday_calendar bh  on (generated.holiday_date = bh.banking_holiday_date )
	WHERE  h.holiday_date IS null and (bh.banking_holiday_date is null or ignore_banking_holiday)
	AND    extract(isodow from generated.holiday_date) < 6
	ORDER  BY generated.holiday_date
	LIMIT  1);
end;
$function$
;



do
$$
    declare
        rec      record;
        st_time  timestamp;
        fin_time timestamp;
        ret_date int4;
    begin
        st_time := clock_timestamp();
        raise notice 'plpgsql st_time - %', st_time;
        for rec in (
        select create_time, di.instrument_type_id from dwh.client_order co join dwh.d_instrument di using (instrument_id) where create_date_id = 20231109 limit 100000
        )
            loop
                select *
                into ret_date
                from trash.get_gth_date_id_by_instrument_type_plpgsql(rec.create_time, rec.instrument_type_id);
            end loop;
        fin_time := clock_timestamp();
        raise notice 'fin_time - %, durability - %', fin_time, fin_time - st_time;
    end;
$$;


do
$$
    declare
        st_time  timestamp;
        fin_time timestamp;
    begin
        st_time := clock_timestamp();
        raise notice 'sql st_time - %', st_time;
        create temp table t_so_sql as
        select trash.get_dateid_sql(trade_record_time::date)
        from dwh.flat_trade_record ftr
        where date_id between 20230901 and 20230930;
        fin_time := clock_timestamp();
        raise notice 'fin_time - %, durability - %', fin_time, fin_time - st_time;
    end;
$$;


select *
from public.get_cross_order_id(
        in_create_date_id := :in_create_date_id,
        in_client_order_id := :in_client_order_id,
        in_fix_connection_id := :in_fix_connection_id,
        in_co_client_leg_ref_id := :in_co_client_leg_ref_id,
        in_parent_client_order_id := :in_parent_client_order_id);



do
$$
    declare
    begin
        create temp table as select get_dateid        (            trade_record_id::date        )            from ftr
            where період дофіга великий.
            end;
$$


CREATE OR REPLACE FUNCTION public.get_dateid(period date)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
AS $function$
    select to_char($1,'YYYYMMDD')::Int as date_id;
$function$
;

drop function trash.get_dateid_plpgsql;
create function trash.get_dateid_plpgsql(period date) returns integer
    language plpgsql
    stable
as
$$
begin
    return (select to_char($1, 'YYYYMMDD')::int as date_id);
end;
$$;


select * from trash.get_dateid_plpgsql('2023-01-01')


-------------

select cross_order_id, multileg_reporting_type, fix_message_id,
       *
from dwh.client_order cl
where cl.create_date_id = 20230912
  and cl.cross_order_id is not null
  and cl.client_order_id = '37890738359454'
  and cl.co_client_leg_ref_id is null
  and cl.fix_connection_id = 944;


select co.cross_order_id
     , co.create_date_id
     , co.client_order_id
     , co.multileg_reporting_type
     , co.fix_connection_id
     , co.co_client_leg_ref_id
     , co.transaction_id
       , par.parent_client_order_id
     , *
from dwh.client_order co
         left join lateral ( select par.client_order_id as parent_client_order_id
                             from dwh.client_order par
                             where par.order_id = co.parent_order_id
                               and par.create_date_id <= co.create_date_id
                               and case
                                       when :in_parent_client_order_id is null then 1 = 2
                                       else par.client_order_id = :in_parent_client_order_id end
                             limit 1) par on true
where create_date_id = 20230912
  and client_order_id = '37890738359454'



select *
from public.get_cross_order_id(in_create_date_id := 20231109,
                               in_client_order_id := 'DUAA1318-20231109',
                               in_fix_connection_id := 2918,
                               in_co_client_leg_ref_id := '2',
                               in_parent_client_order_id := 'ZUy+GXl+TNKvndgDCKT/hg==_g2fm0vN',
                               in_transaction_id := 100552008460
     );



do
$$
    declare
        rec          record;
        st_time      timestamp;
        fin_time     timestamp;
        ret_order_id int8;
    begin
        st_time := clock_timestamp();
        raise notice 'sql st_time - %', st_time;
        for rec in (select co.create_date_id,
                           co.client_order_id,
                           co.co_client_leg_ref_id,
                           co.fix_connection_id,
                           par.client_order_id as parent_client_order_id,
--                            null as parent_client_order_id,
                           co.transaction_id
                    from dwh.client_order co
                             join lateral (select client_order_id from dwh.client_order par
                                  where par.order_id = co.parent_order_id and par.create_date_id <= co.create_date_id limit 1) par on true
                    where co.create_date_id = 20231109
                      and co.cross_order_id is not null
                    and co.parent_order_id is not null
                    and co.transaction_id is not null
                    limit 15)
            loop
                select *
                into ret_order_id
                from public.get_cross_order_id(
                        in_create_date_id := rec.create_date_id,
                        in_client_order_id := rec.client_order_id,
                        in_fix_connection_id := rec.fix_connection_id,
                        in_co_client_leg_ref_id := rec.co_client_leg_ref_id,
                        in_parent_client_order_id := rec.parent_client_order_id,
                        in_transaction_id := rec.transaction_id);
                if ret_order_id > 0 then
                    raise notice '%, %,  %, %, %, %', rec.create_date_id, rec.client_order_id, rec.fix_connection_id, rec.co_client_leg_ref_id, rec.parent_client_order_id, rec.transaction_id;
                end if;
            end loop;
        fin_time := clock_timestamp();
        raise notice 'fin_time - %, durability - %', fin_time, fin_time - st_time;
    end;
$$;

select * from client_order where client_order_id = 'DUAA1318-20231109' and create_date_id = 20231109;


CREATE OR REPLACE FUNCTION public.get_multileg_order_id(in_create_date_id integer, in_client_order_id character varying,
                                                        in_fix_connection_id integer,
                                                        in_co_client_leg_ref_id character varying,
                                                        in_transaction_id bigint)

select *
from public.get_single_order_id(in_create_date_id := _, in_client_order_id := _, in_fix_connection_id := _);

select *
from public.get_multileg_order_id(in_create_date_id := _, in_client_order_id := _, in_fix_connection_id := _,
                                  in_co_client_leg_ref_id := _, in_transaction_id := _);

select *
from public.get_cross_order_id(in_create_date_id := _, in_client_order_id := _, in_fix_connection_id := _,
                               in_co_client_leg_ref_id := _, in_parent_client_order_id := _, in_transaction_id := _);



create or replace function public.get_order_id_by_natural_key(in_create_date_id integer, -- $1
                                                              in_client_order_id character varying, -- $2
                                                              in_fix_connection_id integer, -- $3
                                                              in_side char(1), -- $4
                                                              in_co_client_leg_ref_id character varying, -- $5
                                                              in_transaction_id bigint, -- $6
                                                              in_parent_client_order_id character varying, -- $7
                                                              in_multileg_reporting_type char(1), -- $8
                                                              in_cross_order_id int8, -- $9
                                                              in_quote_id character varying -- $10
)
    returns int8
    language plpgsql
as
$function$
    -- 2023-11-29 SO https://dashfinancial.atlassian.net/browse/DS-7457
    -- The algorithm is described here https://dashfinancial.atlassian.net/wiki/spaces/DMP/pages/3773038946/DMP+Order+Search
declare
    ret_order_id text := null;

begin
    if in_multileg_reporting_type = '1' and (in_cross_order_id is null or in_quote_id is null) then
--         raise notice 'Single';
        select *
        into ret_order_id
        from public.get_single_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                        in_fix_connection_id := $3, in_side := $4);
        return ret_order_id;
    end if;


    if in_cross_order_id is null then
--         raise notice 'Multileg';
        select *
        into ret_order_id
        from public.get_multileg_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                          in_fix_connection_id := $3, in_co_client_leg_ref_id := $5,
                                          in_transaction_id := $6);
        return ret_order_id;
    end if;

--     raise notice 'Cross';
    select *
    into ret_order_id
    from public.get_cross_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                   in_fix_connection_id := $3,
                                   in_co_client_leg_ref_id := $5, in_parent_client_order_id := $7,
                                   in_transaction_id := $6);
    return ret_order_id;
end;
$function$
;


do
$$
    declare
        rc           record;
        ret_order_id int8;
        st_time      timestamp;
        fin_time     timestamp;
        n            int4 := 0;
    begin
        st_time := clock_timestamp();
        raise notice 'st_time - %', st_time;
        for rc in (select cl.order_id,
                          cl.create_date_id,
                          cl.client_order_id,
                          cl.fix_connection_id,
                          cl.side,
                          cl.co_client_leg_ref_id,
                          cl.transaction_id,
                          par.client_order_id as parent_client_order_id,
                          cl.multileg_reporting_type,
                          cl.cross_order_id,
                          cl.quote_id
                   from dwh.client_order cl
                            left join lateral (select client_order_id
                                               from dwh.client_order par
                                               where par.order_id = cl.parent_order_id
                                                 and par.create_date_id <= cl.create_date_id
--                                                limit 1
                       ) par on true
                   where create_date_id = 20231025
                     and multileg_reporting_type != '1'
                     and cross_order_id is not null
                   limit 2000)
            loop
                n := n + 1;
--                 raise notice '%', n;
                select *
                into ret_order_id
                from trash.get_wrapper_order_id(rc.create_date_id, rc.client_order_id, rc.fix_connection_id, rc.side,
                                                rc.co_client_leg_ref_id, rc.transaction_id, rc.parent_client_order_id,
                                                rc.multileg_reporting_type, rc.cross_order_id, rc.quote_id);
                if ret_order_id is null then
                    raise notice 'order_id - %; %, %, %, %, %, %', rc.order_id, rc.create_date_id, rc.client_order_id, rc.fix_connection_id, rc.co_client_leg_ref_id, rc.transaction_id, rc.parent_client_order_id;
                end if;
            end loop;
        fin_time := clock_timestamp();
        raise notice 'Count - %, fin_time - %, durability - %', n, fin_time, fin_time - st_time;
    end;
$$;

select * from public.get_cross_order_id(20231025, 'FOAA1532-20231025', 2969, null, '0780000002', 780219981362)

select multileg_reporting_type, cross_order_id, parent_order_id, client_order_id, fix_connection_id, co_client_leg_ref_id, transaction_id, quote_id
from dwh.client_order
where true
    and order_id = 13507479679
and create_date_id = 20231025
and client_order_id = 'CBAA0617-20231025'
and fix_connection_id = 2907;
select *
from trash.get_wrapper_order_id(
        in_create_date_id := _, in_client_order_id := _, in_fix_connection_id := _, in_co_client_leg_ref_id := _,
        in_transaction_id := _, in_parent_client_order_id := _
     );



select co.order_id, par.*
            from dwh.client_order co
                     left join lateral ( select par.client_order_id as parent_client_order_id
                                         from dwh.client_order par
                                         where par.order_id = co.parent_order_id
                                           and par.create_date_id <= co.create_date_id
                                           and case
                                                   when :in_parent_client_order_id is null then 1 = 2
                                                   else par.client_order_id = :in_parent_client_order_id end
--                                          limit 1
                         ) par on true
            where co.create_date_id = :in_create_date_id
              and cross_order_id is not null
              and co.client_order_id = :in_client_order_id
              and co.fix_connection_id = :in_fix_connection_id
              and case
                      when :in_co_client_leg_ref_id is null then co_client_leg_ref_id is null
                      else co.co_client_leg_ref_id = :in_co_client_leg_ref_id end
--               and case
--                       when :in_parent_client_order_id is not null
--                           then par.parent_client_order_id = :in_parent_client_order_id
--                       else par.parent_client_order_id is null end
              and case
                      when :in_transaction_id is null then co.transaction_id is null
                      else co.transaction_id = :in_transaction_id end


select *
from dwh.gtc_order_status gtc
    join dwh.CLIENT_ORDER CL using (create_date_id, order_id)
		  INNER JOIN dwh.d_INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
-- 		  INNER JOIN dwh.mv_ACTIVE_ACCOUNT_SNAPSHOT AC ON (CL.ACCOUNT_ID = AC.ACCOUNT_ID)
		  INNER JOIN EXECUTION EX ON (CL.ORDER_ID = EX.ORDER_ID)
		  INNER JOIN dwh.d_ORDER_STATUS ORS ON ORS.ORDER_STATUS = EX.ORDER_STATUS
		  WHERE CL.PARENT_ORDER_ID IS NULL
			AND CL.TIME_IN_FORCE_id = '1'
			AND CL.MULTILEG_REPORTING_TYPE in ('1','2')
			AND gtc.LAST_TRADE_DATE >= '2023-01-01'
-- 			AND NOT EXISTS (SELECT 1 FROM EXECUTION WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS IN ('2','4','8') and (TEXT <>'Instrument expiration' OR TEXT is NULL))
-- 			AND EX.EXEC_ID = (SELECT MAX(EXEC_ID) FROM EXECUTION WHERE ORDER_ID = CL.ORDER_ID AND ORDER_STATUS <> '3')
			AND gtc.account_id in (select account_id from dwh.mv_active_account_snapshot ac where AC.TRADING_FIRM_ID = 'baml' and ac.is_active)
		  and cl.create_date_id > 20230101

limit 1

select * from dwh.d_account
where trading_firm_id = 'baml'
and is_active