-- Normalized report based on the new view
-- with base as (
create table staging.away_trade as
select coalesce(aw.manualexecutiontime, aw.transactiondatetime)::timestamptz as          trade_record_time, -- check timezone
       to_char(coalesce(aw.manualexecutiontime, aw.transactiondatetime)::timestamptz,
               'YYYYMMDD')::int                                              as          date_id,           -- check timezone
       'to do'                                                               as          is_busted,
       case when 8 = 8 then 'OMS_EDW' else 'LPEDW' end                       as          subsystem_id,      -- ?? 8 is hardcoded in [dbo].[vNormalizeBLAZE7Orders]
       coalesce(aw.dashaliasid,
                case
                    when coalesce(us.aors_user_name, us.user_login) = 'BBNTRST' then 'NTRSCBOE'
                    else coalesce(us.aors_user_name, us.user_login)
                    end)                                                     as          account_name,
       aw.side,
       aw.OpenClose                                                          as          open_close,
       'no data'                                                             as          exchange_id,
       coalesce(aw.LiquidityIndicator, 'R')                                  as          trade_liquidity_indicator,
       aw.ExchangeMappedOrderID                                              as          secondary_order_id,
       CASE
           WHEN aw.OrderReportSpecialType = 'M' THEN 'Manual Report'
           ELSE aw.ExchangeTransactionID END                                 as          secondary_exch_exec_id,

       case
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                ('XPAR', 'PLAK', 'PARL')
               then 'LQPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                ('FOGS', 'MID')
               then 'XCHI'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                ('C2', 'CBOE2')
               then 'C2OX'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) = 'SMARTR'
               then 'COWEN'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in ('XPSE')
               then 'N'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in ('TO')
               then '1'
           else coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination,
                         aw.ExDestination) end                               as          last_mkt,
       coalesce(aw.lastshares::int, 0)                                       as          last_qty,
       round(aw.lastprice::numeric / 10000.0, 8)                             as          last_px,
       coalesce(lm.Ex_Destination, aw.ExDestination, '')                     as          ex_destination,
       'no data'                                                             as          sub_strategy,
--        	coalesce(nullif(case when nullif(aw.[ExpirationDate],'1900-01-01 00:00:00.000') is not null and nullif(aw.[Strike],0.00) is not null then aw.OptionQuantity
-- 			else aw.StockQuantity end,0),aw.Quantity) as street_order_qty,
       coalesce(case
                    when aw.ExpirationDate is not null and aw.Strike is not null then aw.OptionQuantity
                    else aw.StockQuantity end,
                aw.Quantity)::int8                                           as          street_order_qty,
       coalesce(case
                    when aw.ExpirationDate is not null and aw.Strike is not null then aw.OptionQuantity
                    else aw.StockQuantity end,
                aw.Quantity)::int8                                           as          order_qty,
       case when aw.LegCount::int4 > 1 then 2 else 1 end                     as          multileg_reporting_type,
       coalesce(aw.GiveUpFirm, aw.ExecutingBroker)                           as          exec_broker,
       aw.CMTAFirm                                                           as          cmta,
       coalesce(ltf.edwid, tif.id)                                           as          tif,
       case
           when coalesce(ltf.edwid, tif.id) = any (array [24, 17, 10, 1, 44]) then 0
           when coalesce(ltf.edwid, tif.id) = any (array [26, 18, 3, 45, 12]) then 1
           when coalesce(ltf.edwid, tif.id) = any (array [31, 8, 15, 46]) then 2
           when coalesce(ltf.edwid, tif.id) = any (array [47, 28, 11, 19, 5]) then 3
           when coalesce(ltf.edwid, tif.id) = any (array [48, 2, 13, 25, 20]) then 4
           when coalesce(ltf.edwid, tif.id) = any (array [36, 37, 38, 49]) then 5
           when coalesce(ltf.edwid, tif.id) = any (array [50, 14, 21, 33]) then 6
           when coalesce(ltf.edwid, tif.id) = any (array [32, 9, 16]) then 7
           end                                                               as          street_time_in_force,
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
           end                                                               as          opt_customer_firm,
       case when aw.OrigOrderID is not null then 'Y' else 'N' end            as          is_cross_order,
       case when aw.OrigOrderID is not null then 'Y' else 'N' end            as          street_is_cross_order,
       aw.ContraBroker                                                       as          contra_broker,
       coalesce(comp.CompanyCode, us.user_login)                             as          client_id,
       case
           when round(aw.price::bigint / 10000.0, 4) > 99999999.9999 then 99999999.9999
           else round(aw.price::bigint / 10000.0, 4) end                     as          order_price,
       'no data'                                                             as          order_process_time,
       'no data'                                                             as          remarks,
       aw.ExchangeMappedOrderID                                              as          street_client_order_id,
       'LPEDWCOMPID'                                                         as          fix_comp_id,
       aw.leavesqty::bigint                                                  as          leaves_qty,
       aw.Legnumber                                                          as          leg_ref_id,
       null                                                                  as          load_batch_id,
       CASE
           WHEN aw.ORIGOrderID is not null or aw.ContraOrderID is not null then 26
           WHEN aw.ParentOrderID is not null or
                (aw.ParentOrderID is null and nullif(aw.ChildOrders::int, 0) is not null) then 10
           WHEN aw.COMMENT like '%OVR%' then 4
           ELSE 50 end                                                       as          strategy_decision_reason_code,
       case when aw.ParentID is null then 'Y' else 'N' end                   as          is_parent,
       aw.basecode                                                           as          symbol,
       round(aw.strike::numeric, 6)                                          as          strike_price,
       case aw.TypeCode
           when 'P' then '0'
           when 'C' then '1'
           end                                                               as          put_or_call,
       extract(year from aw.expirationdate)                                  as          maturity_year,
       extract(month from aw.expirationdate)                                 as          maturity_month,
       extract(day from aw.expirationdate)                                   as          maturity_day,
       CASE
           WHEN aw.SecurityType = 'O' THEN 1
           WHEN aw.SecurityType = 'E' THEN 2
           ELSE aw.SecurityType::int END                                     as          security_type,
       aw.ChildOrders                                                        as          child_orders,
       coalesce(case when aw.OrderReportSpecialType = 'M' then lt.ID ELSE aw.Handling::int END,
                0)                                                           as          handling_id,
       0                                                                     as          secondary_order_id2,
       case
           when aw.expirationdate is not null and aw.strike IS NOT NULL
               THEN replace(
                   COALESCE(((((regexp_replace(COALESCE(aw.basecode, ''::text), '\.|-'::text, ''::text,
                                               'g'::text) ||
                                ' '::text) ||
                               to_char(aw.expirationdate::timestamp with time zone, 'DDMonYY'::text)) ||
                              ' '::text) || staging.trailing_dot(aw.strike)) || "left"(aw.typecode, 8),
                            CASE
                                WHEN aw.contractdesc !~~ (aw.basecode || ' %'::text) THEN
                                    (aw.basecode || ' '::text) ||
                                    replace(aw.contractdesc, aw.basecode, ''::text)
                                WHEN aw.legcount::integer = 1 AND aw.typecode = 'S'::text
                                    THEN aw.contractdesc || ' Stock'::text
                                WHEN aw.contractdesc !~~ ' %'::text THEN aw.contractdesc || ' '::text
                                ELSE aw.contractdesc
                                END), '/'::text, ''::text)
           ELSE regexp_replace(COALESCE(aw.rootcode, ''::text), '\.|-'::text, ''::text, 'g'::text)
           END                                                               AS          display_instrument_id,
       case
           when aw.expirationdate is not null and aw.strike IS NOT NULL then 'O'
           else 'E'
           end                                                               as          instrument_type_id,
       regexp_replace(COALESCE(aw.basecode, ''::text), '\.|-'::text, ''::text,
                      'g'::text)                                             AS          activ_symbol,
       aw.accountalias,
       'to do'                                                               as          is_sor_routed,
       case
           when lag(comp.companyname, 1) over (partition by CASE
                                                                WHEN aw.OrderReportSpecialType = 'M'
                                                                    THEN 'Manual Report'
                                                                ELSE aw.ExchangeTransactionID END order by aw.generation) <>
                comp.companyname
               and lag(aw.OrderID, 1) over (partition by CASE
                                                             WHEN aw.OrderReportSpecialType = 'M'
                                                                 THEN 'Manual Report'
                                                             ELSE aw.ExchangeTransactionID END order by aw.generation) =
                   aw.ParentORdeRID then 1
           else 0
           end                                                               as          is_company_name_changed,
       comp.companyname,
       case
           when aw.generation::int = 1 and aw.ParentOrderID is null then 0
           else aw.generation::int
           end                                                               as          generation,
       max(aw.generation::int) over (partition by CASE
                                                      WHEN aw.OrderReportSpecialType = 'M'
                                                          THEN 'Manual Report'
                                                      ELSE aw.ExchangeTransactionID END) mx_gen,
       ---- aux columns
       CASE
           WHEN coalesce(los.EDWID, bos.ID, 0) = 151 and aw.OrderReportSpecialType = 'M' then 156
           ELSE coalesce(los.EDWID, bos.ID, 0) END                           as          Status,
       coalesce(aw.manualexecutiontime, aw.transactiondatetime)::timestamptz as          TransactionDateTime,
       aw.legnumber,
       coalesce(lm.Ex_Destination, aw.ExDestination, '')                     as          ExCode,
       '8'                                                                   as          systemid,
       us.id                                                                 as          user_id,
       coalesce(lot.EDWID, oc.ID)                                            as          SystemOrderTypeID,
       comp.id                                                               as          companyid,
       coalesce(lm.Ex_Destination, aw.ExDestination, '')                     as          ExDestination,
       ---- orders, exec_ids, report_ids
       aw.orderid                                                            as          client_order_id,
       aw.parentorderid                                                      as          parent_client_order_id,
--                      aw.cancelorderid                                                                             as cancel_client_order_id,
       aw.contraorderid                                                      as          contra_client_order_id,
       aw.origorderid                                                        as          orig_client_order_id,
--                      aw.replaceorderid                                                                            as replace_client_order_id,
--                      aw.childorderid                                                                              as child_client_order_id,
       aw.reportid                                                           as          report_id,
       aw.childreportid                                                      as          child_exec_id,

       aw.order_id                                                           as          order_id,
       aw.chain_id                                                           as          chain_id,
       staging.clordid_to_guid(aw.orderid)                                   as          client_order_id_guid,
       staging.execid_to_guid(aw.reportid)                                   as          report_id_guid,
       '-1'::integer * base32_to_int8(aw.reportid)                           AS          exec_id


from staging.v_away_trade aw
         Left join staging.d_blaze_order_status bos
                   on aw.Status = bos.enum and bos.Order_or_Report_status = 2
         join staging.l_order_status los on bos.ID = los.StatusCode and los.SystemID = 8
         LEft join staging.d_blaze_exchange_codes lm
                   on aw.ExDestination = coalesce(lm.last_mkt, lm.ex_destination) and
                      CASE
                          WHEN aw.SecurityType = '1' THEN 'O'
                          WHEN aw.SecurityType = '2' THEN 'E'
                          ELSE aw.SecurityType END = lm.Security_Type
         LEFT JOIN staging.t_users us
                   on aw.UserID::int = us.USer_ID and us.System_ID = 2 and us.EDW_Active = 1 -- USER
         Left join staging.d_Order_Class oc on aw.SystemOrderTypeID = oc.enum
         Left join staging.l_order_type lot on oc.ID = lot.Code and lot.SystemID = 8
         LEFT JOIN billing.tCompany comp
                   on us.Company_ID = comp.CompanyID and us.System_ID = comp.SystemID
                       and comp.EDWActive = '1'::bit -- Company
         left join billing.dash_exchange_names den
                   on den.mic_code = regexp_replace(aw.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                      den.real_exchange_id = den.exchange_id and den.mic_code != '' and den.is_active
         left join billing.dash_exchange_names den1
                   on den1.exchange_id =
                      regexp_replace(aw.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                      den1.real_exchange_id = den1.exchange_id and den1.mic_code != '' and
                      den1.is_active = 'TRUE'
         LEFT JOIN staging.d_time_in_force tif ON tif.enum = aw.TimeInForceCode
         LEFT JOIN billing.time_in_force ltf ON tif.id = ltf.code AND ltf.systemid = 8
         LEFT JOIN billing.lforwhom lfw ON lfw.shortdesc::text = aw.ForWhom AND lfw.systemid = 4
         LEft join staging.d_liquidity_type lt on aw.LiquidityType = lt.enum
where true
--                 and aw.orderid = '1_po241029'
--   and aw.report_db_create_time::date = '2024-10-30'
--   and coalesce(aw.manualexecutiontime, aw.transactiondatetime)::timestamptz::date = '2024-10-30'::date
  and reportid >= 'jj4ogr3s0002'
  and reportid < 'jj4rk4380002'
    and (aw.Status in (151, 156, 239)
    and aw.SystemID::int in ('2', '3', '8')
    and aw.SystemOrderTypeID <> 87);
  and los.ID is not null
;
              )
select * from base
where Status in (151, 156, 239)
and SystemID in('2','3','8')
and SystemOrderTypeID <> 87;


-- DROP FUNCTION trash.so_load_away_trade();
select * from staging.away_trade;
create index away_trade_report_id on staging.away_trade (report_id);



create or replace function trash.so_load_away_trade(in_min_report_id text default null, in_max_report_id text default null)
    returns integer
    language plpgsql
as
$function$
declare
    l_last_loaded_report_id text;
    l_maxt_report_id        text;
    l_row_cnt               int4;
    l_load_id               int4;
    l_step_id               int4;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select into l_last_loaded_report_id report_id
    from staging.away_trade
    where true
    order by report_id desc
    limit 1;

    if l_last_loaded_report_id is null then
        l_last_loaded_report_id := coalesce(in_min_report_id, '');
    end if;

    select into l_maxt_report_id coalesce(in_max_report_id, exec_id)
    from staging.v_max_blaze_exec_id;

    select public.load_log(l_load_id, l_step_id,
                           'load_away_trade for report_id between ' || l_last_loaded_report_id::text ||
                           ' and ' || l_maxt_report_id || ' STARTED===',
                           0, 'O')
    into l_step_id;

    create temp table t_blaze on commit drop
    as
    select *
    from staging.v_away_trade aw
    where true
      and aw.reportid > coalesce(l_last_loaded_report_id, '')
      and aw.reportid <= l_maxt_report_id;

    select public.load_log(l_load_id, l_step_id, 'load_away_trade temp table created',
                           0, 'O')
    into l_step_id;

    insert into staging.away_trade(trade_record_time, date_id, is_busted, subsystem_id, account_name, side, open_close,
                                   exchange_id, trade_liquidity_indicator, secondary_order_id, secondary_exch_exec_id,
                                   last_mkt, last_qty, last_px, ex_destination, sub_strategy, street_order_qty,
                                   order_qty,
                                   multileg_reporting_type, exec_broker, cmta, tif, street_time_in_force,
                                   opt_customer_firm,
                                   is_cross_order, street_is_cross_order, contra_broker, client_id, order_price,
                                   order_process_time, remarks, street_client_order_id, fix_comp_id, leaves_qty,
                                   leg_ref_id,
                                   load_batch_id, strategy_decision_reason_code, is_parent, symbol, strike_price,
                                   put_or_call, maturity_year, maturity_month, maturity_day, security_type,
                                   child_orders,
                                   handling_id, secondary_order_id2, display_instrument_id, instrument_type_id,
                                   activ_symbol, accountalias, is_sor_routed, is_company_name_changed, companyname,
                                   generation, mx_gen, status, transactiondatetime, legnumber, excode, systemid,
                                   user_id,
                                   systemordertypeid, companyid, exdestination, client_order_id, parent_client_order_id,
                                   contra_client_order_id, orig_client_order_id, report_id, child_exec_id, order_id,
                                   chain_id, client_order_id_guid, report_id_guid, exec_id)
    select coalesce(aw.manualexecutiontime, aw.transactiondatetime)::timestamptz as          trade_record_time, -- check timezone
           to_char(coalesce(aw.manualexecutiontime, aw.transactiondatetime)::timestamptz,
                   'YYYYMMDD')::int                                              as          date_id,           -- check timezone
           'to do'                                                               as          is_busted,
           case when 8 = 8 then 'OMS_EDW' else 'LPEDW' end                       as          subsystem_id,      -- ?? 8 is hardcoded in [dbo].[vNormalizeBLAZE7Orders]
           coalesce(aw.dashaliasid,
                    case
                        when coalesce(us.aors_user_name, us.user_login) = 'BBNTRST' then 'NTRSCBOE'
                        else coalesce(us.aors_user_name, us.user_login)
                        end)                                                     as          account_name,
           aw.side,
           aw.OpenClose                                                          as          open_close,
           'no data'                                                             as          exchange_id,
           coalesce(aw.LiquidityIndicator, 'R')                                  as          trade_liquidity_indicator,
           aw.ExchangeMappedOrderID                                              as          secondary_order_id,
           CASE
               WHEN aw.OrderReportSpecialType = 'M' THEN 'Manual Report'
               ELSE aw.ExchangeTransactionID END                                 as          secondary_exch_exec_id,

           case
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                    ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                    ('XPAR', 'PLAK', 'PARL')
                   then 'LQPT'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                    ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                    ('FOGS', 'MID')
                   then 'XCHI'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                    ('C2', 'CBOE2')
                   then 'C2OX'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) = 'SMARTR'
                   then 'COWEN'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in
                    ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in ('XPSE')
                   then 'N'
               when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, aw.ExDestination) in ('TO')
                   then '1'
               else coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination,
                             aw.ExDestination) end                               as          last_mkt,
           coalesce(aw.lastshares::int, 0)                                       as          last_qty,
           round(aw.lastprice::numeric / 10000.0, 8)                             as          last_px,
           coalesce(lm.Ex_Destination, aw.ExDestination, '')                     as          ex_destination,
           'no data'                                                             as          sub_strategy,
--        	coalesce(nullif(case when nullif(aw.[ExpirationDate],'1900-01-01 00:00:00.000') is not null and nullif(aw.[Strike],0.00) is not null then aw.OptionQuantity
-- 			else aw.StockQuantity end,0),aw.Quantity) as street_order_qty,
           coalesce(case
                        when aw.ExpirationDate is not null and aw.Strike is not null then aw.OptionQuantity
                        else aw.StockQuantity end,
                    aw.Quantity)::int8                                           as          street_order_qty,
           coalesce(case
                        when aw.ExpirationDate is not null and aw.Strike is not null then aw.OptionQuantity
                        else aw.StockQuantity end,
                    aw.Quantity)::int8                                           as          order_qty,
           case when aw.LegCount::int4 > 1 then 2 else 1 end                     as          multileg_reporting_type,
           coalesce(aw.GiveUpFirm, aw.ExecutingBroker)                           as          exec_broker,
           aw.CMTAFirm                                                           as          cmta,
           coalesce(ltf.edwid, tif.id)                                           as          tif,
           case
               when coalesce(ltf.edwid, tif.id) = any (array [24, 17, 10, 1, 44]) then 0
               when coalesce(ltf.edwid, tif.id) = any (array [26, 18, 3, 45, 12]) then 1
               when coalesce(ltf.edwid, tif.id) = any (array [31, 8, 15, 46]) then 2
               when coalesce(ltf.edwid, tif.id) = any (array [47, 28, 11, 19, 5]) then 3
               when coalesce(ltf.edwid, tif.id) = any (array [48, 2, 13, 25, 20]) then 4
               when coalesce(ltf.edwid, tif.id) = any (array [36, 37, 38, 49]) then 5
               when coalesce(ltf.edwid, tif.id) = any (array [50, 14, 21, 33]) then 6
               when coalesce(ltf.edwid, tif.id) = any (array [32, 9, 16]) then 7
               end                                                               as          street_time_in_force,
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
               end                                                               as          opt_customer_firm,
           case when aw.OrigOrderID is not null then 'Y' else 'N' end            as          is_cross_order,
           case when aw.OrigOrderID is not null then 'Y' else 'N' end            as          street_is_cross_order,
           aw.ContraBroker                                                       as          contra_broker,
           coalesce(comp.CompanyCode, us.user_login)                             as          client_id,
           case
               when round(aw.price::bigint / 10000.0, 4) > 99999999.9999 then 99999999.9999
               else round(aw.price::bigint / 10000.0, 4) end                     as          order_price,
           'no data'                                                             as          order_process_time,
           'no data'                                                             as          remarks,
           aw.ExchangeMappedOrderID                                              as          street_client_order_id,
           'LPEDWCOMPID'                                                         as          fix_comp_id,
           aw.leavesqty::bigint                                                  as          leaves_qty,
           aw.Legnumber                                                          as          leg_ref_id,
           null                                                                  as          load_batch_id,
           CASE
               WHEN aw.ORIGOrderID is not null or aw.ContraOrderID is not null then 26
               WHEN aw.ParentOrderID is not null or
                    (aw.ParentOrderID is null and nullif(aw.ChildOrders::int, 0) is not null) then 10
               WHEN aw.COMMENT like '%OVR%' then 4
               ELSE 50 end                                                       as          strategy_decision_reason_code,
           case when aw.ParentID is null then 'Y' else 'N' end                   as          is_parent,
           aw.basecode                                                           as          symbol,
           round(aw.strike::numeric, 6)                                          as          strike_price,
           case aw.TypeCode
               when 'P' then '0'
               when 'C' then '1'
               end                                                               as          put_or_call,
           extract(year from aw.expirationdate)                                  as          maturity_year,
           extract(month from aw.expirationdate)                                 as          maturity_month,
           extract(day from aw.expirationdate)                                   as          maturity_day,
           CASE
               WHEN aw.SecurityType = 'O' THEN 1
               WHEN aw.SecurityType = 'E' THEN 2
               ELSE aw.SecurityType::int END                                     as          security_type,
           aw.ChildOrders                                                        as          child_orders,
           coalesce(case when aw.OrderReportSpecialType = 'M' then lt.ID ELSE aw.Handling::int END,
                    0)                                                           as          handling_id,
           0                                                                     as          secondary_order_id2,
           case
               when aw.expirationdate is not null and aw.strike IS NOT NULL
                   THEN replace(
                       COALESCE(((((regexp_replace(COALESCE(aw.basecode, ''::text), '\.|-'::text, ''::text,
                                                   'g'::text) ||
                                    ' '::text) ||
                                   to_char(aw.expirationdate::timestamp with time zone, 'DDMonYY'::text)) ||
                                  ' '::text) || staging.trailing_dot(aw.strike)) || "left"(aw.typecode, 8),
                                CASE
                                    WHEN aw.contractdesc !~~ (aw.basecode || ' %'::text) THEN
                                        (aw.basecode || ' '::text) ||
                                        replace(aw.contractdesc, aw.basecode, ''::text)
                                    WHEN aw.legcount::integer = 1 AND aw.typecode = 'S'::text
                                        THEN aw.contractdesc || ' Stock'::text
                                    WHEN aw.contractdesc !~~ ' %'::text THEN aw.contractdesc || ' '::text
                                    ELSE aw.contractdesc
                                    END), '/'::text, ''::text)
               ELSE regexp_replace(COALESCE(aw.rootcode, ''::text), '\.|-'::text, ''::text, 'g'::text)
               END                                                               AS          display_instrument_id,
           case
               when aw.expirationdate is not null and aw.strike IS NOT NULL then 'O'
               else 'E'
               end                                                               as          instrument_type_id,
           regexp_replace(COALESCE(aw.basecode, ''::text), '\.|-'::text, ''::text,
                          'g'::text)                                             AS          activ_symbol,
           aw.accountalias,
           'to do'                                                               as          is_sor_routed,
           case
               when lag(comp.companyname, 1) over (partition by CASE
                                                                    WHEN aw.OrderReportSpecialType = 'M'
                                                                        THEN 'Manual Report'
                                                                    ELSE aw.ExchangeTransactionID END order by aw.generation) <>
                    comp.companyname
                   and lag(aw.OrderID, 1) over (partition by CASE
                                                                 WHEN aw.OrderReportSpecialType = 'M'
                                                                     THEN 'Manual Report'
                                                                 ELSE aw.ExchangeTransactionID END order by aw.generation) =
                       aw.ParentORdeRID then 1
               else 0
               end                                                               as          is_company_name_changed,
           comp.companyname,
           case
               when aw.generation::int = 1 and aw.ParentOrderID is null then 0
               else aw.generation::int
               end                                                               as          generation,
           max(aw.generation::int) over (partition by CASE
                                                          WHEN aw.OrderReportSpecialType = 'M'
                                                              THEN 'Manual Report'
                                                          ELSE aw.ExchangeTransactionID END) mx_gen,
           ---- aux columns
           CASE
               WHEN coalesce(los.EDWID, bos.ID, 0) = 151 and aw.OrderReportSpecialType = 'M' then 156
               ELSE coalesce(los.EDWID, bos.ID, 0) END                           as          Status,
           coalesce(aw.manualexecutiontime, aw.transactiondatetime)::timestamptz as          TransactionDateTime,
           aw.legnumber,
           coalesce(lm.Ex_Destination, aw.ExDestination, '')                     as          ExCode,
           '8'                                                                   as          systemid,
           us.id                                                                 as          user_id,
           coalesce(lot.EDWID, oc.ID)                                            as          SystemOrderTypeID,
           comp.id                                                               as          companyid,
           coalesce(lm.Ex_Destination, aw.ExDestination, '')                     as          ExDestination,
           ---- orders, exec_ids, report_ids
           aw.orderid                                                            as          client_order_id,
           aw.parentorderid                                                      as          parent_client_order_id,
--                      aw.cancelorderid                                                                             as cancel_client_order_id,
           aw.contraorderid                                                      as          contra_client_order_id,
           aw.origorderid                                                        as          orig_client_order_id,
--                      aw.replaceorderid                                                                            as replace_client_order_id,
--                      aw.childorderid                                                                              as child_client_order_id,
           aw.reportid                                                           as          report_id,
           aw.childreportid                                                      as          child_exec_id,

           aw.order_id                                                           as          order_id,
           aw.chain_id                                                           as          chain_id,
           staging.clordid_to_guid(aw.orderid)                                   as          client_order_id_guid,
           staging.execid_to_guid(aw.reportid)                                   as          report_id_guid,
           '-1'::integer * base32_to_int8(aw.reportid)                           AS          exec_id

-- select *
    from t_blaze aw --staging.v_away_trade aw
             Left join staging.d_blaze_order_status bos
                       on aw.Status = bos.enum and bos.Order_or_Report_status = 2
             join staging.l_order_status los on bos.ID = los.StatusCode and los.SystemID = 8
             LEft join staging.d_blaze_exchange_codes lm
                       on aw.ExDestination = coalesce(lm.last_mkt, lm.ex_destination) and
                          CASE
                              WHEN aw.SecurityType = '1' THEN 'O'
                              WHEN aw.SecurityType = '2' THEN 'E'
                              ELSE aw.SecurityType END = lm.Security_Type
             LEFT JOIN staging.t_users us
                       on aw.UserID::int = us.USer_ID and us.System_ID = 2 and us.EDW_Active = 1 -- USER
             Left join staging.d_Order_Class oc on aw.SystemOrderTypeID = oc.enum
             Left join staging.l_order_type lot on oc.ID = lot.Code and lot.SystemID = 8
             LEFT JOIN billing.tCompany comp
                       on us.Company_ID = comp.CompanyID and us.System_ID = comp.SystemID
                           and comp.EDWActive = '1'::bit -- Company
             left join billing.dash_exchange_names den
                       on den.mic_code = regexp_replace(aw.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                          den.real_exchange_id = den.exchange_id and den.mic_code != '' and den.is_active
             left join billing.dash_exchange_names den1
                       on den1.exchange_id =
                          regexp_replace(aw.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                          den1.real_exchange_id = den1.exchange_id and den1.mic_code != '' and
                          den1.is_active = 'TRUE'
             LEFT JOIN staging.d_time_in_force tif ON tif.enum = aw.TimeInForceCode
             LEFT JOIN billing.time_in_force ltf ON tif.id = ltf.code AND ltf.systemid = 8
             LEFT JOIN billing.lforwhom lfw ON lfw.shortdesc::text = aw.ForWhom AND lfw.systemid = 4
             LEft join staging.d_liquidity_type lt on aw.LiquidityType = lt.enum
    where true
      and aw.reportid > coalesce(l_last_loaded_report_id, '')
    --       and aw.reportid <= 'jj5cs060000c'
-- --       and CASE
-- --               WHEN coalesce(los.EDWID, bos.ID, 0) = 151 and aw.OrderReportSpecialType = 'M' then 156
-- --               ELSE coalesce(los.EDWID, bos.ID, 0) END in (151, 156, 239)
-- -- --and SystemID in('2','3','8')
-- --       and coalesce(lot.EDWID, oc.ID) <> 87
--     and aw.report_db_create_time::date = '2024-10-30'
--     and aw.order_trade_date_id >= 20241030
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'load_away_trade COMPLETED ===',
                           l_row_cnt, 'O')
    into l_step_id;
    return l_row_cnt;

end;
$function$
;
truncate staging.away_trade;
select * from trash.so_load_away_trade('jj4pujdk0000', 'jj5ihm400000');
select * from trash.so_load_away_trade(in_max_report_id := 'jj5nqgsg0004');

select * from trash.so_load_away_trade(in_max_report_id := 'jj5rcsgc0004');
select * from trash.so_load_away_trade(in_max_report_id := 'jj60h2q00006');
select * from trash.so_load_away_trade(in_max_report_id := 'jj63rb900002');
select * from trash.so_load_away_trade(in_max_report_id := 'jj67rq6k0004');
select * from trash.so_load_away_trade(in_max_report_id := 'jj6a40q00000');
select * from trash.so_load_away_trade(in_max_report_id := 'jj6crkck0002');

select * from trash.so_load_away_trade(in_max_report_id := 'jj6htme00006');
select * from trash.so_load_away_trade(in_max_report_id := 'jj6kc4v40000');
select * from trash.so_load_away_trade(in_max_report_id := 'jj6q0sr40000');
select * from trash.so_load_away_trade(in_max_report_id := 'jj71idog0000');
select * from trash.so_load_away_trade(in_max_report_id := 'jj76jbm80000');
select * from trash.so_load_away_trade(in_max_report_id := 'jj7cs46g0000');