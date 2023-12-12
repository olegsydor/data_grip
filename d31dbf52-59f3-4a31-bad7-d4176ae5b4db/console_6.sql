select export_row from dash360.report_gtc_recon_questrade_row()

select export_row from dash360.report_gtc_recon_questrade_2_row (p_trading_firm_ids => ARRAY['OFP0022'])

select * from dash360.report_gtc_fidelity_retail('N', '{param1}')

select * from dash360.report_gtc_fidelity_retail('Y', '{param1}')


select export_row from dash360.report_gtc_recon_questrade (p_instrument_type_id => 'E', p_trading_firm_ids => ARRAY['OFP0013','LPTF258'])

select * from dash360.report_gtc_recon_raymond_james_associates_v2 ( p_trading_firm_ids => array['OFP0038'] )

----------------------
-- input parameters
----------------------
-- dates
-- trading_firm
drop view trash.so_gtc_merge;
create view trash.so_gtc_merge as
select gtc.account_id,
       ac.account_name,
       ac.trading_firm_id,
       tf.trading_firm_name,
       cl.create_time,
       ors.order_status_description,
       di.instrument_type_id,
       cl.side,
       di.symbol,
       di.last_trade_date,
       exch.exchange_id,
       exch.exchange_name,
       exch.is_bdma,
       cl.order_qty,
       exl.ex_qty,
       cl.order_type_id,
       cl.price,
       ex.avg_px,
       ex.leaves_qty,
       cl.multileg_reporting_type,
       leg.client_leg_ref_id,
       cl.open_close,
       cl.dash_client_order_id,
       cl.client_order_id,
--        orig.client_order_id as orig_client_order_id,
       par.client_order_id  as par_client_order_id,
       fmj.t10441           as occ_data,
       oc.opra_symbol,
       cl.client_id,
       dss.sub_system_id,
       oc.strike_price,
       oc.put_call,
       oc.maturity_year,
       oc.maturity_month,
       oc.maturity_day,
       cl.order_id,
       fc.fix_comp_id,
       cl.co_client_leg_ref_id,
       cl.create_date_id,
       ors.order_status,
       fmj.t99              as stop_px
from dwh.gtc_order_status gtc
         join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id and
                                     cl.parent_order_id is not null
         join dwh.d_account ac on gtc.account_id = ac.account_id
         left join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         left join dwh.client_order par
                   on (cl.parent_order_id = par.order_id and par.create_date_id <= gtc.create_date_id)
         join lateral (select ex.exec_id as exec_id
                       from dwh.execution ex
                       where gtc.order_id = ex.order_id
                         and ex.order_status <> '3'
                         and ex.exec_date_id >= gtc.create_date_id
                       order by ex.exec_id desc
                       limit 1) gtex on true
         inner join lateral (select ex.avg_px, ex.last_px, ex.leaves_qty, ex.order_status
                             from dwh.execution ex
                             where ex.exec_id = gtex.exec_id
                               and ex.exec_date_id >= gtc.create_date_id
                             limit 1) ex on true
         join dwh.d_order_status ors on ors.order_status = ex.order_status
         inner join lateral (select exch.exchange_id,
                                    exch.exchange_name,
                                    case when exch.exchange_id like '%ML' then 'Y' else 'N' end as is_bdma
                             from dwh.d_exchange exch
                             where exch.exchange_id = cl.exchange_id
                               and exch.is_active
                             limit 1) exch on true
--          left join dwh.client_order orig
--                    on (orig.order_id = cl.orig_order_id and orig.create_date_id <= cl.create_date_id)
         left join lateral (select sum(ex.last_qty) as ex_qty
                            from dwh.execution ex
                            where ex.exec_date_id >= gtc.create_date_id
                              and ex.order_id = cl.order_id
                              and ex.exec_type in ('F', 'G')
                              and ex.is_busted = 'N'
                            limit 1) exl on true
         left join dwh.client_order_leg leg on (leg.order_id = gtc.order_id)
         left join lateral (select fix_message ->> '10441' as t10441,
                                   fix_message ->> '99'    as t99
                            from fix_capture.fix_message_json fmj
                            where fmj.fix_message_id = cl.fix_message_id
                              and fmj.date_id = cl.create_date_id
                            limit 1) fmj on true
         left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id and oc.is_active)
         left join dwh.d_sub_system dss on dss.sub_system_unq_id = par.sub_system_unq_id and dss.is_active
         left join dwh.d_fix_connection fc on (cl.fix_connection_id = fc.fix_connection_id)
where true
--           and cl.parent_order_id is not null
  and gtc.close_date_id is null
  and cl.trans_type in ('D', 'G')
  and cl.time_in_force_id in ('1', '6')
  and cl.multileg_reporting_type in ('1', '2')
--           and case when coalesce(l_account_ids, '{}') = '{}' then true else gtc.account_id = any (l_account_ids) end
;


select
    account_id,

    to_char(create_time, 'DD/MM/YYYY HH:MI:SS AM') as create_date
     , client_order_id                                as cl_ord_id
--        , fmj.leg_rfr_id
     , co_client_leg_ref_id                           as leg_rfr_id
     , case
           when co.side in ('1', '3') then 'BUY'
           when co.side = '5' then 'SELLSHORT'
           else 'SELL'
    end                                               as buy_sell
     , case
           when symbol like 'BRK%' and instrument_type_id = 'E' then 'BRK.B'
           else symbol end                            as symbol
     , (order_qty - coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => order_id, in_date_id => create_date_id),
                             0))::varchar             as open_quantity
--        , coalesce(co.price, co.stop_price)::varchar as price
     , price                                          as price
--        , coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), to_char(co.expire_time, 'YYYYMMDD')) as expiration_date
     , to_char(last_trade_date, 'YYYYMMDD')           as expiration_date -- looking at the data, I can see that equity leg has an expiration date value. I can imagine that is the Option Expiry? If so, could you also as an enhancement remove it for the equity legs of MLEG”
     , case
           when put_call = '0' then 'P'
           when put_call = '1' then 'C'
    end                                               as type_code
     , strike_price::varchar                          as strike
     , order_status
     , stop_px
     , order_qty
     , case
           when co_client_leg_ref_id is not null then 'MLEG'
           when instrument_type_id = 'O' then 'OPT'
           when instrument_type_id = 'E' then 'EQ'
           else instrument_type_id end                as product_type
from trash.so_gtc_merge co
where true
  and par_client_order_id is not null -- parent level
        and account_id = any(array (select ac.account_id from dwh.d_account ac where ac.trading_firm_id = 'LPTF258'))

        and case when coalesce(p_account_ids, '{}') = '{}' then true else gos.account_id = any(p_account_ids) end
--        and i.instrument_type_id = l_instrument_type --need Options orders
        and case when l_instrument_type is null then true else i.instrument_type_id = l_instrument_type end--need Options orders
--        and co.trans_type <> 'F' -- don't need cancell requests. hardcode. --(здесь был канселл реквест)
        and gos.close_date_id is null
        and co.multileg_reporting_type <> '3'
        and case when co.time_in_force_id = '6' then co.expire_time::date > co.create_time::date else true end

select *
from trash.so_gtc_merge
where true
  and trading_firm_id = 'OFP0022'
  and instrument_type_id = 'E';

drop FUNCTION dash360.report_gtd_open_order_recon;

CREATE OR REPLACE FUNCTION dash360.report_gtd_open_order_recon(
    in_date_id int4 DEFAULT to_char(current_date, 'YYYYMMDD')::int4,
    in_account_ids int4[] DEFAULT NULL::int4[]
)
    RETURNS TABLE
            (
                rec text
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_load_id       int;
    l_step_id       int;
    l_point_date_id int4 := to_char(current_date, 'YYYYMMDD')::int4;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_gtd_open_order_recon for accounts ' || in_account_ids::text || ' STARTED ====',
                           in_date_id,
                           'O')
    into l_step_id;

    return query
        select "Order Number"::text || '|' ||
               coalesce("Order Leg ID", '') || '|' ||
               coalesce("Order Entry Date", '') || '|' ||
               coalesce("Action", '') || '|' ||
               coalesce("Type", '') || '|' ||
               coalesce(order_qty::text, '') || '|' ||
               coalesce(leaves_qty::text, '') || '|' ||
               coalesce(instrument_type_id::text, '') || '|' ||
               coalesce("Symbol", '') || '|' ||
               coalesce("Root Symbol", '') || '|' ||
               coalesce("Put or Call", '') || '|' ||
               coalesce("O/C", '') || '|' ||
               coalesce(last_trade_date, '') || '|' ||
               coalesce(strike_price, '') || '|' ||
               coalesce(price, '') || '|' ||
               coalesce(stop_price, '') || '|' ||
               coalesce(gtc, '') || '|' ||
               coalesce(expire_date, '') || '|' ||
               coalesce(notheld, '')
        from (select cl.order_id                                                   as "Order Number",
                     case cl.multileg_reporting_type
                         when '1' then '0'
                         when '2'
                             then cl.no_legs::text end                             as "Order Leg ID",
                     to_char(cl.create_time, 'MMDDYYYY')                           as "Order Entry Date",
                     case cl.side
                         when '1' then 'B'
                         when '2' then 'S'
                         when '5' then 'SS'
                         when '6'
                             then 'SS' end                                         as "Action",
                     case cl.order_type_id
                         when '1' then 'M'
                         when '2' then 'L'
                         when '3' then 'S'
                         when '4' then 'SL'
                         else 'L' end                                              as "Type",
                     cl.order_qty                                                  as order_qty,
                     ex.leaves_qty                                                 as leaves_qty,
                     di.instrument_type_id                                         as instrument_type_id,
                     case when di.instrument_type_id = 'E' then di.symbol end      as "Symbol",
                     case when di.instrument_type_id = 'O' then os.root_symbol end as "Root Symbol",
                     case oc.put_call when '0' then 'P' when '1' then 'C' end      as "Put or Call",
                     cl.open_close                                                 as "O/C",
                     case
                         when di.instrument_type_id = 'O'
                             then to_char(di.last_trade_date, 'MMDDYY') end        as last_trade_date,
                     to_char(oc.strike_price, 'FM99990D0099')                      as strike_price,
                     to_char(cl.price, 'FM99990D0099')                             as price,
                     to_char(cl.stop_price, 'FM99990D0099')                        as stop_price,
                     case cl.time_in_force_id
                         when '1' then 'GTC'
                         when '6' then 'GTD'
                         else cl.time_in_force_id end                              as gtc,
                     coalesce(to_char(cl.expire_time, 'MMDDYYYY'),
                              to_char(to_date(fmj.t432, 'YYYYMMDD'), 'YYYYMMDD'))  as expire_date,
                     case
                         when cl.exec_instruction like '%G%' then 'AON'
                         when cl.exec_instruction like '%1%' then 'NH'
                         end                                                       as notheld
              from dwh.gtc_order_status gtc
                       join dwh.client_order cl
                            on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
                       join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                       join lateral (select ex.exec_id as exec_id,
                                            ex.avg_px,
                                            ex.leaves_qty,
                                            ex.order_status
                                     from dwh.execution ex
                                     where gtc.order_id = ex.order_id
                                       and ex.order_status <> '3'
                                       and ex.exec_date_id >= gtc.create_date_id
                                     order by ex.exec_time desc
                                     limit 1) ex on true
                       left join lateral (select fix_message ->> '432' as t432
                                          from fix_capture.fix_message_json fmj
                                          where true
                                            and fmj.fix_message_id = cl.fix_message_id
                                            and fmj.date_id = cl.create_date_id
                                            and fix_message ->> '432' is not null
                                          limit 1) fmj on true
                       left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
                       left join d_option_series os on (oc.option_series_id = os.option_series_id)
              where true
                and cl.parent_order_id is null
                and case
                        when in_date_id < l_point_date_id then coalesce(close_date_id, in_date_id + 1) > in_date_id
                        else gtc.close_date_id is null end
                and cl.trans_type in ('D', 'G')
                and cl.time_in_force_id in ('1', '6')
                and cl.multileg_reporting_type in ('1', '2')
                and gtc.account_id = any (in_account_ids)) x;

    select public.load_log(l_load_id, l_step_id,
                           'get_ameritrade_gtd for accounts FINISHED ====', in_date_id,
                           'O')
    into l_step_id;
end;
$function$
;
select * from dash360.report_beta_open_order_recon('{14765, 17287}')

select to_char(current_date, 'YYYYMMDD')::int4;

CREATE OR REPLACE FUNCTION dash360.report_beta_open_order_recon(in_account_id int4[])
 RETURNS TABLE(rec text)
 LANGUAGE plpgsql
AS $function$
declare
    l_load_id int;
    l_step_id int;

begin
     select nextval('public.load_timing_seq') into l_load_id;
     l_step_id := 1;

     select public.load_log(l_load_id, l_step_id,
                            'report_beta_open_order_recon for ' || in_account_id::text || 'STARTED ====', 0, 'O')
     into l_step_id;

     return query
        SELECT "EXCH-FIRM-NO" ||
               "EXCH-SUB-NO" ||
               "EXCH-FIRM-MNEMONIC" ||
               "EXCH-BRANCH" ||
               "EXCH-BRSEQ" ||
               "EXCH-FIX-11" ||
               "EXCH-ORDR-DATE-MDCY" ||
               "EXCH-BORS" ||
               "EXCH-ORIG-QTY" ||
               "EXCH-SEC-IDENTIFIER" ||
               "EXCH-SECURITY" ||
               "EXCH-LIMIT-PRICE" ||
               "EXCH-STOP-PRICE" ||
               "EXCH-LEAVES-QTY" ||
               "EXCH-INVESTOR-CODE" ||
               "EXCH-SPREAD-IND" ||
               "EXCH-SPREAD-PRICE" ||
               "EXCH-SPREAD-PX-ID" ||
               "EXCH-MULTI-LEG" ||
               "EXCH-STOP-ORDR" ||
               "EXCH-MARKET-ORDR" ||
               "EXCH-TIME-IN-FORCE" ||
               "EXCH-POS-DUP" ||
               "EXCH-ALL-OR-NONE" ||
               "EXCH-DNR" ||
               "EXCH-OR-BETTER" ||
               "EXCH-NOT-HELD" ||
               "EXCH-CASH-TRADE" ||
               "EXCH-NEXT-DAY" ||
               "EXCH-STOP-LIMIT-WOW" ||
               "EXCH-STOP-LIMIT-IND" ||
               "EXCH-CALL-PUT-IND" ||
               "EXCH-ROOT-SYMB" ||
               "EXCH-EXP-MON" ||
               "EXCH-EXP-DAY" ||
               "EXCH-EXP-YEAR" ||
               "EXCH-STRIKE-PX" ||
               "FILLER"
        FROM (SELECT '   '                                                                           AS "EXCH-FIRM-NO",
                     '   '                                                                           AS "EXCH-SUB-NO",
                     RPAD(ac.broker_dealer_mpid, 5)                                                  AS "EXCH-FIRM-MNEMONIC",
                     '    '                                                                          AS "EXCH-BRANCH",
                     '     '                                                                         AS "EXCH-BRSEQ",
                     RPAD(CL.CLIENT_ORDER_ID, 30)                                                    AS "EXCH-FIX-11",
                     TO_CHAR(CL.CREATE_TIME, 'MMDDYYYY')                                             AS "EXCH-ORDR-DATE-MDCY",
                     CASE WHEN CL.SIDE = '1' THEN 'B ' WHEN CL.SIDE in ('2', '5', '6') THEN 'S ' END AS "EXCH-BORS",
                     LPAD(round(CL.ORDER_QTY * 100000, 0)::text, 18, '0')                            AS "EXCH-ORIG-QTY",
                     'O'                                                                             AS "EXCH-SEC-IDENTIFIER",
                     RPAD(' ', 20)                                                                   AS "EXCH-SECURITY",
                     LPAD((COALESCE(CL.PRICE * 1000000000, 0)::int8)::text, 18, '0')                 AS "EXCH-LIMIT-PRICE",

                     LPAD((COALESCE(CL.STOP_PRICE * 1000000000, 0)::int8)::text, 18,
                          '0')                                                                       AS "EXCH-STOP-PRICE",
                     LPAD((COALESCE(EX.LEAVES_QTY * 100000, 0)::int8)::text, 18, '0')                AS "EXCH-LEAVES-QTY",

                     ' '                                                                             AS "EXCH-INVESTOR-CODE",
                     CASE WHEN CL.MULTILEG_REPORTING_TYPE <> '1' THEN 'SPD' ELSE '   ' END           AS "EXCH-SPREAD-IND",
                     '0000000'                                                                       AS "EXCH-SPREAD-PRICE",
                     '   '                                                                           AS "EXCH-SPREAD-PX-ID",
                     ' '                                                                             AS "EXCH-MULTI-LEG",
                     '   '                                                                           AS "EXCH-STOP-ORDR",
                     '   '                                                                           AS "EXCH-MARKET-ORDR",
                     RPAD(UPPER(TIF.TIF_SHORT_NAME), 3)                                              AS "EXCH-TIME-IN-FORCE",
                     ' '                                                                             AS "EXCH-POS-DUP",
                     ' '                                                                             AS "EXCH-ALL-OR-NONE",
                     ' '                                                                             AS "EXCH-DNR",
                     ' '                                                                             AS "EXCH-OR-BETTER",
                     ' '                                                                             AS "EXCH-NOT-HELD",
                     ' '                                                                             AS "EXCH-CASH-TRADE",
                     ' '                                                                             AS "EXCH-NEXT-DAY",
                     ' '                                                                             AS "EXCH-STOP-LIMIT-WOW",
                     'L'                                                                             AS "EXCH-STOP-LIMIT-IND",
                     CASE
                         WHEN OC.PUT_CALL = '0' THEN 'P'
                         WHEN OC.PUT_CALL = '1' THEN 'C'
                         ELSE ' ' END                                                                AS "EXCH-CALL-PUT-IND",
                     RPAD(OS.ROOT_SYMBOL, 6)                                                         AS "EXCH-ROOT-SYMB",
                     RPAD(OC.MATURITY_MONTH::text, 2, '0')                                           AS "EXCH-EXP-MON",
                     RPAD(OC.MATURITY_DAY::text, 2, '0')                                             AS "EXCH-EXP-DAY",
                     RIGHT('0000' || OC.MATURITY_YEAR::text, 2)                                      AS "EXCH-EXP-YEAR",
                     LPAD(round(OC.STRIKE_PRICE * 1000000000, 0)::text, 18, '0')                     AS "EXCH-STRIKE-PX",
                     RPAD(' ', 232)                                                                  AS "FILLER"
              FROM dwh.gtc_order_status gtc
                       join dwh.CLIENT_ORDER CL using (create_date_id, order_id)
                       INNER JOIN dwh.d_INSTRUMENT I ON I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                       INNER JOIN dwh.d_ACCOUNT AC ON (CL.ACCOUNT_ID = AC.ACCOUNT_ID)
                       LEFT JOIN dwh.d_OPTION_CONTRACT OC on (OC.INSTRUMENT_ID = CL.INSTRUMENT_ID)
                       LEFT JOIN dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
                       join lateral (select ex.exec_id as exec_id,
                                            ex.avg_px,
                                            ex.leaves_qty,
                                            ex.order_status
                                     from dwh.execution ex
                                     where gtc.order_id = ex.order_id
                                       and ex.order_status <> '3'
                                       and ex.exec_date_id >= gtc.create_date_id
                                     order by ex.exec_time desc
                                     limit 1) ex on true
                       INNER JOIN dwh.d_ORDER_STATUS ORS ON ORS.ORDER_STATUS = EX.ORDER_STATUS
                       LEFT JOIN dwh.d_EX_DESTINATION_CODE EDC
                                 on (CL.ex_destination = EDC.ex_destination_CODE and EDC.is_acitive)

                       LEFT JOIN dwh.d_TIME_IN_FORCE TIF ON (TIF.TIF_ID = CL.TIME_IN_FORCE_id)
              WHERE true
                and gtc.close_date_id is null
                and gtc.account_id = any(in_account_id)
                AND CL.PARENT_ORDER_ID IS NULL
                AND CL.TRANS_TYPE IN ('D', 'G')
                AND CL.TIME_IN_FORCE_ID in ('1', '6')
                AND CL.MULTILEG_REPORTING_TYPE in ('1', '2')
              ORDER BY CL.CREATE_TIME::date) x;

     select public.load_log(l_load_id, l_step_id,
                            'report_beta_open_order_recon for ' || in_account_id::text || 'FINISHED ====', 0, 'O')
     into l_step_id;
end;
$function$
;



CREATE OR REPLACE FUNCTION trash.report_gtc_recon_questrade_ad_hoc(p_instrument_type_id character varying DEFAULT 'E'::character varying,
                                                                   p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                export_row text
            )
    LANGUAGE plpgsql
AS
$function$
-- SY: 20220207 and co.account_id in has been refactord as and co.account_id = any
-- SO: 20230824 https://dashfinancial.atlassian.net/browse/DS-7146 changing logic
declare

    l_row_cnt          integer;
    l_current_date_id  integer;
    l_trading_firm_ids character varying[];
    l_instrument_type  varchar;
    l_load_id          integer;
    l_step_id          integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_recon_questrade_ad_hoc STARTED===', 0, 'O')
    into l_step_id;

    l_trading_firm_ids := case when p_trading_firm_ids = '{}' then ARRAY ['LPTF258'] else p_trading_firm_ids end;

    l_instrument_type := p_instrument_type_id;

    select public.load_log(l_load_id, l_step_id, left(' trading_firm_ids = ' || l_trading_firm_ids::varchar, 200), 0,
                           'O')
    into l_step_id;

    RETURN QUERY
        select 'CreateDate,ClOrdID,BuySell,Symbol,OpenQuantity,Price,ExpirationDate,TypeCode,Strike';
    return query
    select coalesce(s.create_date::varchar, '')::varchar || ',' || -- CreateDate
           coalesce(s.cl_ord_id::varchar, '')::varchar || ',' || -- ClOrdID
           coalesce(s.buy_sell::varchar, '')::varchar || ',' || -- BuySell
           coalesce(s.symbol::varchar, '')::varchar || ',' || -- Symbol
           coalesce(s.open_quantity::varchar, '')::varchar || ',' || -- OpenQuantity
           coalesce(s.price::varchar, '')::varchar || ',' || -- Price
           coalesce(s.expiration_date::varchar, '')::varchar || ',' || -- ExpirationDate
           coalesce(s.type_code::varchar, '')::varchar || ',' || -- TypeCode
           coalesce(s.strike::varchar, '')::varchar -- Strike
               as roe
    from (select to_char(co.create_time, 'DD/MM/YYYY HH:MI:SS AM') as create_date
               , co.client_order_id                                as cl_ord_id
               , case
                     when co.side in ('1', '3')
                         then 'BUY'
                     else 'SELL'
            end                                                    as buy_sell
               , i.symbol                                          as symbol
               , (co.order_qty - coalesce(
                dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id),
                0))::varchar                                       as open_quantity
               , coalesce(co.price, co.stop_price)::varchar        as price
               , to_char(i.last_trade_date, 'YYYYMMDD')            as expiration_date
               , case
                     when oc.put_call = '0' then 'P'
                     when oc.put_call = '1' then 'C'
            end                                                    as type_code
               , oc.strike_price::varchar                          as strike
          from dwh.client_order co
                   join dwh.v_client_order_today co2 using (order_id, create_date_id)
                   left join lateral
              (
              select ex.order_id
                   , max(ex.exec_type)    as max_exec_type
                   , max(ex.order_status) as max_order_status
                   --, sum(case when ex.exec_type in ('F','1','2') then ex.last_qty else 0 end) as cum_qty
                   , max(ex.exec_time)    as max_exec_time
              from dwh.execution ex
              where ex.order_id = co.order_id
                and ex.exec_date_id >= co.create_date_id
                and (
                          ex.exec_type in ('4', '8') -- fill, canc, rej, replaced
                      or
                          ex.order_status in ('2', '4', '5', '8') -- fill, canc, rej, replaced
                  )
              group by ex.order_id
              limit 1
              ) ex on true

                   join dwh.d_instrument i on co.instrument_id = i.instrument_id
                   left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
          where true
            and co.parent_order_id is null                                                                     -- parent level
            and co.account_id = any
                (array(select ac.account_id from dwh.d_account ac where ac.trading_firm_id = any (l_trading_firm_ids)))
            and co.time_in_force_id in ('1', '6')                                                              -- GTC hardcode - no GTC found for LPTF258, but are found for OFP0013
            and case when l_instrument_type is null then true else i.instrument_type_id = l_instrument_type end--need Options orders
            and co.trans_type <> 'F') s
    where true;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'Rowcount is ', l_row_cnt, 'O')
    into l_step_id;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_gtc_recon_questrade_ad_hoc COMPLETED===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

END;
$function$
;


select case when :in_num ~ '^[0-9]+$' then :in_num else null end;



CREATE OR REPLACE FUNCTION trash.report_gtc_recon_raymond_james_associates_v2_ad_hoc(p_instrument_type_id character varying DEFAULT 'E'::character varying,
                                                                                     p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                export_row text
            )
    LANGUAGE plpgsql
AS
$function$
    -- 20230824 SO: https://dashfinancial.atlassian.net/browse/DS-7147
DECLARE
    l_row_cnt          integer;
    l_current_date_id  integer;
    l_gtc_date_id      integer;
    l_trading_firm_ids character varying[];
    l_instrument_type  varchar;
    l_load_id          integer;
    l_step_id          integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_recon_raymond_james_associates_v2_ad_hoc STARTED===', 0, 'O')
    into l_step_id;

    l_trading_firm_ids := case when p_trading_firm_ids = '{}' then ARRAY ['raymjay01'] else p_trading_firm_ids end;

    l_instrument_type := p_instrument_type_id;

    select public.load_log(l_load_id, l_step_id, left(' trading_firm_ids = ' || l_trading_firm_ids::varchar, 200), 0,
                           'O')
    into l_step_id;
    select public.load_log(l_load_id, l_step_id,
                           ' Period: l_current_date_id = ' || l_current_date_id::varchar || ', l_gtc_date_id = ' ||
                           l_gtc_date_id::varchar || ', l_instrument_type = ' || l_instrument_type::varchar, 0, 'O')
    into l_step_id;

    create temp table if not exists tmp_gtc_recon_raymond_james_roe
    (
        roe text
    )
        on commit DROP;
    truncate table tmp_gtc_recon_raymond_james_roe;

    RETURN QUERY
        select 'CreateDate,ClOrdID,BuySell,Symbol,OpenQuantity,Price,ExpirationDate,TypeCode,Strike';
    return query
        select coalesce(s.cl_ord_id::varchar, '')::varchar || ',' || -- OrderID
               coalesce(s.side::varchar, '')::varchar || ',' || -- Side
               coalesce(s.put_or_call::varchar, '')::varchar || ',' || -- PutOrCall
               coalesce(s.open_close::varchar, '')::varchar || ',' || -- OpenClose
               coalesce(s.qty::varchar, '')::varchar || ',' || -- Qty
               coalesce(s.symbol::varchar, '')::varchar || ',' || -- Symbol
               coalesce(s.suffix::varchar, '')::varchar || ',' || -- Suffix
               coalesce(s.expiration_date::varchar, '')::varchar || ',' || -- ExpirationDate
               coalesce(s.strike_price::varchar, '')::varchar || ',' || -- StrikePrice
               coalesce(s.limit_price::varchar, '')::varchar || ',' || -- LimitPrice
               coalesce(s.stop_price::varchar, '')::varchar || ',' || -- StopPrice
               coalesce(s.exec_inst::varchar, '')::varchar -- ExecInst
                   as roe
        from (select --to_char(co.create_time, 'DD/MM/YYYY HH:MI:SS AM') as create_date
                  co.client_order_id                                               as cl_ord_id
                   , co.side                                                       as side
                   , oc.put_call                                                   as put_or_call
                   , co.open_close                                                 as open_close
                   , co.order_qty                                                  as qty
                   , i.symbol                                                      as symbol
                   , i.symbol_suffix                                               as suffix
                   , coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), '')::varchar as expiration_date
                   , oc.strike_price                                               as strike_price
                   , co.price                                                      as limit_price
                   , co.stop_price                                                 as stop_price
                   , co.exec_instruction                                           as exec_inst
              from dwh.client_order co
                       join dwh.v_client_order_today co2 using (order_id, create_date_id)
                       left join lateral
                  (
                  select ex.order_id
                       , max(ex.exec_type)    as max_exec_type
                       , max(ex.order_status) as max_order_status
                       --, sum(case when ex.exec_type in ('F','1','2') then ex.last_qty else 0 end) as cum_qty
                       , max(ex.exec_time)    as max_exec_time
                  from dwh.execution ex
                  where ex.exec_date_id >= co.create_date_id
                    and ex.order_id = co.order_id
                    --and ex.exec_type in ('F','1','2','4','8') -- fill, canc, rej
                    and (
                              ex.exec_type in ('4', '8') -- fill, canc, rej, replaced
                          or
                              ex.order_status in ('2', '4', '5', '8') -- fill, canc, rej, replaced
                      )
                  group by ex.order_id
                  limit 1
                  ) ex on true
                       join dwh.d_instrument i
                            on co.instrument_id = i.instrument_id
                       left join dwh.d_option_contract oc
                                 on i.instrument_id = oc.instrument_id
              where true
                and co.parent_order_id is null                                             -- parent level
                and co.account_id in (select ac.account_id
                                      from dwh.d_account ac
                                      where ac.trading_firm_id = any (l_trading_firm_ids)) -- in ('raymjay01') --
                and co.time_in_force_id = '1'                                              -- GTC hardcode - no GTC found for LPTF258, but are found for OFP0013
                and i.instrument_type_id = p_instrument_type_id
                and co.multileg_reporting_type in ('1', '2')
                and co.trans_type <> 'F' -- don't need cancell requests. hardcode. --(здесь был канселл реквест)
                 -- retail?
                 --and co.sub_strategy_id in (select dts.target_strategy_id from dwh.d_target_strategy dts where dts.target_strategy_name = 'RETAIL') -- only 9000 tag = RETAIL
             ) s
        where true;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'dash360.report_gtc_recon_raymond_james_associates_v2_ad_hoc COMPLETED===',
                           coalesce(l_row_cnt, 0), 'O')
    into l_step_id;

END;
$function$
;


select * from trash.report_gtc_recon_raymond_james_associates_v2_ad_hoc(p_instrument_type_id := 'O', p_trading_firm_ids := '{"bnplon","dashnewed","OFP0001","socgen01"}')