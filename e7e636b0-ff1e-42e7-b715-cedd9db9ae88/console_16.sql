alter table trash.so_away_trade add column order_create_time text;
alter table trash.so_away_trade add column blaze_account_alias text;

drop view trash.so_missed_lp;
create view trash.so_missed_lp as
select aw.order_id,
       aw.orderid                                                                               as order_id_guid,
       aw.ex_destination                                                                        as rep_ex_destination,
       trade_record_time,
       db_create_time,
       date_id,
       aw.is_busted                                                                             as is_busted,     -- I have a faint hope that this can be solved in another way used in the originl script
       'LPEDW'                                                                                  as subsystem_id,
       coalesce(aw.dashaliasid, case
                                    when coalesce(us.aors_user_name, us.user_Login) = 'BBNTRST' then 'NTRSCBOE'
                                    else coalesce(us.aors_user_name, us.user_Login) end)        as account_name,
       aw.cl_ord_id                                                                             as client_order_id,
       '???'                                                                                    as instrument_id,
       aw.side,
       aw.openclose,
       '???'                                                                                    as exec_id,
       '0'                                                                                      as exch_exec_id,
       aw.secondary_exch_exec_id,
--        aw.SecurityType,
--        den.last_mkt,
--        den1.last_mkt,
       case
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in
                ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in ('XPAR', 'PLAK', 'PARL')
               then 'LQPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in
                ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in ('FOGS', 'MID')
               then 'XCHI'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in ('C2', 'CBOE2')
               then 'C2OX'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) = 'SMARTR' then 'COWEN'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in
                ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in ('XPSE') then 'N'
           when coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) in ('TO') then '1'
           else coalesce(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination) end as last_mkt,
       aw.lastshares                                                                            as last_qty,
       aw.last_px,
       coalesce(lm.ex_destination, aw.ex_destination)                                           as ex_destination,
       '???'                                                                                    as sub_strategy,
--        '???'                                                                                    as order_id,
       coalesce(
               case
                   when aw.expiration_date is not null and aw.strike_price is not null then
                       aw.opt_qty
                   else
                       aw.eq_qty end,
               eq_leaves_qty)                                                                   as street_order_qty,
       coalesce(
               case
                   when aw.expiration_date is not null and aw.strike_price is not null then
                       aw.opt_qty
                   else
                       aw.eq_qty end, eq_leaves_qty)                                            as order_qty,
       aw.multileg_reporting_type,
       aw.exec_broker,
       aw.cmtafirm                                                                              as cmta,
       coalesce(ltf.EDWID, tif.ID)                                                              as tif,
       case
           when coalesce(ltf.EDWID, tif.ID) in (24, 17, 10, 1, 44) then 0
           when coalesce(ltf.EDWID, tif.ID) in (26, 18, 3, 45, 12) then 1
           when coalesce(ltf.EDWID, tif.ID) in (31, 8, 15, 46) then 2
           when coalesce(ltf.EDWID, tif.ID) in (47, 28, 11, 19, 5) then 3
           when coalesce(ltf.EDWID, tif.ID) in (48, 2, 13, 25, 20) then 4
           when coalesce(ltf.EDWID, tif.ID) in (36, 37, 38, 49) then 5
           when coalesce(ltf.EDWID, tif.ID) in (50, 14, 21, 33) then 6
           when coalesce(ltf.EDWID, tif.ID) in (32, 9, 16) then 7
           end                                                                                  as street_time_in_force,

       case
           when lfw.EDWID in (1, 25, 32, 78) then '0'
           when lfw.EDWID in (33, 26, 79) then '1'
           when lfw.EDWID in (52, 103, 20, 97) then '2'
           when lfw.EDWID in (19, 30, 38, 96) then '3'
           when lfw.EDWID in (35, 28, 4, 81) then '4'
           when lfw.EDWID in (5, 29, 36, 82) then '5'
           when lfw.EDWID IN (21, 6, 83) then '7'
           when lfw.EDWID IN (31, 23, 41, 98) then '8'
           when lfw.EDWID IN (9, 40, 50, 86) then 'J'
           end                                                                                  as opt_customer_firm,

       CASE
           when aw.crossing_side = 'C' and aw.cross_cl_ord_id is not null then 'Y'
           when aw.crossing_side <> 'C' and aw.orig_cl_ord_id is not null then 'Y'
           else 'N'
           END                                                                                  as is_cross_order,
-- street_is_cross_order is as same as is_cross_order
       aw.contra_broker,
       coalesce(cmp.CompanyCode, us.user_login)                                                 as client_id,
       round(aw.order_price::bigint / 10000.0, 4)                                               as order_price,
       '???'                                                                                    as order_process_time,
       '???'                                                                                    as remarks,
       null                                                                                     as street_client_order_id,
       'LPEDWCOMPID'                                                                            as fix_comp_id,
       aw.leaves_qty,
       aw.leg_ref_id,
       '???'                                                                                    as load_batch_id,

       case
           when aw.orig_order_id is not null then 26
           when aw.contra_order_id is not null then 26
           when aw.parent_order_id is not null then 10
           when aw.parent_order_id is null and aw.last_child_order != '0' then 10
           when rep_comment like '%OVR%' then 4
           else 50 end                                                                          as strategy_decision_reason_code,
       aw.is_parent,
       aw.symbol,
       coalesce(aw.strike_price, 0)                                                             as strike_price,
       aw.type_code,
       case aw.type_code
           when 'P' then '0'
           when 'C' then '1'
           end                                                                                  as put_or_call,
       extract(year from aw.expiration_date::date)                                              as maturuty_year,
       extract(month from aw.expiration_date::date)                                             as maturuty_month,
       extract(day from aw.expiration_date::date)                                               as maturuty_day,
       coalesce(aw.SecurityType, '1')                                                           as security_type,  --?????????????? null in securitytype = 'O'???
       aw.child_orders,
       coalesce(case when aw.orderreportspecialtype = 'M' then lt.id else null end, 0)          as handling,
       0                                                                                        as secondary_order_id2,
       case
           when aw.expiration_date is not null and aw.strike_price is not null then
               replace(coalesce(
                               regexp_replace(coalesce(aw.rootcode, ''), '\.|-', '', 'g') || ' ' ||
                               to_char(aw.expiration_date::date, 'DDMonYY') || ' ' ||
                               staging.trailing_dot(aw.strike_price) ||
                               left(aw.typecode, 8),
                               case
                                   when aw.ord_ContractDesc not like aw.basecode || ' %'
                                       then aw.basecode || ' ' || REPLACE(aw.ord_ContractDesc, aw.BaseCode, '')
                                   when aw.legcount::int = 1 and aw.typecode = 'S' then aw.ord_ContractDesc || ' Stock'
                                   when aw.ord_ContractDesc not like ' %' then aw.ord_ContractDesc || ' '
                                   else aw.ord_ContractDesc end
                       ), '/', '')
           else
               regexp_replace(coalesce(aw.rootcode, ''), '\.|-', '', 'g')
           end                                                                                  as display_instrument_id,
       case
           when aw.expiration_date is not null and aw.strike_price is not null then 'O'
           else 'E' end                                                                         as instrument_type_id,
       regexp_replace(coalesce(aw.basecode, ''), '\.|-', '', 'g')                               as activ_symbol,
       '???'                                                                                    as mapping_logic,
       '???'                                                                                    as commision_rate_unit,
       case when aw.orderreportspecialtype = 'M' then 0 else 1 end                              as is_sor_routed, -- it is assumption
       case
           when lag(cmp.companyname, 1) over (partition by aw.ExchangeTransactionID order by aw.generation) <>
                cmp.companyname
               and lag(aw.OrderID, 1) over (partition by aw.ExchangeTransactionID order by aw.generation) =
                   aw.ParentORdeRID then 1
           else 0
           end                                                                                  as is_company_name_changed,
       cmp.companyname as company_name,
       aw.generation,
       max(aw.generation) over (partition by aw.ExchangeTransactionID)                             mx_gen,
--        aw.order_id,
       aw.parent_order_id,
       case
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) in ('CBOE-CRD NO BK', 'PAR', 'CBOIE')
               then 'XCBO'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) in ('XPAR', 'PLAK', 'PARL') then 'LQPT'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) in ('SOHO', 'KNIGHT', 'LSCI', 'NOM')
               then 'ECUT'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) in ('FOGS', 'MID') then 'XCHI'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) in ('C2', 'CBOE2') then 'C2OX'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) = 'SMARTR' then 'COWEN'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) in ('ACT', 'BOE', 'OTC', 'lp', 'VOL')
               then 'BRKPT'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) in ('XPSE') then 'ARCO'
           when coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) = 'TO' then 'AMXO'
           else coalesce(den1.mic_code, lm.ex_destination, aw.ex_destination) end               as mic_code,
       aw.option_range,
       aw.client_entity_id,
       aw.status,
       coalesce(nullif(aw.liquidityindicator, ''), 'R')                                         as trade_liquidity_indicator,
       order_create_time::timestamp                                                             as order_create_time,
       blaze_account_alias

from --staging.v_away_trade aw
     trash.so_away_trade aw
         LEft join lateral (select *
                            from staging.d_Blaze_Exchange_Codes lm
                            where coalesce(lm.last_mkt, lm.ex_destination) = aw.Ex_Destination
                              and CASE
                                      WHEN aw.SecurityType = '1' THEN 'O'
                                      WHEN aw.SecurityType is null THEN 'O' ---- ????
                                      WHEN aw.SecurityType = '2' THEN 'E'
                                      ELSE aw.SecurityType END = lm.Security_Type
                            limit 1) lm on true

         left join staging.T_Users us on us.user_id = aw.userid::int
         left join lateral (select last_mkt
--                             from staging.dash_exchange_names den
                            from billing.dash_exchange_names den
                            where den.mic_code = coalesce(lm.ex_destination, aw.ex_destination)
--                               and aw.exec_type in ('1', '2', 'r')
                              and den.real_exchange_id = den.exchange_id
                              and den.mic_code != ''
                              and den.is_active
                            limit 1) den on true
         left join lateral (select last_mkt, mic_code
--                             from staging.dash_exchange_names den1
                            from billing.dash_exchange_names den1
                            where den1.exchange_id = coalesce(lm.ex_destination, aw.ex_destination)
--                               and aw.exec_type in ('1', '2', 'r')
                              and den1.real_exchange_id = den1.exchange_id
                              and den1.mic_code != ''
                              and den1.is_active
                            limit 1) den1 on true
         left join staging.d_time_in_force tif on tif.enum = aw.co_time_in_force
--          left join staging.l_time_in_force ltf on tif.id = ltf.code and ltf.systemid = 8
         left join billing.time_in_force ltf on tif.id = ltf.code and ltf.systemid = 8

--          LEFT JOIN staging.l_for_whom lfw on lfw.ShortDesc = aw.option_range and lfw.SystemID = 4
         LEFT JOIN billing.lforwhom lfw on lfw.ShortDesc = aw.option_range and lfw.SystemID = 4
         --          LEFT OUTER JOIN staging.T_Company cmp on us.company_id = cmp.CompanyID and us.System_ID = cmp.SystemID and
--                                                   cmp.EDWActive = 1 -- Company
         LEFT OUTER JOIN billing.tcompany cmp on us.company_id = cmp.CompanyID and us.System_ID = cmp.SystemID and
                                                 cmp.EDWActive = 1::bit -- Company

         left join staging.d_liquidity_type lt on aw.rep_liquidity_type = lt.enum
where true
--   and cl_ord_id in ('1_65240605','1_2b8240605','1_254240617','1_3c6240617','1_16o240626')
--   and order_id in (652865815179165700,
-- 652934019335323648,
-- 657283755907481600,
-- 657302344068759552,
-- 657302260082016256,
-- 660511556445929472
-- )
  and aw.status in ('1', '2');


select 'new',
       left(trade_record_time, 26)::timestamp                                  as trade_record_time,
       db_create_time,
       date_id,
       is_busted,
       subsystem_id,
       client_order_id,
       side,
       openclose                                                               as open_close,
       exec_id,
       trade_liquidity_indicator,
       secondary_order_id2::text,
       exch_exec_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       ex_destination,
       sub_strategy,
       order_id,
       street_order_qty::int4,
       order_qty::int4,
       multileg_reporting_type::char,
       exec_broker,
       cmta,
       street_time_in_force::char,
       contra_broker,
       client_id,
       order_price,
       order_process_time,
       remarks,
       street_client_order_id,
       fix_comp_id,
       leaves_qty::int,
       null::numeric(12, 4)                                                    as street_order_price,
       leg_ref_id::int2,
       strategy_decision_reason_code,
       order_id_guid,
       is_parent,
       symbol,
       strike_price,
       put_or_call,
       maturuty_year,
       maturuty_month,
       maturuty_day,
       security_type,
       child_orders::int4,
       handling,
       secondary_order_id2::text,
       display_instrument_id,
       instrument_type_id,
       activ_symbol,
       mapping_logic,
       commision_rate_unit,
       blaze_account_alias,
       case when is_sor_routed = 0 then false else true end                    as is_sor_routed,
       is_company_name_changed,
       company_name,
       generation::int4,
       mx_gen::int4,
       sum(is_company_name_changed) over (partition by secondary_exch_exec_id) as num_firms,
--        order_id
       ''
from trash.so_missed_lp
where true
  and date_id = 20240809
  and client_order_id = 'b_1_1le240809'

union all

SELECT 'exist',
       trade_record_time,
       db_create_time,
       date_id,
       is_busted,
       subsystem_id,
       client_order_id,
       side,
       open_close,
       exec_id::varchar,
       trade_liquidity_indicator,
       secondary_order_id,
       exch_exec_id,
       secondary_exch_exec_id,
       last_qty,
       last_px,
       ex_destination,
       sub_strategy,
--        street_order_id,
       order_id,
       street_order_qty,
       order_qty,
       multileg_reporting_type,

--       is_largest_leg, street_max_floor,
       exec_broker,
       cmta,
       street_time_in_force,
--        street_order_type, opt_customer_firm, street_mpid,
--        is_cross_order, street_is_cross_order, street_cross_type,
--       cross_is_originator, street_cross_is_originator, contra_account,
       contra_broker,
--       trade_exec_broker, order_fix_message_id, trade_fix_message_id, street_order_fix_message_id,
       client_id,
--       street_transaction_id, transaction_id,
       order_price,
       order_process_time::text,
--       clearing_account_number, sub_account,
       remarks,
--        optional_data,
       street_client_order_id,
       fix_comp_id,
       leaves_qty,
-- is_billed, street_exec_inst, fee_sensitivity,
       street_order_price,
       leg_ref_id,

       --       load_batch_id,
       strategy_decision_reason_code,
--       compliance_id, floor_broker_id,
       order_id_guid,
       is_parent,
       symbol,
--       symbol_sfx,
       strike_price,
       put_or_call,
       maturity_year,
       maturity_month,
       maturity_day,
       security_type,
       child_orders,
       handling_id,
       secondary_order_id2,

       --       ex_destination_for_order_guid, sub_strategy_for_ordg,
       display_instrument_id,
--       trade_record_id,
       instrument_type_id,
       activ_symbol,
       mapping_logic::text,
       commision_rate_unit::text,
       blaze_account_alias,
       is_sor_routed,
--       report_id,
       is_company_name_changed,
       companyname,
       generation,
       mx_gen,
       num_firms,
--        "orderId"
--        , "parentOrderId",
       --        , is_flex_order, last_px_temp
       ''
FROM staging.trade_record_missed_lp
where true
  and date_id = 20240809
  and client_order_id = 'b_1_1le240809'