/*
select order_fix_message_id,
	trade_fix_message_id,
	street_order_fix_message_id,
	street_trade_fix_message_id,
	* from dwh.flat_trade_record ftr
where date_id = 20230905;

select *
from fix_capture.fix_message_json
where fix_message_id in (26882020354, 26882020392, 26882020360, 26882020379);


create or replace function trash.so_get_message_ftr_tag_string(in_date_id int4, in_trade_record_id int8,
                                                               in_tag_number int4,
                                                               in_fix_msg_type text)
    returns text
    language plpgsql
as
$fx$
    -- SO: 20230906 https://dashfinancial.atlassian.net/browse/DS-7217
declare
    l_fix_message_id  int8         := null;
    l_client_order_id varchar(256) := null;
    l_ret_value       text         := null;
    l_leg_ref_id      text         := null;
    l_is_cross        bool         := false;
    l_tag_number      int4         := in_tag_number;

    -- parent_order case: Get from FTR only. client_order_id can be null in case non cross
    -- street order case: Get from ftr and leg from client_order str
    -- any trade: get fix_message_id only, pass rest parameters as null / fasle

begin
    -- order_fix_message_id
    if in_fix_msg_type = 'order_fix_message_id' then
        select order_fix_message_id,
               leg_ref_id,
               case when is_cross_order = 'N' then false else true end,
               case when is_cross_order = 'N' then null else client_order_id end
        into l_fix_message_id, l_leg_ref_id, l_is_cross, l_client_order_id
        from dwh.flat_trade_record
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        -- street_order_fix_message_id
    elsif in_fix_msg_type = 'street_order_fix_message_id' then
        select street_order_fix_message_id,
               str.co_client_leg_ref_id,
               case when is_cross_order = 'N' then false else true end,
               client_order_id
        into l_fix_message_id, l_leg_ref_id, l_is_cross, l_client_order_id
        from dwh.flat_trade_record ftr
                 left join lateral (select co_client_leg_ref_id
                                    from dwh.client_order co
                                    where co.order_id = ftr.street_order_id
                                      and co.create_date_id >= ftr.date_id
                                    limit 1) str on true
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        -- trade_fix_message_id
    elsif in_fix_msg_type = 'trade_fix_message_id' then
        select trade_fix_message_id
        into l_fix_message_id
        from dwh.flat_trade_record
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        select fix_message ->> in_tag_number::text
        into l_ret_value
        from fix_capture.fix_message_json
        where date_id = in_date_id
          and fix_message_id = l_fix_message_id;
        return l_ret_value;

        -- street_trade_fix_message_id
    elsif in_fix_msg_type = 'street_trade_fix_message_id' then
        select street_trade_fix_message_id
        into l_fix_message_id
        from dwh.flat_trade_record
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        select fix_message ->> in_tag_number::text
        into l_ret_value
        from fix_capture.fix_message_json
        where date_id = in_date_id
          and fix_message_id = l_fix_message_id;
        return l_ret_value;

    else
        return null;
    end if;

    select public.get_message_tag_string_cross_multileg(in_fix_message_id := l_fix_message_id,
                                                        in_tag_number := l_tag_number, in_date_id := in_date_id,
                                                        in_client_order_id := l_client_order_id,
                                                        in_legref_id := l_leg_ref_id,
                                                        in_is_cross := l_is_cross)
    into l_ret_value;

    return l_ret_value;
end;
$fx$;

select * from trash.so_get_message_ftr_tag_string(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 10445,
                                                  in_fix_msg_type := 'order_fix_message_id')
union all
select * from trash.so_get_message_ftr_tag_string(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 10006,
                                                  in_fix_msg_type := 'trade_fix_message_id')
union all
select * from trash.so_get_message_ftr_tag_string(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 10001,
                                                  in_fix_msg_type := 'street_order_fix_message_id')
union all
select * from trash.so_get_message_ftr_tag_string(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 548,
                                                  in_fix_msg_type := 'street_trade_fix_message_id');



create or replace function trash.so_get_message_ftr_tag_string_2(in_date_id int4, in_trade_record_id int8,
                                                                 in_tag_number int4,
                                                                 in_fix_msg_type text)
    returns text
    language plpgsql
as
$fx$
    -- SO: 20230906 https://dashfinancial.atlassian.net/browse/DS-7217
declare
    l_fix_message_id  int8         := null;
    l_ret_value       text         := null;
    l_leg_ref_id      int4         := null;
    l_tag_number      int4         := in_tag_number;
    l_fix_message     json;

begin
    -- order_fix_message_id
    if in_fix_msg_type = 'order_fix_message_id' then
        select order_fix_message_id,
               leg_ref_id::int4
        into l_fix_message_id, l_leg_ref_id
        from dwh.flat_trade_record
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        -- street_order_fix_message_id
    elsif in_fix_msg_type = 'street_order_fix_message_id' then
        select street_order_fix_message_id,
               str.co_client_leg_ref_id::int4
        into l_fix_message_id, l_leg_ref_id
        from dwh.flat_trade_record ftr
                 left join lateral (select co_client_leg_ref_id
                                    from dwh.client_order co
                                    where co.order_id = ftr.street_order_id
                                      and co.create_date_id >= ftr.date_id
                                    limit 1) str on true
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        -- trade_fix_message_id
    elsif in_fix_msg_type = 'trade_fix_message_id' then
        select trade_fix_message_id
        into l_fix_message_id
        from dwh.flat_trade_record
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        select fix_message ->> in_tag_number::text
        into l_ret_value
        from fix_capture.fix_message_json
        where date_id = in_date_id
          and fix_message_id = l_fix_message_id;
        return l_ret_value;

        -- street_trade_fix_message_id
    elsif in_fix_msg_type = 'street_trade_fix_message_id' then
        select street_trade_fix_message_id
        into l_fix_message_id
        from dwh.flat_trade_record
        where date_id = in_date_id
          and trade_record_id = in_trade_record_id;

        select fix_message ->> in_tag_number::text
        into l_ret_value
        from fix_capture.fix_message_json
        where date_id = in_date_id
          and fix_message_id = l_fix_message_id;
        return l_ret_value;

    else
        return null;
    end if;

    raise notice 'l_fix_message_id - %, l_leg_ref_id - %', l_fix_message_id, l_leg_ref_id;

    select fix_message
    into l_fix_message
    from fix_capture.fix_message_json
    where date_id = in_date_id
      and fix_message_id = l_fix_message_id;

    select (array_agg(value order by rn))[l_leg_ref_id]
    into l_ret_value
    from (select key                  as tag,
                 value,
                 row_number() over () as rn
          FROM json_each_text(l_fix_message)) x
    where tag = l_tag_number::text
    group by tag;

    return l_ret_value;
end;
$fx$;


select * from trash.so_get_message_ftr_tag_string_2(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 10445,
                                                  in_fix_msg_type := 'order_fix_message_id')
union all
select * from trash.so_get_message_ftr_tag_string_2(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 10006,
                                                  in_fix_msg_type := 'trade_fix_message_id')
union all
select * from trash.so_get_message_ftr_tag_string_2(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 10001,
                                                  in_fix_msg_type := 'street_order_fix_message_id')
union all
select * from trash.so_get_message_ftr_tag_string_2(in_date_id := 20230816, in_trade_record_id := 3173998520, in_tag_number := 548,
                                                  in_fix_msg_type := 'street_trade_fix_message_id');

drop function trash.get_message_tag_string(int8,int4,int4,boolean,text)
)

create or replace function trash.get_message_tag_string2(in_fix_message_id int8,
                                                        in_tag_number int4,
                                                        in_date_id int4,
                                                        in_null_when_crash boolean default true,
                                                        in_leg_ref_id text default '1'
)
    returns character varying
    language plpgsql
as
$fx$
declare
    l_fix_message json;
    l_ret_value   text;
begin
    select fix_message
    into l_fix_message
    from fix_capture.fix_message_json
    where date_id = in_date_id
      and fix_message_id = in_fix_message_id;

    with base as (select key                  as tag,
                         value,
                         row_number() over () as rn
                  from json_each_text(l_fix_message))
       , legs as (select tag,
                         value,
                         row_number() over (partition by tag order by rn) as leg_number_id
                  from base)
       , leg_id as (select leg_number_id
                    from legs
                    where tag = '654'
                      and value = in_leg_ref_id)
    select value
    into l_ret_value
    from legs,
         leg_id
    where legs.tag = in_tag_number::text
      and legs.leg_number_id = leg_id.leg_number_id;

    return l_ret_value;

exception
    when others then
        raise notice 'invalid varchar value: "%".  returning null.', l_ret_value;
        l_ret_value := case when in_null_when_crash is true then null else l_ret_value::varchar end;
        return l_ret_value;
end;
$fx$;


select date_id, fix_message_id, fix_message ->>'654', fix_message
from fix_capture.fix_message_json
where date_id = 20230907
  and fix_message ->>'654' is null
    and not public.is_digit(fix_message ->>'654')

select * from trash.get_message_tag_string2(in_fix_message_id := 27281859257,
                                             in_tag_number := 60,
                                             in_date_id := 20230907)

select * from trash.get_message_tag_string2(in_fix_message_id := 27281859283,
                                             in_tag_number := 612,
                                             in_date_id := 20230907,
                                             in_leg_ref_id := 'i111')



select * from fix_capture.fix_message_json
where fix_message_id = 26897407302;

select '{"8":"FIX.4.2","9":"1168","35":"As","49":"GTHLB","56":"SEG71_OPT_RCS","34":"1566","52":"20230817-13:55:55.002","100":"B","9000":"DMA","18":"f","38":"1500","40":"2","44":"-0.03","55":"IWM","59":"3","60":"20230817-13:55:54.897","167":"MLEG","548":"1_co230817","9202":"R","552":"2","11":"1_cp230817","1":"RFABOXCROSS1","76":"010","109":"jcardinale2","204":"0","376":"546690952857649152","10009":"O","10440":"74FA0409","6376":"546691266100854786","10445":"BTIG-GS","10562":"BPAA0021-20230817","11":"1_cq230817","1":"RFABOXCROSS2","76":"595","109":"jcardinale2","204":"2","555":"6","654":"1","600":"IWM","608":"OP","611":"20230915","612":"185","623":"1","624":"2","564":"C","9564":"C","10500":"3.51","10501":"3.54","654":"2","600":"IWM","608":"OP","611":"20230915","612":"175","623":"2","624":"1","564":"C","9564":"C","10500":"1.12","10501":"1.14","654":"3","600":"IWM","608":"OP","611":"20230915","612":"165","623":"1","624":"2","564":"C","9564":"C","10500":"0.4","10501":"0.41","654":"4","600":"IWM","608":"OP","611":"20230929","612":"182","623":"1","624":"1","564":"C","9564":"C","10500":"3.5","10501":"3.54","654":"5","600":"IWM","608":"OP","611":"20230929","612":"170","623":"2","624":"2","564":"C","9564":"C","10500":"1.19","10501":"1.22","654":"6","600":"IWM","608":"OP","611":"20230929","612":"158","623":"1","624":"1","564":"C","9564":"C","6606":"DASHCROSS","5049":"DASHCROSS","5050":"20230817-13:55:54.901534","5056":"DASHLB","6376":"546691266100854788","9291":"N","9461":"0","10006":"SEG71_SCORE5","10009":"C","10056":"DASHLB","10057":"715","10061":"20230817-13:55:54.897","10500":"0.45","10501":"0.47","10502":"0","10503":"707390","10504":"0","10505":"0","10":"232"}'::json


select count(*)                                  as count,
       (count(*) filter (where is_busted = 'Y')) as busted
from dwh.flat_trade_record ftr
where date_id = 20230918;


select typname, typlen, nspname
from pg_type t
         join pg_namespace n
              on t.typnamespace = n.oid
where nspname = 'pg_catalog'
  and typname !~ '(^_|^pg_|^reg|_handlers$)'
order by nspname, typname;


select *
from dash360.report_gtc_recon(
  --in_trading_firm_ids => array['OFP0022']
  in_account_ids => array[28517,20805],
  in_instrument_type => null
)

select * from dwh.client_order
where client_order_id = 'N2/5059/X03/099236/23268HC0QQ'

select cl.order_qty,
       dwh.get_cum_qty_from_orig_orders(in_order_id => cl.order_id, in_date_id => cl.create_date_id) as daso_quantity
, * from dwh.client_order cl
where cl.client_order_id in ('N2/5059/X03/099236/23268HC0QQ', 'N2/5060/X03/099236/23268HC109');

  create temp table tmp_gtc_fidelity_retail_ord_open as
  select gtc.account_id,
         gtc.order_id,
         cl.client_order_id,
         gtc.create_date_id,
         cl.instrument_id,
         cl.order_type_id,
         cl.time_in_force_id,
         cl.stop_price,
         cl.price,
         cl.order_qty,
         cl.create_time,
         cl.side,
         cl.open_close,
         gtc.close_date_id,
         cl.multileg_reporting_type
    from dwh.gtc_order_status gtc
           join dwh.client_order cl using (order_id, create_date_id)
  where true
    and gtc.account_id in (select ac.account_id
                           from dwh.d_account ac
                           where ac.trading_firm_id = 'OFP0022')
--      and fyc.trading_firm_unq_id = any(l_trading_firm_unq_ids)
    and cl.parent_order_id is null
    --and fyc.instrument_type_id = 'O'
    and gtc.time_in_force_id = '1'
--       and gtc.create_date_id >= :l_gtc_date_id
    and gtc.create_date_id <= :l_current_date_id
    and cl.sub_strategy_id in (select dts.target_strategy_id
                               from dwh.d_target_strategy dts
                               where dts.target_strategy_name = 'RETAIL')
    and ((gtc.close_date_id is not null and gtc.close_date_id >= :l_current_date_id)
      or gtc.close_date_id is null)
--     and cl.multileg_reporting_type = :l_multileg_reporting_type
   and cl.client_order_id in ('N2/5059/X03/099236/23268HC0QQ', 'N2/5060/X03/099236/23268HC109')

select * from tmp_gtc_fidelity_retail_ord_open
  select 'DASO' as daso_mm_firm
          , to_char(co.create_time, 'YYMMDD') as daso_ord_date
          --, 'XX9999' as daso_mkt_seq
          , left(replace(replace(co.client_order_id,'/',''),'-',''),6) as daso_mkt_seq -- https://dashfinancial.atlassian.net/browse/DEVREQ-1387
          , case when co.side in ('1','3') then 'B' else 'S' end as daso_action
          , rpad(case oc.put_call when '0' then 'P' when '1' then 'C' else '' end,1,' ') as daso_put_call_ind
          , rpad(coalesce(co.open_close, ''),1,' ') as daso_open_close_ind
          --, lpad((co.order_qty - coalesce(ex.cum_qty, 0))::varchar,8,'0') as daso_quantity
          , lpad((co.order_qty - coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id), 0))::varchar,8,'0') as daso_quantity
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),5,' ') as daso_opra_code
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),8,' ') as daso_udly_symbol
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),6,' ') as daso_optn_symbol
          , coalesce(to_char(di.last_trade_date, 'YY'), '  ') as daso_exp_year
          , coalesce(to_char(di.last_trade_date, 'MON'), '   ') as daso_month_name
          , coalesce(to_char(di.last_trade_date, 'MM'),'  ') as daso_month_num
          , coalesce(to_char(di.last_trade_date, 'DD'),'  ') as daso_exp_day
          , lpad(coalesce((oc.strike_price * 1000000000)::numeric(24,0),0)::varchar,18,'0') as daso_strike_price
          , coalesce(upper(ot.order_type_short_name), '   ') as daso_mkt_lmt
          , lpad(coalesce((abs(co.price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as daso_lmt_price
          , rpad(coalesce((abs(co.stop_price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as daso_stp_price
          , coalesce(upper(tif.tif_short_name), '   ') as daso_tif
          , 'LST' as daso_listed_otc_ind
          --, lpad(' ',19,' ')
          --|| lpad(co.client_order_id,10,' ') as daso_order_num
          , lpad(co.client_order_id,29,' ') as daso_order_num
          , lpad(' ',28,' ') as filler
          , '2' as daso_d_rec_id
          , case
              --when coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id), 0) >= co.order_qty then 1 -- order is filled -- too long
              when ex.max_exec_type = '4' then 1 -- order is cancelled
              when ex.max_exec_type = '8' then 1 -- order was rejected
              when ex.max_order_status in ('2', '4', '5', '8') then 1 -- order status: filled, canceled, replaced, rejected
              --when coalesce(di.last_trade_date, current_timestamp) <= current_timestamp  then 1 -- Expiration date of instrument is exceeded
              when to_char(coalesce(di.last_trade_date, current_timestamp), 'YYYYMMDD')::integer < :l_current_date_id  then 1 -- Expiration date of instrument is exceeded
              else 0
            end as gts_is_closed
          --, ac.trading_firm_id
          --, co.*
        from --tmp_gtc_fidelity_retail_ord fyc
             tmp_gtc_fidelity_retail_ord_open fyc
          inner join lateral
            (
              select cl.client_order_id
                , cl.create_time
                , cl.side, cl.open_close
                , cl.order_qty, cl.price, cl.stop_price
                , cl.parent_order_id
                , cl.instrument_id, cl.order_type_id, cl.time_in_force_id
                , cl.order_id, cl.create_date_id
              from dwh.client_order cl
              where cl.order_id = fyc.order_id
                and cl.sub_strategy_id in (select dts.target_strategy_id from dwh.d_target_strategy dts where dts.target_strategy_name = 'RETAIL') -- only 9000 tag = RETAIL
                and cl.time_in_force_id = '1' -- in ('1','C','M') -- GTC hardcode - no GTC found for , but are found for
                and cl.multileg_reporting_type = :l_multileg_reporting_type
                and cl.trans_type <> 'F'
                and cl.create_date_id >= :l_gtc_date_id
                and cl.create_date_id <= :l_current_date_id
                and cl.parent_order_id is null
            ) co on true
          --join dwh.d_account ac on ac.account_id = co.account_id
          left join dwh.d_option_contract oc
            on oc.instrument_id = co.instrument_id
          left join dwh.d_instrument di
            on di.instrument_id = co.instrument_id
          left join dwh.d_order_type ot
            on co.order_type_id = ot.order_type_id
          left join dwh.d_time_in_force tif
            on co.time_in_force_id = tif.tif_id
          left join lateral
            (
              select ex.order_id
                , max(ex.exec_type) as max_exec_type
                , max(ex.order_status) as max_order_status
                --, sum(case when ex.exec_type in ('F','1','2') then ex.last_qty else 0 end) as cum_qty
                , max(ex.exec_time) as max_exec_time
              from dwh.execution ex
              where ex.exec_date_id >= :l_gtc_date_id
                and ex.exec_date_id <= :l_current_date_id
                and ex.order_id = co.order_id
                --and ex.exec_type in ('F','1','2','4','8') -- fill, canc, rej
                and
                  (
                    --ex.exec_type in ('F','1','2','4','8') -- fill, canc, rej, replaced
                    ex.exec_type in ('4','8') -- fill, canc, rej, replaced
                    or
                    ex.order_status in ('2', '4', '5', '8') -- fill, canc, rej, replaced
                  )
                and is_busted = 'N'
              group by ex.order_id
              limit 1
            ) ex on true
        where 1=1

  select create_date_id, client_order_id, stop_price, abs(stop_price) * 10000000::numeric(24,0),
rpad(coalesce((abs(stop_price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as daso_stp_price

select rpad('oleh', 10, '0'), lpad('oleh', 10, '0')


  from dwh.client_order
  where create_date_id = 20230925
  and client_order_id in ('N2/5059/X03/099236/23268HC0QQ', 'N2/5060/X03/099236/23268HC109')

*/
drop function if exists trash.so_report_gtc_fidelity_retail;
CREATE FUNCTION trash.so_report_gtc_fidelity_retail(p_is_multileg_report character varying DEFAULT 'N'::character varying,
                                                              p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                              p_report_date_id integer DEFAULT NULL::integer,
                                                              p_instrument_type_id character varying DEFAULT 'O'::character varying,
                                                              p_account_ids int4[] default '{}'::int4[]
                                                              )
    RETURNS TABLE
            (
                export_row text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
  l_row_cnt       integer;

  l_current_date_id  integer;
  l_gtc_date_id    integer;
  l_instrument_type varchar;
  l_multileg_reporting_type bpchar(1);
l_account_ids int4[];

   l_load_id        integer;
   l_step_id        integer;

begin
  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_fidelity_retail STARTED===', 0, 'O')
   into l_step_id;

   l_current_date_id := coalesce(p_report_date_id, (to_char(NOW(), 'YYYYMMDD'))::integer);

   l_gtc_date_id := to_char((to_date(l_current_date_id::varchar, 'YYYYMMDD') - interval '24 months'), 'YYYYMMDD')::integer;

  select array_agg(account_id)
  into l_account_ids
  from dwh.d_account
  where true
    and case when coalesce(p_account_ids, '{}') = '{}' then true else account_id = any (p_account_ids) end
    and case
            when p_trading_firm_ids = '{}' then trading_firm_id = 'OFP0022'
            else trading_firm_id = any (p_trading_firm_ids) end;

   l_multileg_reporting_type := case when p_is_multileg_report = 'Y' then '2' else '1' end;

   l_instrument_type := p_instrument_type_id;

    select public.load_log(l_load_id, l_step_id, left(' account_ids = '||l_account_ids::varchar, 200), 0, 'O')
   into l_step_id;
    select public.load_log(l_load_id, l_step_id, ' Period: l_current_date_id = '||l_current_date_id::varchar||', l_gtc_date_id = '||l_gtc_date_id::varchar||', l_multileg_reporting_type = '||l_multileg_reporting_type::varchar, 0, 'O')
   into l_step_id;

  create temp table if not exists tmp_gtc_fidelity_retail_roe
    (
      roe  text
    )
  on commit DROP;
  truncate table tmp_gtc_fidelity_retail_roe;

  DROP TABLE IF EXISTS tmp_gtc_fidelity_retail_ord_open;
  create temp table tmp_gtc_fidelity_retail_ord_open with (parallel_workers = 4)
                                                     ON COMMIT drop as
  select gtc.account_id,
         gtc.order_id,
         cl.client_order_id,
         gtc.create_date_id,
         cl.instrument_id,
         cl.order_type_id,
         cl.time_in_force_id,
         cl.stop_price,
         cl.price,
         cl.order_qty,
         cl.create_time,
         cl.side,
         cl.open_close,
         gtc.close_date_id
  from dwh.gtc_order_status gtc
           join dwh.client_order cl using (order_id, create_date_id)
  join dwh.d_instrument di on di.instrument_id = cl.instrument_id
  where true
  and cl.account_id = any(l_account_ids)
    and cl.parent_order_id is null
    and case when l_instrument_type is null then true else instrument_type_id = l_instrument_type end
    and gtc.time_in_force_id = '1'
--       and gtc.create_date_id >= :l_gtc_date_id
    and gtc.create_date_id <= l_current_date_id
    and cl.sub_strategy_id in (select dts.target_strategy_id
                               from dwh.d_target_strategy dts
                               where dts.target_strategy_name = 'RETAIL')       -- only 9000 tag = RETAIL
    and ((gtc.close_date_id is not null and gtc.close_date_id >= l_current_date_id)
      or gtc.close_date_id is null)
    and cl.multileg_reporting_type = l_multileg_reporting_type
--   and cl.client_order_id in ('N2/5059/X03/099236/23268HC0QQ', 'N2/5060/X03/099236/23268HC109')
    ;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    --RAISE INFO 'Found: % rows', l_row_cnt;
   select public.load_log(l_load_id, l_step_id, 'insert into tmp_gtc_fidelity_retail_ord_open ', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

  --return;

  if p_is_multileg_report = 'N'
  then
     -- Report Name: Fidelity Single-leg Open Order Report
    insert into tmp_gtc_fidelity_retail_roe (roe)
    select s.daso_mm_firm
        || s.daso_ord_date
        || s.daso_mkt_seq
        || s.daso_action
        || s.daso_put_call_ind
        || s.daso_open_close_ind
        || s.daso_quantity
        || s.daso_opra_code
        || s.daso_udly_symbol
        || s.daso_optn_symbol
        || s.daso_exp_year
        || s.daso_month_name
        || s.daso_month_num
        || s.daso_exp_day
        || s.daso_strike_price
        || s.daso_mkt_lmt
        || s.daso_lmt_price
        || s.daso_stp_price
        || s.daso_tif
        || s.daso_listed_otc_ind
        || s.daso_order_num
        || s.filler
        || s.daso_d_rec_id

        as roe
    -- select s.* --s.trading_firm_id, s.gts_is_closed, count(1) as cnt
    from
      (
        select 'DASO' as daso_mm_firm
          , to_char(co.create_time, 'YYMMDD') as daso_ord_date
          --, 'XX9999' as daso_mkt_seq
          , left(replace(replace(co.client_order_id,'/',''),'-',''),6) as daso_mkt_seq -- https://dashfinancial.atlassian.net/browse/DEVREQ-1387
          , case when co.side in ('1','3') then 'B' else 'S' end as daso_action
          , rpad(case oc.put_call when '0' then 'P' when '1' then 'C' else '' end,1,' ') as daso_put_call_ind
          , rpad(coalesce(co.open_close, ''),1,' ') as daso_open_close_ind
          --, lpad((co.order_qty - coalesce(ex.cum_qty, 0))::varchar,8,'0') as daso_quantity
          , lpad((co.order_qty - coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id), 0))::varchar,8,'0') as daso_quantity
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),5,' ') as daso_opra_code
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),8,' ') as daso_udly_symbol
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),6,' ') as daso_optn_symbol
          , coalesce(to_char(di.last_trade_date, 'YY'), '  ') as daso_exp_year
          , coalesce(to_char(di.last_trade_date, 'MON'), '   ') as daso_month_name
          , coalesce(to_char(di.last_trade_date, 'MM'),'  ') as daso_month_num
          , coalesce(to_char(di.last_trade_date, 'DD'),'  ') as daso_exp_day
          , lpad(coalesce((oc.strike_price * 1000000000)::numeric(24,0),0)::varchar,18,'0') as daso_strike_price
          , coalesce(upper(ot.order_type_short_name), '   ') as daso_mkt_lmt
          , lpad(coalesce((abs(co.price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as daso_lmt_price
          , rpad(coalesce((abs(co.stop_price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as daso_stp_price
          , coalesce(upper(tif.tif_short_name), '   ') as daso_tif
          , 'LST' as daso_listed_otc_ind
          --, lpad(' ',19,' ')
          --|| lpad(co.client_order_id,10,' ') as daso_order_num
          , lpad(co.client_order_id,29,' ') as daso_order_num
          , lpad(' ',28,' ') as filler
          , '2' as daso_d_rec_id
          , case
              --when coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id), 0) >= co.order_qty then 1 -- order is filled -- too long
              when ex.max_exec_type = '4' then 1 -- order is cancelled
              when ex.max_exec_type = '8' then 1 -- order was rejected
              when ex.max_order_status in ('2', '4', '5', '8') then 1 -- order status: filled, canceled, replaced, rejected
              --when coalesce(di.last_trade_date, current_timestamp) <= current_timestamp  then 1 -- Expiration date of instrument is exceeded
              when to_char(coalesce(di.last_trade_date, current_timestamp), 'YYYYMMDD')::integer < l_current_date_id  then 1 -- Expiration date of instrument is exceeded
              else 0
            end as gts_is_closed
          --, ac.trading_firm_id
          --, co.*
        from --tmp_gtc_fidelity_retail_ord fyc
             tmp_gtc_fidelity_retail_ord_open fyc
          inner join lateral
            (
              select cl.client_order_id
                , cl.create_time
                , cl.side, cl.open_close
                , cl.order_qty, cl.price, cl.stop_price
                , cl.parent_order_id
                , cl.instrument_id, cl.order_type_id, cl.time_in_force_id
                , cl.order_id, cl.create_date_id
              from dwh.client_order cl
              where cl.order_id = fyc.order_id
                and cl.sub_strategy_id in (select dts.target_strategy_id from dwh.d_target_strategy dts where dts.target_strategy_name = 'RETAIL') -- only 9000 tag = RETAIL
                and cl.time_in_force_id = '1' -- in ('1','C','M') -- GTC hardcode - no GTC found for , but are found for
                and cl.multileg_reporting_type = l_multileg_reporting_type
                and cl.trans_type <> 'F'
                and cl.create_date_id >= l_gtc_date_id
                and cl.create_date_id <= l_current_date_id
                and cl.parent_order_id is null
            ) co on true
          --join dwh.d_account ac on ac.account_id = co.account_id
          left join dwh.d_option_contract oc
            on oc.instrument_id = co.instrument_id
          left join dwh.d_instrument di
            on di.instrument_id = co.instrument_id
          left join dwh.d_order_type ot
            on co.order_type_id = ot.order_type_id
          left join dwh.d_time_in_force tif
            on co.time_in_force_id = tif.tif_id
          left join lateral
            (
              select ex.order_id
                , max(ex.exec_type) as max_exec_type
                , max(ex.order_status) as max_order_status
                --, sum(case when ex.exec_type in ('F','1','2') then ex.last_qty else 0 end) as cum_qty
                , max(ex.exec_time) as max_exec_time
              from dwh.execution ex
              where ex.exec_date_id >= l_gtc_date_id
                and ex.exec_date_id <= l_current_date_id
                and ex.order_id = co.order_id
                --and ex.exec_type in ('F','1','2','4','8') -- fill, canc, rej
                and
                  (
                    --ex.exec_type in ('F','1','2','4','8') -- fill, canc, rej, replaced
                    ex.exec_type in ('4','8') -- fill, canc, rej, replaced
                    or
                    ex.order_status in ('2', '4', '5', '8') -- fill, canc, rej, replaced
                  )
                and is_busted = 'N'
              group by ex.order_id
              limit 1
            ) ex on true
        where true
      ) s
    where true
      and s.gts_is_closed = 0
    ;

  else
     -- Report Name: Fidelity Multi-leg Open Order Report
    insert into tmp_gtc_fidelity_retail_roe (roe)
    select s.dasm_mm_firm
        || s.dasm_ord_date
        || s.dasm_mkt_seq
        || s.dasm_action
        || s.dasm_put_call_ind
        || s.dasm_open_close_ind
        || s.dasm_quantity
        || s.dasm_opra_code
        || s.dasm_udly_symbol
        || s.dasm_optn_symbol
        || s.dasm_exp_year
        || s.dasm_month_name
        || s.dasm_month_num
        || s.dasm_exp_day
        || s.dasm_strike_price
        || s.dasm_mkt_lmt
        || s.dasm_lmt_price
        || s.dasm_stp_price
        || s.dasm_tif
        || s.dasm_listed_otc_ind
        || s.dasm_order_id
        || s.filler
        || s.dasm_d_rec_id

        as roe
    -- select s.* --s.trading_firm_id, s.gts_is_closed, count(1) as cnt
    from
      (

        select 'DASM' as dasm_mm_firm
          , to_char(co.create_time, 'YYMMDD') as dasm_ord_date
          --, 'XX9999' as daso_mkt_seq
          , left(replace(replace(co.client_order_id,'/',''),'-',''),6) as dasm_mkt_seq -- https://dashfinancial.atlassian.net/browse/DEVREQ-1387
          , case when co.side in ('1','3') then 'B' else 'S' end as dasm_action
          , rpad(case oc.put_call when '0' then 'P' when '1' then 'C' else '' end,1,' ') as dasm_put_call_ind
          , rpad(coalesce(co.open_close, ''),1,' ') as dasm_open_close_ind
          --, lpad((co.order_qty - coalesce(ex.cum_qty, 0))::varchar,8,'0') as dasm_quantity
          , lpad((co.order_qty - coalesce(dwh.get_cum_qty_from_orig_orders_interval(in_order_id => co.order_id, in_date_id => co.create_date_id, in_max_date_id => l_current_date_id), 0))::varchar, 8, '0') as dasm_quantity
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),5,' ') as dasm_opra_code
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),8,' ') as dasm_udly_symbol
          , rpad(di.symbol||coalesce(di.symbol_suffix,''),6,' ') as dasm_optn_symbol
          , coalesce(to_char(di.last_trade_date, 'YY'), '  ') as dasm_exp_year
          , coalesce(to_char(di.last_trade_date, 'MON'), '   ') as dasm_month_name
          , coalesce(to_char(di.last_trade_date, 'MM'),'  ') as dasm_month_num
          , coalesce(to_char(di.last_trade_date, 'DD'),'  ') as dasm_exp_day
          , lpad(coalesce((oc.strike_price * 1000000000)::numeric(24,0),0)::varchar,18,'0') as dasm_strike_price
          , coalesce(upper(ot.order_type_short_name), '   ') as dasm_mkt_lmt
          , lpad(coalesce((abs(co.price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as dasm_lmt_price
          , rpad(coalesce((abs(co.stop_price) * 10000000)::numeric(24,0),0)::varchar,11,'0') as dasm_stp_price
          , coalesce(upper(tif.tif_short_name), '   ') as dasm_tif
          , 'LST' as dasm_listed_otc_ind
          , lpad(co.client_order_id,29,' ') as dasm_order_id -- filler(19) + order_id(10)
          , lpad(' ',2,' ') as filler
          , '2' as dasm_d_rec_id
            , case when close_date_id is null then 0
            when close_date_id <= l_current_date_id then 1
            else 0
            end as gts_is_closed
        from tmp_gtc_fidelity_retail_ord_open co
            inner join lateral
              (
                select 1
                from dwh.client_order cl
                where cl.order_id = co.order_id
                  and cl.sub_strategy_id = 78 --in (select dts.target_strategy_id from dwh.d_target_strategy dts where dts.target_strategy_name = 'RETAIL') -- only 9000 tag = RETAIL
                  and cl.time_in_force_id = '1' -- in ('1','C','M') -- GTC hardcode - no GTC found for , but are found for
                  and cl.multileg_reporting_type = '2' --l_multileg_reporting_type
                  and cl.trans_type <> 'F'
                  and cl.create_date_id >= l_gtc_date_id
                  and cl.create_date_id <= l_current_date_id
                  and cl.parent_order_id is null
                  limit 1
              ) co_in on true
          --join dwh.d_account ac on ac.account_id = co.account_id
          left join dwh.d_option_contract oc on oc.instrument_id = co.instrument_id
          left join dwh.d_option_series dos on dos.option_series_id = oc.option_series_id
          left join dwh.d_instrument di    on di.instrument_id = co.instrument_id
          left join dwh.d_order_type ot      on co.order_type_id = ot.order_type_id
          left join dwh.d_time_in_force tif  on co.time_in_force_id = tif.tif_id

        where true
        and coalesce (close_date_id, 30011231) > l_current_date_id  -- as a max date to comare
--        and case when (dos.exercise_style = 'E' and di.last_trade_date = l_current_date_id::text::date + interval '1 day') then false else true end
        and case when (di.symbol in ('VIX', 'SPX') and di.last_trade_date = l_current_date_id::text::date + interval '1 day') then false else true end
      ) s
    where true
--      and s.gts_is_closed = 0
    ;
  end if;
    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    --RAISE INFO 'Found: % rows', l_row_cnt;
   select public.load_log(l_load_id, l_step_id, 'insert into tmp_gtc_fidelity_retail_roe ', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

  l_row_cnt := coalesce((select count(1) from tmp_gtc_fidelity_retail_roe), 0);

  if p_is_multileg_report = 'N'
  then
     -- Report Name: Fidelity Single-leg Open Order Report
   RETURN QUERY
     select
       rpad('DASO'::varchar, 4, ' ') || -- DASO-FILE-ID
       rpad(to_char(to_date(l_current_date_id::varchar,'YYYYMMDD'), 'YYMMDD'), 6, ' ') || -- DASO-FILE-DATE  l_current_date_id - Current business date
       rpad(' '::varchar, 151, ' ') || -- FILLER
       rpad('1'::varchar, 1, ' ') -- DASO-H-REC-ID
     union all
     select t.roe from tmp_gtc_fidelity_retail_roe t
     union all
     select
       lpad(l_row_cnt::varchar, 6, '0') || -- DASO-REC-COUNT
       rpad(' '::varchar, 155, ' ') ||  -- FILLER in spaces
       rpad('9'::varchar, 1, ' ')      -- DASO-T-REC-ID
     ;
  else
     -- Report Name: Fidelity Multi-leg Open Order Report
   RETURN QUERY
     select
       rpad('DASM'::varchar, 4, ' ') || -- DASM-FILE-ID
       rpad(to_char(to_date(l_current_date_id::varchar,'YYYYMMDD'), 'YYMMDD'), 6, ' ') || -- DASM-FILE-DATE  l_current_date_id - Current business date
       rpad(' '::varchar, 125, ' ') || -- FILLER
       rpad('1'::varchar, 1, ' ') -- DASM-H-REC-ID
     union all
     select t.roe from tmp_gtc_fidelity_retail_roe t
     union all
     select
       lpad(l_row_cnt::varchar, 6, '0') || -- DASM-REC-COUNT
       rpad(' '::varchar, 129, ' ') ||  -- FILLER in spaces
       rpad('9'::varchar, 1, ' ')      -- DASO-T-REC-ID
     ;
  end if;

    --GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
    --RAISE INFO 'Exported: % rows', l_row_cnt;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_fidelity_retail COMPLETED===', coalesce(l_row_cnt,0), 'E')
   into l_step_id;

END;
$function$
;
select * from trash.so_report_gtc_fidelity_retail('Y');
select * from trash.so_report_gtc_fidelity_retail('N');


select *
from dash360.report_gtc_fidelity_retail(p_is_multileg_report := 'Y', p_trading_firm_ids := '{"OFP0022"}',
                                         p_instrument_type_id := 'O', p_account_ids := '{29609}');


alter function trash.so_report_gtc_fidelity_retail set schema dash360;
drop function if exists dash360.report_gtc_fidelity_retail;
alter function dash360.so_report_gtc_fidelity_retail rename to report_gtc_fidelity_retail;

select trading_firm_id, * from dwh.d_account
where account_id = 29609