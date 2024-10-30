create function staging.base32_to_int8(in_string text)
    returns bigint
    language plpgsql
    immutable
as
$fn$
    -- 2024-09-02 SO https://dashfinancial.atlassian.net/browse/DS-8441 transformation exec_id in base32 coding into int8
    -- 2024-10-30 SO moved to staging
declare
    l_base_string text := '0123456789abcdefghijklmnopqrstuv';
    l_ret_result  int8 := 0;
    l_each_char   char;
    l_iter        int  := 1;
    l_base_length int  := length(in_string);
begin
    while l_iter <= l_base_length
        loop
            l_each_char := lower(substring(in_string from l_iter for 1));
            l_ret_result := l_ret_result * 32 + (position(l_each_char in l_base_string) - 1);
            l_iter := l_iter + 1;
        end loop;

    return l_ret_result;
end;
$fn$
;
comment on function staging.base32_to_int8(text) is 'Convering base32 exec_id\report_id on blaze7 envs into int8';


-- DROP FUNCTION staging.base64_to_hex(text);

create function staging.base64_to_hex(in_value text default null)
    returns text
    language plpgsql
    immutable
AS
$fn$
    -- 20241030 SO https://dashfinancial.atlassian.net/browse/DS-8441
declare
    l_each_char     char;
    l_ln            int;
    l_bit_string    text := '';
    l_result_string text = '';
    l_to_ext        bool = false;

begin
    if in_value is null
    then
        return '';
    end if;

    foreach l_each_char in array regexp_split_to_array(in_value, '')
        loop
            l_bit_string = ascii(l_each_char)::bit(8) || l_bit_string;

        end loop;
    l_ln = length(l_bit_string);

    loop
        if l_ln <= 4 then
            l_bit_string = right('000' || substr(l_bit_string, 1, l_ln), 4);
            l_to_ext = TRUE;
        end if;
        l_result_string = to_hex(substr(l_bit_string, l_ln - 3, 4)::bit(4)::int) || l_result_string;
        l_ln = l_ln - 4;

        if l_to_ext
        then
            exit;
        end if;
    end loop;
    return l_result_string;

end;
$fn$
;
comment on function staging.base64_to_hex is ' auxiliary function to convert base64 text into bit string. Used from execid_to_guid and clordid_to_guid';

select staging.base64_to_hex('01af');

drop function if exists staging.execid_to_guid(text);

create function staging.execid_to_guid(in_text text default null)
    returns text
    language plpgsql
    immutable
as
$fn$
    -- 20241030 SO https://dashfinancial.atlassian.net/browse/DS-8441
declare
    l_part_01 varchar;

begin
    if in_text is null then
        return '00000000-0000-0000-0000-000000000000';
    end if;

    l_part_01 = right('000000000000000000000000' || staging.base64_to_hex(in_text), 32);

    return
        substring(l_part_01, 1, 8) || '-' || substring(l_part_01, 9, 4) || '-' || substring(l_part_01, 13, 4) || '-' ||
        substring(l_part_01, 17, 4) || '-' || substring(l_part_01, 21, 12);

end;
$fn$;
comment on function staging.execid_to_guid is ' Function to convert text like f8cq4dik0000 into pseudo GUID';
-- select staging.execid_to_guid('f8cq4dik0000');


drop function if exists staging.clordid_to_guid;
create function staging.clordid_to_guid(in_text text default null)
    returns text
    language plpgsql
    immutable
as
$fn$
    -- 20241030 SO https://dashfinancial.atlassian.net/browse/DS-8441
declare
    l_main_01       text;
    l_main_02       text;
    l_part_01       text := '';
    l_part_02       text;
    l_result_string text := '';
    l_rec           record;

begin
    if in_text is null
    then
        return '00000000-0000-0000-0000-000000000000';
    end if;

    l_main_01 = substring(in_text, '(.{1,7})_[a-z0-9]*$'::text);
    l_main_02 = substring(in_text, '_([a-z0-9]*)$'::text); -- the second part - after the last underscore

    for l_rec in (select regexp_split_to_table(l_main_01, '_') as lett)
        loop
            l_part_01 = l_rec.lett::text || l_part_01;
        end loop;
    l_part_01 = right('0000' || l_part_01, 4);

    l_part_02 = right('00000000000000000000' || staging.base64_to_hex(substring(l_main_02, '^(.*)\d{6}$'::text)) ||
                      to_hex(substring(l_main_02, '^.*(\d{6})$'::text)::int), 20);

    l_result_string =
            '00000000-' || l_part_01 || '-' || substring(l_part_02, 1, 4) || '-' || substring(l_part_02, 5, 4) || '-' ||
            substring(l_part_02, 9, 12);
    return l_result_string;
end;
$fn$;
comment on function staging.clordid_to_guid is 'Function to convert text like 1_3230826 or f_0_6k230831 into pseudo GUID';
select staging.clordid_to_guid('f_0_6k230831');
select staging.clordid_to_guid('1_3230826');


-- main query
drop view if exists trash.v_away_trade;
-- create view trash.v_away_trade as
-- create table trash.so_away_trade as
select coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz as          trade_record_time, -- check timezone
       to_char(coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz,
               'YYYYMMDD')::int                                                as          date_id,           -- check timezone
       'N'                                                                     as          is_busted,
       case when 8 = 8 then 'OMS_EDW' else 'LPEDW' end                         as          subsystem_id,      -- ?? 8 is hardcoded in [dbo].[vNormalizeBLAZE7Orders]
       coalesce(tom.dashaliasid,
                case
                    when coalesce(us.aors_user_name, us.user_login) = 'BBNTRST' then 'NTRSCBOE'
                    else coalesce(us.aors_user_name, us.user_login)
                    end)                                                       as          account_name,
       tl.side,
       tl.OpenClose                                                            as          open_close,
--        rep.reportid                                                            as          exec_id,
       'no data'                                                               as          exchange_id,
       coalesce(rep.LiquidityIndicator, 'R')                                   as          trade_liquidity_indicator,
       rep.ExchangeMappedOrderID                                               as          secondary_order_id,
       CASE
           WHEN rep.OrderReportSpecialType = 'M' THEN 'Manual Report'
           ELSE rep.ExchangeTransactionID END                                  as          secondary_exch_exec_id,

       case
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('XPAR', 'PLAK', 'PARL')
               then 'LQPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('FOGS', 'MID')
               then 'XCHI'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('C2', 'CBOE2')
               then 'C2OX'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) = 'SMARTR'
               then 'COWEN'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in
                ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in ('XPSE')
               then 'N'
           when coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination, rep.ExDestination) in ('TO')
               then '1'
           else coalesce(den.last_mkt, den1.last_mkt, lm.Ex_Destination,
                         rep.ExDestination) end                                as          last_mkt,
       coalesce(rep.lastshares::int, 0)                                        as          last_qty,
       round(lastprice::numeric / 10000.0, 8)                                  as          last_px,
       coalesce(lm.Ex_Destination, rep.ExDestination, '')                      as          ex_destination,
       'no data'                                                               as          sub_strategy,
--        	coalesce(nullif(case when nullif(tl.[ExpirationDate],'1900-01-01 00:00:00.000') is not null and nullif(tl.[Strike],0.00) is not null then tl.OptionQuantity
-- 			else tl.StockQuantity end,0),tl.Quantity) as street_order_qty,
       coalesce(case
                    when tl.ExpirationDate is not null and tl.Strike is not null then tl.OptionQuantity
                    else tl.StockQuantity end,
                tl.Quantity)::int8                                             as          street_order_qty,
       coalesce(case
                    when tl.ExpirationDate is not null and tl.Strike is not null then tl.OptionQuantity
                    else tl.StockQuantity end,
                tl.Quantity)::int8                                             as          order_qty,
       case when ord.LegCount::int4 > 1 then 2 else 1 end                      as          multileg_reporting_type,
       coalesce(ord.GiveUpFirm, rep.ExecutingBroker)                           as          exec_broker,
       ord.CMTAFirm                                                            as          cmta,
       coalesce(ltf.edwid, tif.id)                                             as          tif,
       case
           when coalesce(ltf.edwid, tif.id) = any (array [24, 17, 10, 1, 44]) then 0
           when coalesce(ltf.edwid, tif.id) = any (array [26, 18, 3, 45, 12]) then 1
           when coalesce(ltf.edwid, tif.id) = any (array [31, 8, 15, 46]) then 2
           when coalesce(ltf.edwid, tif.id) = any (array [47, 28, 11, 19, 5]) then 3
           when coalesce(ltf.edwid, tif.id) = any (array [48, 2, 13, 25, 20]) then 4
           when coalesce(ltf.edwid, tif.id) = any (array [36, 37, 38, 49]) then 5
           when coalesce(ltf.edwid, tif.id) = any (array [50, 14, 21, 33]) then 6
           when coalesce(ltf.edwid, tif.id) = any (array [32, 9, 16]) then 7
           end                                                                 as          street_time_in_force,
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
           end                                                                 as          opt_customer_firm,
       case when ord.OrigOrderID is not null then 'Y' else 'N' end             as          is_cross_order,
       case when ord.OrigOrderID is not null then 'Y' else 'N' end             as          street_is_cross_order,
       rep.ContraBroker                                                        as          contra_broker,
       coalesce(comp.CompanyCode, us.user_login)                               as          client_id,
       case
           when round(tl.price::bigint / 10000.0, 4) > 99999999.9999 then 99999999.9999
           else round(tl.price::bigint / 10000.0, 4) end                       as          order_price,
       'no data'                                                               as          order_process_time,
       'no data'                                                               as          remarks,
       rep.ExchangeMappedOrderID                                               as          street_client_order_id,
       'LPEDWCOMPID'                                                           as          fix_comp_id,
       rep.leavesqty::bigint                                                   as          leaves_qty,
       tl.Legnumber                                                            as          leg_ref_id,
       null                                                                    as          load_batch_id,
       CASE
           WHEN ord.ORIGOrderID is not null or ord.ContraOrderID is not null then 26
           WHEN ord.ParentOrderID is not null or
                (ord.ParentOrderID is null and nullif(ord.ChildOrders::int, 0) is not null) then 10
           WHEN ord.COMMENT like '%OVR%' then 4
           ELSE 50 end                                                         as          strategy_decision_reason_code,
       case when rep.ParentID is null then 'Y' else 'N' end                    as          is_parent,
       tl.basecode                                                             as          symbol,
       round(tl.strike::numeric, 6)                                            as          strike_price,
       case tl.TypeCode
           when 'P' then '0'
           when 'C' then '1'
           end                                                                 as          put_or_call,
       extract(year from tl.expirationdate)                                    as          maturity_year,
       extract(month from tl.expirationdate)                                   as          maturity_month,
       extract(day from tl.expirationdate)                                     as          maturity_day,
       CASE
           WHEN rep.SecurityType = 'O' THEN 1
           WHEN rep.SecurityType = 'E' THEN 2
           ELSE rep.SecurityType::int END                                      as          security_type,
       ord.ChildOrders                                                         as          child_orders,
       coalesce(case when rep.OrderReportSpecialType = 'M' then lt.ID ELSE rep.Handling::int END,
                0)                                                             as          handling_id,
       0                                                                       as          secondary_order_id2,
       case
           when tl.expirationdate is not null and tl.strike IS NOT NULL
               THEN replace(
                   COALESCE(((((regexp_replace(COALESCE(tl.basecode, ''::text), '\.|-'::text, ''::text,
                                               'g'::text) ||
                                ' '::text) ||
                               to_char(tl.expirationdate::timestamp with time zone, 'DDMonYY'::text)) ||
                              ' '::text) || staging.trailing_dot(tl.strike)) || "left"(tl.typecode, 8),
                            CASE
                                WHEN ord.contractdesc !~~ (tl.basecode || ' %'::text) THEN
                                    (tl.basecode || ' '::text) ||
                                    replace(ord.contractdesc, tl.basecode, ''::text)
                                WHEN ord.legcount::integer = 1 AND tl.typecode = 'S'::text
                                    THEN ord.contractdesc || ' Stock'::text
                                WHEN ord.contractdesc !~~ ' %'::text THEN ord.contractdesc || ' '::text
                                ELSE ord.contractdesc
                                END), '/'::text, ''::text)
           ELSE regexp_replace(COALESCE(tl.rootcode, ''::text), '\.|-'::text, ''::text, 'g'::text)
           END                                                                 AS          display_instrument_id,
       case
           when tl.expirationdate is not null and tl.strike IS NOT NULL then 'O'
           else 'E'
           end                                                                 as          instrument_type_id,
       regexp_replace(COALESCE(tl.basecode, ''::text), '\.|-'::text, ''::text,
                      'g'::text)                                               AS          activ_symbol,
       ord.accountalias,
       'to do'                                                                 as          is_sor_routed,
       case
           when lag(comp.companyname, 1) over (partition by CASE
                                                                WHEN rep.OrderReportSpecialType = 'M'
                                                                    THEN 'Manual Report'
                                                                ELSE rep.ExchangeTransactionID END order by ord.generation) <>
                comp.companyname
               and lag(ord.OrderID, 1) over (partition by CASE
                                                              WHEN rep.OrderReportSpecialType = 'M'
                                                                  THEN 'Manual Report'
                                                              ELSE rep.ExchangeTransactionID END order by ord.generation) =
                   ord.ParentORdeRID then 1
           else 0
           end                                                                 as          is_company_name_changed,
       comp.companyname,
       case
           when ord.generation::int = 1 and ord.ParentOrderID is null then 0
           else ord.generation::int
           end                                                                 as          generation,
       max(ord.generation::int) over (partition by CASE
                                                       WHEN rep.OrderReportSpecialType = 'M'
                                                           THEN 'Manual Report'
                                                       ELSE rep.ExchangeTransactionID END) mx_gen,
       ---- aux columns
       CASE
           WHEN coalesce(los.EDWID, bos.ID, 0) = 151 and rep.OrderReportSpecialType = 'M' then 156
           ELSE coalesce(los.EDWID, bos.ID, 0) END                             as          Status,
       coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz as          TransactionDateTime,
       rep.legnumber,
       coalesce(lm.Ex_Destination, rep.ExDestination, '')                      as          ExCode,
       '8'                                                                     as          systemid,
       us.id                                                                   as          user_id,
       coalesce(lot.EDWID, oc.ID)                                              as          SystemOrderTypeID,
       comp.id                                                                 as          companyid,
       coalesce(lm.Ex_Destination, rep.ExDestination, '')                      as          ExDestination,
       ---- orders, exec_ids, report_ids
       rep.orderid                                                             as          client_order_id,
       ord.parentorderid                                                       as          parent_client_order_id,
       ord.cancelorderid                                                       as          cancel_client_order_id,
       ord.contraorderid                                                       as          contra_client_order_id,
       ord.origorderid                                                         as          orig_client_order_id,
       ord.replaceorderid                                                      as          replace_client_order_id,
       rep.childorderid                                                        as          child_client_order_id,
       rep.reportid                                                            as          report_id,
       rep.childreportid                                                       as          child_exec_id,

       rep._order_id                                                           as          order_id,
       rep._chain_id                                                           as          chain_id,

       staging.clordid_to_guid(ord.orderid)                                    as          client_order_id_guid,
       staging.execid_to_guid(rep.reportid)                                    as          report_id_guid,
       '-1'::integer * base32_to_int8(rep.reportid)                            AS          exec_id
from staging.temp_treports_edw rep
         join staging.torder_edw ord on ord.orderid = rep.orderid
         join staging.tordermisc1_edw tom on tom.orderid = rep.orderid
         left join staging.tlegs_edw tl on tl.orderid = rep.orderid and tl.legnumber = rep.legnumber
         Left join staging.d_blaze_order_status bos
                   on rep.Status = bos.enum and bos.Order_or_Report_status = 2
         join staging.l_order_status los on bos.ID = los.StatusCode and los.SystemID = 8
         LEft join staging.d_blaze_exchange_codes lm
                   on rep.ExDestination = coalesce(lm.last_mkt, lm.ex_destination) and
                      CASE
                          WHEN rep.SecurityType = '1' THEN 'O'
                          WHEN rep.SecurityType = '2' THEN 'E'
                          ELSE rep.SecurityType END = lm.Security_Type
         LEFT JOIN staging.t_users us
                   on rep.UserID::int = us.USer_ID and us.System_ID = 2 and us.EDW_Active = 1 -- USER
         Left join staging.d_Order_Class oc on ord.SystemOrderTypeID = oc.enum
         Left join staging.l_order_type lot on oc.ID = lot.Code and lot.SystemID = 8
         LEFT JOIN billing.tCompany comp
                   on us.Company_ID = comp.CompanyID and us.System_ID = comp.SystemID
                       and comp.EDWActive = '1'::bit -- Company
         left join billing.dash_exchange_names den
                   on den.mic_code = regexp_replace(rep.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                      den.real_exchange_id = den.exchange_id and den.mic_code != '' and den.is_active
         left join billing.dash_exchange_names den1
                   on den1.exchange_id =
                      regexp_replace(rep.ExDestination, '(DIRECT-| Printer)', '', 'g') and
                      den1.real_exchange_id = den1.exchange_id and den1.mic_code != '' and
                      den1.is_active = 'TRUE'
         LEFT JOIN staging.d_time_in_force tif ON tif.enum = ord.TimeInForceCode
         LEFT JOIN billing.time_in_force ltf ON tif.id = ltf.code AND ltf.systemid = 8
         LEFT JOIN billing.lforwhom lfw ON lfw.shortdesc::text = ord.ForWhom AND lfw.systemid = 4
         LEft join staging.d_liquidity_type lt on rep.LiquidityType = lt.enum
where true
--   and los.ID is not null;
 and rep.reportid >= 'jj5s3fes0000'
and coalesce(rep.manualexecutiontime, rep.transactiondatetime)::timestamptz::date = '2024-10-30'::date
   order by rep.reportid
--                limit 1
and rep.reportid = 'jitanr200000'

select *
from trash.v_away_trade
where true
  and client_order_id = '1_2q1241029'
  and report_id = '1_2q1241029'
  and trade_record_time::date = '2024-10-29'::date
  and (Status in (151, 156, 239)
    and SystemID::int in (2, 3, 8)
    and SystemOrderTypeID <> 87);

-- alter table trash.so_away_trade rename to so_away_trade_old;
SELECT r2.legcount,
       r2.giveupfirm,
       r2.cmtafirm,
       r2.origorderid,
       r2.contraorderid,
       r2.parentorderid,
       r2.childorders,
       r2.comment,
       r2.contractdesc,
       r2.accountalias,
       r2.orderid,
       r2.generation,
       r2.cancelorderid,
       r2.replaceorderid,
       r2.systemordertypeid,
       r2.timeinforcecode,
       r2.forwhom,
       r4.dashaliasid,
       r4.orderid
FROM (blaze7.torder_edw r2 INNER JOIN blaze7.tordermisc1_edw r4 ON (((r2.orderid = r4.orderid))))


(((COALESCE(rep.manualexecutiontime, rep.transactiondatetime))::timestamp with time zone)::date = '2024-10-30'::date)