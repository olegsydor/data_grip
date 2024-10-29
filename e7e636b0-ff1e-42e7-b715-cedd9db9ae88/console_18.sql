
select client_order_id, count(*)
	from staging.trade_record_missed_lp
		where date_id = 20241024
group by client_order_id
having count(*) > 1

create temp table t_new as
select *
	from trash.so_missed_lp
		where date_id = 20241024
and client_order_id = '1_0241024';



create temp table t_old as
select *
	from staging.trade_record_missed_lp
		where date_id = 20241024
and client_order_id = '1_0241024';


select client_order_id, count(*)
	from t_new
		where date_id = 20241024
-- and client_order_id = '1_0241024'
group by client_order_id

select *
	from t_old
		where date_id = 20241024
and client_order_id = '1_0241024';

select
--     distinct
    order_id,
       order_id_guid,
       rep_ex_destination,
       trade_record_time,
       db_create_time,
       date_id,
       is_busted,
       subsystem_id,
       account_name,
       client_order_id,
       instrument_id,
       side,
       openclose,
       exec_id,
       exch_exec_id,
       secondary_exch_exec_id,
       last_mkt,
       last_qty,
       last_px,
       ex_destination,
       sub_strategy,
       street_order_qty,
       order_qty,
       multileg_reporting_type,
       exec_broker,
       cmta,
       tif,
       street_time_in_force,
       opt_customer_firm,
       is_cross_order,
       contra_broker,
       client_id,
       order_price,
       order_process_time,
       remarks,
       street_client_order_id,
       fix_comp_id,
       leaves_qty,
       leg_ref_id,
       load_batch_id,
       strategy_decision_reason_code,
       is_parent,
       symbol,
       strike_price,
       type_code,
       put_or_call,
       maturuty_year,
       maturuty_month,
       maturuty_day,
       security_type,
       child_orders,
       handling,
       secondary_order_id2,
       display_instrument_id,
       instrument_type_id,
       activ_symbol,
       mapping_logic,
       commision_rate_unit,
       is_sor_routed,
       is_company_name_changed,
       company_name,
       generation,
       mx_gen,
       parent_order_id,
       mic_code,
       option_range,
       client_entity_id,
       status,
       trade_liquidity_indicator,
       order_create_time,
       blaze_account_alias
, edw_status
, system_order_type_id
from t_new tn
where true
and client_order_id = '1_0241024';

with bth as (select 'new' as src,
                    client_order_id,
                    side,
                    openclose,
                    exch_exec_id,
                    secondary_exch_exec_id,
                    last_mkt,
                    last_qty,
                    last_px,
                    ex_destination,
                    street_order_qty::int,
                    order_qty::int,
                    multileg_reporting_type::text,
                    exec_broker,
                    cmta,
                    street_time_in_force::text,
                    opt_customer_firm,
                    is_cross_order,
                    contra_broker,
                    client_id,
                    order_price,
                    leaves_qty::int,
                    symbol,
                    strike_price,
                    put_or_call,
                    maturuty_year,
                    maturuty_month,
                    maturuty_day,
                    security_type,
                    display_instrument_id,
                    instrument_type_id,
                    activ_symbol,
                    company_name,
                    generation::int,
                    mx_gen::int
             -- , edw_status
-- , system_order_type_id
             from t_new
             where true
               and client_order_id = '1_118241024'
             union all
             select 'old' as src,
                    client_order_id,
                    side,
                    open_close,
                    exch_exec_id,
                    secondary_exch_exec_id,
                    last_mkt,
                    last_qty,
                    last_px,
                    ex_destination,
                    street_order_qty,
                    order_qty,
                    multileg_reporting_type::text,
                    exec_broker,
                    cmta,
                    street_time_in_force,
                    opt_customer_firm,
                    is_cross_order,
                    contra_broker,
                    client_id,
                    order_price,
                    leaves_qty,
                    symbol,
                    strike_price,
                    put_or_call,
                    maturity_year,
                    maturity_month,
                    maturity_day,
                    security_type,
                    display_instrument_id,
                    instrument_type_id,
                    activ_symbol,
                    companyname,
                    generation,
                    mx_gen
             from t_old
             where true
               and client_order_id = '1_118241024')
select * from bth
order by secondary_exch_exec_id, src

---
select aw.edw_status, *
FROM trash.so_away_trade aw
     LEFT JOIN LATERAL ( SELECT lm_1.id,
            lm_1.mic_code,
            lm_1.security_type,
            lm_1.venue_exchange,
            lm_1.business_name,
            lm_1.ex_destination,
            lm_1.last_mkt
           FROM staging.d_blaze_exchange_codes lm_1
          WHERE COALESCE(lm_1.last_mkt, lm_1.ex_destination)::text = aw.ex_destination AND
                CASE
                    WHEN aw.securitytype = '1'::text THEN 'O'::text
                    WHEN aw.securitytype IS NULL THEN 'O'::text
                    WHEN aw.securitytype = '2'::text THEN 'E'::text
                    ELSE aw.securitytype
                END = lm_1.security_type::text
         LIMIT 1) lm ON true
     LEFT JOIN staging.t_users us ON us.user_id = aw.userid::integer
     LEFT JOIN LATERAL ( SELECT den_1.last_mkt
           FROM billing.dash_exchange_names den_1
          WHERE den_1.mic_code::text = COALESCE(lm.ex_destination, aw.ex_destination::character varying)::text AND den_1.real_exchange_id::text = den_1.exchange_id::text AND den_1.mic_code::text <> ''::text AND den_1.is_active
         LIMIT 1) den ON true
     LEFT JOIN LATERAL ( SELECT den1_1.last_mkt,
            den1_1.mic_code
           FROM billing.dash_exchange_names den1_1
          WHERE den1_1.exchange_id::text = COALESCE(lm.ex_destination, aw.ex_destination::character varying)::text AND den1_1.real_exchange_id::text = den1_1.exchange_id::text AND den1_1.mic_code::text <> ''::text AND den1_1.is_active
         LIMIT 1) den1 ON true
     LEFT JOIN staging.d_time_in_force tif ON tif.enum = aw.co_time_in_force
     LEFT JOIN billing.time_in_force ltf ON tif.id = ltf.code AND ltf.systemid = 8
     LEFT JOIN billing.lforwhom lfw ON lfw.shortdesc::text = aw.option_range AND lfw.systemid = 4
     LEFT JOIN billing.tcompany cmp ON us.company_id = cmp.companyid AND us.system_id = cmp.systemid AND cmp.edwactive = 1::bit(1)
     LEFT JOIN staging.d_liquidity_type lt ON aw.rep_liquidity_type = lt.enum::text
   left join staging.d_blaze_order_status bos on aw.status = bos.enum and bos.order_or_report_status = 2
   left join staging.l_order_status los on bos.id = los.statuscode and los.systemid = 8
   left join staging.d_order_class oc on oc.enum = aw.systemordertypeid
   left join staging.l_order_type lot on oc.ID = lot.Code and lot.SystemID = 8
  WHERE true
    AND (aw.status = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
   and aw.cl_ord_id in ('1_118241024')
 and exec_id in ('jelu6ngc0000', 'jelucahg0002', 'jelucaho0002', 'jelu6ngk0004');


select report_exec_id_guid, cl_ord_id
from trash.so_away_trade
where date_id = 20241017
and report_cl_ord_id_guid ilike '00000000-0001-0000-0000-03471313AD79'

select * from trash.so_missed_lp
where date_id = 20241017
  and client_order_id =  '1_1q4241017'
and order_id_guid ilike '00000000-0001-0000-0000-03471313AD79'
---------------------------


-- Normalized report
select coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz                  as trade_record_time, -- check timezone
       to_char(coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz,
               'YYYYMMDD')::int                                                                 as date_id,           -- check timezone
       'to do'                                                                                  as is_busted,
       case when 8 = 8 then 'OMS_EDW' else 'LPEDW' end                                          as subsystem_id,      -- ?? 8 is hardcoded in [dbo].[vNormalizeBLAZE7Orders]
       coalesce(tom.dashaliasid,
                case
                    when coalesce(us.aors_user_name, us.user_login) = 'BBNTRST' then 'NTRSCBOE'
                    else coalesce(us.aors_user_name, us.user_login)
                    end)                                                                        as account_name,
       rep.orderid                                                                              as client_order_id,
       tl.side,
       tl.OpenClose                                                                             as open_close,
       rep.reportid                                                                             as exec_id,
       'no data'                                                                                as exchange_id,
       coalesce(rep.LiquidityIndicator, 'R')                                                    as trade_liquidity_indicator,
       rep.ExchangeMappedOrderID                                                                as secondary_order_id,
       CASE
           WHEN rep.OrderReportSpecialType = 'M' THEN 'Manual Report'
           ELSE rep.ExchangeTransactionID END                                                   as secondary_exch_exec_id,

       case
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in ('XPAR', 'PLAK', 'PARL')
               then 'LQPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in ('FOGS', 'MID')
               then 'XCHI'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in ('C2', 'CBOE2')
               then 'C2OX'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) = 'SMARTR' then 'COWEN'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in ('XPSE') then 'N'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in ('TO') then '1'
           else coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) end as last_mkt,
       coalesce(rep.lastshares::int, 0)                                                         as last_qty,
       round(lastprice::numeric / 10000.0, 8)                                                   as last_px,
       coalesce(lm.Ex_Destination, rep.ExDestination, '')                                       as ex_destination,
       'no data'                                                                                as sub_strategy,
       rep._order_id                                                                            as order_id,
--        	coalesce(nullif(case when nullif(tl.[ExpirationDate],'1900-01-01 00:00:00.000') is not null and nullif(tl.[Strike],0.00) is not null then tl.OptionQuantity
-- 			else tl.StockQuantity end,0),tl.Quantity) as street_order_qty,
       coalesce(case
                    when tl.ExpirationDate is not null and tl.Strike is not null then tl.OptionQuantity
                    else tl.StockQuantity end, tl.Quantity)::int8                               as street_order_qty,
       coalesce(case
                    when tl.ExpirationDate is not null and tl.Strike is not null then tl.OptionQuantity
                    else tl.StockQuantity end, tl.Quantity)::int8                               as order_qty,
       case when ord.LegCount::int4 > 1 then 2 else 1 end                                       as multileg_reporting_type,
       coalesce(ord.GiveUpFirm, rep.ExecutingBroker)                                            as exec_broker,
       ord.CMTAFirm                                                                             as cmta,
       coalesce(ltf.edwid, tif.id)                                                              as tif,
       case
           when coalesce(ltf.edwid, tif.id) = any (array [24, 17, 10, 1, 44]) then 0
           when coalesce(ltf.edwid, tif.id) = any (array [26, 18, 3, 45, 12]) then 1
           when coalesce(ltf.edwid, tif.id) = any (array [31, 8, 15, 46]) then 2
           when coalesce(ltf.edwid, tif.id) = any (array [47, 28, 11, 19, 5]) then 3
           when coalesce(ltf.edwid, tif.id) = any (array [48, 2, 13, 25, 20]) then 4
           when coalesce(ltf.edwid, tif.id) = any (array [36, 37, 38, 49]) then 5
           when coalesce(ltf.edwid, tif.id) = any (array [50, 14, 21, 33]) then 6
           when coalesce(ltf.edwid, tif.id) = any (array [32, 9, 16]) then 7
           end                                                                                  as street_time_in_force,
       case
           when lfw.edwid = any (array [1, 25, 32, 78]) then '0'
           when lfw.edwid = any (array [33, 26, 79]) then '1'
           when lfw.edwid = any (array [52, 103, 20, 97]) then '2'
           when lfw.edwid = any (array [19, 30, 38, 96]) then '3'
           when lfw.edwid = any (array [35, 28, 4, 81]) then '4'
           when lfw.edwid = any (array [5, 29, 36, 82]) then '5'
           when lfw.edwid = any (array [21, 6, 83]) then '7'
           when lfw.edwid = any (array [31, 23, 41, 98]) then '8'
           when lfw.edwid = any (array [9, 40, 50, 86]) then 'J'
           end                                                                                  as opt_customer_firm,
       case when ord.OrigOrderID is not null then 'Y' else 'N' end                              as is_cross_order,
       case when ord.OrigOrderID is not null then 'Y' else 'N' end                              as street_is_cross_order,
       rep.ContraBroker                                                                         as contra_broker,
       coalesce(comp.CompanyCode, us.user_login)                                                as client_id,
       case
           when round(tl.price::bigint / 10000.0, 4) > 99999999.9999 then 99999999.9999
           else round(tl.price::bigint / 10000.0, 4) end                                        as order_price,
    'no data' as order_process_time,
      'no data' as remarks,
      	rep.ExchangeMappedOrderID as street_client_order_id,
       ---- aux columns
       CASE
           WHEN coalesce(los.EDWID, bos.ID, 0) = 151 and rep.OrderReportSpecialType = 'M' then 156
           ELSE coalesce(los.EDWID, bos.ID, 0) END                                              as Status,
       coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz                  as TransactionDateTime,
       rep.legnumber,
       coalesce(lm.Ex_Destination, rep.ExDestination, '')                                       as ExCode,
       '8'                                                                                      as systemid,
       us.id                                                                                    as user_id,
       coalesce(lot.EDWID, oc.ID)                                                               as SystemOrderTypeID,
       comp.id                                                                                  as companyid,
       coalesce(lm.Ex_Destination, rep.ExDestination, '')                                       as ExDestination
        ,
       ord.TimeInForceCode,
       tif.*,
       ltf.*
from staging.treports_edw rep
         join staging.torder_edw ord on ord.orderid = rep.orderid
         join staging.tordermisc1_edw tom on tom.orderid = rep.orderid
         left join staging.tlegs_edw tl on tl.orderid = rep.orderid and tl.legnumber = rep.legnumber
         Left join staging.d_blaze_order_status bos on rep.Status = bos.enum and bos.Order_or_Report_status = 2
         LEft join staging.l_order_status los on bos.ID = los.StatusCode and los.SystemID = 8
         LEft join staging.d_blaze_exchange_codes lm on rep.ExDestination = coalesce(lm.last_mkt, lm.ex_destination) and
                                                        CASE
                                                            WHEN rep.SecurityType = '1' THEN 'O'
                                                            WHEN rep.SecurityType = '2' THEN 'E'
                                                            ELSE rep.SecurityType END = lm.Security_Type
         LEFT JOIN staging.t_users us on rep.UserID::int = us.USer_ID and us.System_ID = 2 and us.EDW_Active = 1 -- USER
         Left join staging.d_Order_Class oc on ord.SystemOrderTypeID = oc.enum
         Left join staging.l_order_type lot on oc.ID = lot.Code and lot.SystemID = 8
         LEFT JOIN billing.tCompany comp on us.Company_ID = comp.CompanyID and us.System_ID = comp.SystemID
    and comp.EDWActive = '1'::bit -- Company
         left join billing.dash_exchange_names den
                   on den.mic_code = regexp_replace(rep.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                      den.real_exchange_id = den.exchange_id and den.mic_code != '' and den.is_active
         left join billing.dash_exchange_names den1
                   on den1.exchange_id = regexp_replace(rep.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                      den1.real_exchange_id = den1.exchange_id and den1.mic_code != '' and den1.is_active = 'TRUE'
         LEFT JOIN staging.d_time_in_force tif ON tif.enum = ord.TimeInForceCode
         LEFT JOIN billing.time_in_force ltf ON tif.id = ltf.code AND ltf.systemid = 8
         LEFT JOIN billing.lforwhom lfw ON lfw.shortdesc::text = ord.ForWhom AND lfw.systemid = 4

where rep.orderid = 'f_0_1o241024'
  and coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz::date = '2024-10-24'::date
  and los.ID is not null;

