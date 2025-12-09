-- DROP FUNCTION dash360.report_fintech_adh_allocation_xls(int4, int4, _int4, bpchar, _varchar, _varchar, bpchar);
select * from trash.report_fintech_adh_allocation_xls(in_start_date_id := 20251208, in_end_date_id := 20251208, in_account_ids := '{11806,2928}')


CREATE FUNCTION trash.report_fintech_adh_allocation_xls(in_start_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                        in_end_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                        in_account_ids integer[] DEFAULT '{}'::integer[],
                                                        in_instrument_type character DEFAULT NULL::bpchar,
                                                        in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                        in_occ_actionable_id character varying[] DEFAULT '{}'::character varying[],
                                                        in_include_all character DEFAULT 'N'::bpchar)
    RETURNS TABLE
            (
                "Trading Firm"         character varying,
                "Account"              character varying,
                "Date"                 text,
                "OCC AID"              character varying,
                "Clearing Account"     character varying,
                "Account Nickname"     character varying,
                "Settlement Date"      character varying,
                "Alloc ID"             integer,
                "Allocated By"         character varying,
                "Alloc Time"           text,
                "Sec Type"             text,
                "Symbol"               character varying,
                "Side"                 text,
                "O/C"                  text,
                "Exec Qty"             bigint,
                "Avg Px"               numeric,
                "Alloc Qty"            bigint,
                "Principal Amount"     numeric,
                "CMTA"                 character varying,
                "OSI Symbol"           character varying,
                "Root Symbol"          character varying,
                "Expiration"           text,
                "Put/Call"             text,
                "Strike"               numeric,
                "Commission"           numeric,
                "Execution Cost"       numeric,
                "Maker/Taker Fee"      numeric,
                "Transaction Fee"      numeric,
                "Trade Processing Fee" numeric,
                "Royalty Fee"          numeric,
                "Client Commission"    numeric
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2024-04-18 SO: https://dashfinancial.atlassian.net/browse/DS-8251 added in_trading_firm_ids as an input parameter
    -- SO 20240523 https://dashfinancial.atlassian.net/browse/DEVREQ-4264 add coalesce to account\trading firm input parameters
    -- VP 20240802 https://dashfinancial.atlassian.net/browse/DS-8678 Add new filter by OCC AID array
    -- AK 20241121 https://dashfinancial.atlassian.net/browse/DS-9086 added new column to return table Client Commission
    -- OS 20251105 https://dashfinancial.atlassian.net/browse/DEVREQ-7052 PTA only|All trades
    -- OS 20251209 https://dashfinancial.atlassian.net/browse/DEVREQ-6944 Add "Account Nickname" field

declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_allocation_xls for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;
    return query
        with ftr as (select tr.date_id,
                            tr.trade_record_time::date                                  as trade_record_time,
                            tr.instrument_type_id,
                            sum(tr.last_qty)                                            as sum_last_qty,
                            sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
                            tr.open_close,
                            --tr.order_id,
                            tr.instrument_id,
                            tr.account_id,
                            tr.side,
                            tr.cmta,
                            at.alloc_qty                                                as alloc_qty,
                            at.alloc_instr_id                                           as alloc_instr_id,
                            at.clearing_account_id                                      as clearing_account_id,
                            sum(coalesce(tr.tcce_maker_taker_fee_amount, 0.0))          as tcce_maker_taker_fee_amount,
                            sum(coalesce(tr.tcce_account_dash_commission_amount, 0.0))  as tcce_account_dash_commission_amount, --
                            sum(coalesce(tr.tcce_transaction_fee_amount, 0.0))          as tcce_transaction_fee_amount,
                            sum(coalesce(tr.tcce_trade_processing_fee_amount, 0.0))     as tcce_trade_processing_fee_amount,
                            sum(coalesce(tr.tcce_royalty_fee_amount, 0.0))              as tcce_royalty_fee_amount,
                            sum(tr.principal_amount)                                    as principal_amount,
                            sum(coalesce(tr.tcce_account_execution_cost, 0.0))          as tcce_account_execution_cost,
                            sum(coalesce(tr.client_commission_rate, 0.0) * tr.last_qty) as client_commission_rate_sum,
                            tr.street_account_name,
                            tr.account_nickname
                     from dwh.flat_trade_record tr
                              join dwh.d_account acc on (acc.account_id = tr.account_id and acc.is_active)
                              left join lateral (select atr.trade_record_id,
                                                        atr.alloc_qty,
                                                        atr.alloc_instr_id,
                                                        atr.clearing_account_id
                                                 from dwh.allocation2trade_record atr
                                                 where atr.trade_record_id = tr.trade_record_id
                                                   and atr.date_id = tr.date_id
                                                   and atr.is_active
                                                 limit 1) at on true
                     where tr.date_id between in_start_date_id and in_end_date_id
                       and is_busted = 'N'
                       --and tr.order_id > 0
                       and case
                               when coalesce(in_account_ids, '{}') = '{}' then true
                               else acc.account_id = any (in_account_ids) end
                       and case
                               when coalesce(in_trading_firm_ids, '{}') = '{}' then true
                               else acc.trading_firm_id = any (in_trading_firm_ids) end
                       and case
                               when in_instrument_type is null then true
                               else tr.instrument_type_id = in_instrument_type end
                       and case when in_include_all = 'N' then at.trade_record_id is not null else true end
                     group by tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, tr.cmta,
                              at.alloc_qty, tr.trade_record_time::date,
                              tr.instrument_type_id, at.alloc_instr_id, at.clearing_account_id, tr.street_account_name,
                              tr.account_nickname)
           , pre_base as (select ftr.alloc_instr_id, sum(client_commission_rate_sum) as client_commission_rate_sum
                          from ftr
                          group by ftr.alloc_instr_id)
           , base as (select tf.trading_firm_name                                as "Trading Firm",
                             ac.account_name                                     as "Account",
                             to_char(ftr.trade_record_time, 'MM/DD/YYYY')        as "Date",
                             to_char(public.get_settle_date_by_instrument_type(ftr.trade_record_time::date,
                                                                               ftr.instrument_type_id),
                                     'MM/DD/YYYY')::varchar                      as "Settlement Date",
                             ftr.alloc_instr_id                                  as "Alloc ID",
                             ftr.clearing_account_id                             as "Clearing Account ID",
                             case
                                 when ftr.instrument_type_id = 'E' then 'Equity'
                                 when ftr.instrument_type_id = 'O' then 'Option'
                                 end                                             as "Sec Type",
                             hsd.display_instrument_id                           as "Symbol",
                             case
                                 when ftr.side = '1' then 'Buy'
                                 when ftr.side = '2' then 'Sell'
                                 when ftr.side in ('5', '6') then 'Sell Short'
                                 else ''
                                 end                                             as "Side",
                             case
                                 when ftr.open_close = 'O' then 'Open'
                                 when ftr.open_close = 'C' then 'Close'
                                 else '' end                                     as "O/C",
                             ftr.sum_last_qty                                    as "Exec Qty",
                             round(ftr.avg_px, 4)                                as "Avg Px",
                             coalesce(ftr.alloc_qty, ftr.sum_last_qty)           as "Alloc Qty",
                             ftr.principal_amount                                as "Principal Amount",
                             ftr.cmta                                            as "CMTA",
                             coalesce(hsd.opra_symbol, hsd.symbol)               as "OSI Symbol",
                             hsd.underlying_symbol                               as "Root Symbol",
                             to_char(hsd.maturity_date, 'MM/DD/YYYY')            as "Expiration",
                             case
                                 when hsd.put_call = '0' then 'Put'
                                 when hsd.put_call = '1' then 'Call'
                                 else ''
                                 end                                             as "Put/Call",
                             hsd.strike_px                                       as "Strike",
                             round(ftr.tcce_account_dash_commission_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                            as "Commission",
                             round(ftr.tcce_account_execution_cost / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty), 6) as "Execution Cost",
                             round(ftr.tcce_maker_taker_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                            as "Maker/Taker Fee",
                             round(ftr.tcce_transaction_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                            as "Transaction Fee",
                             round(ftr.tcce_trade_processing_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                            as "Trade Processing Fee",
                             round(ftr.tcce_royalty_fee_amount / ftr.sum_last_qty *
                                   coalesce(ftr.alloc_qty, ftr.sum_last_qty),
                                   6)                                            as "Royalty Fee",
                             --round(ftr.alloc_qty / ftr.sum_last_qty *
                             --      client_commission ,6 )	  			  as "Client Commission"
                             pre_base.client_commission_rate_sum,
                             ftr.street_account_name,
                             ftr.client_commission_rate_sum                      as ftr_client_commission_rate_sum,
                             ftr.account_nickname
                      from ftr
                               join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
                               join dwh.d_account ac on ac.account_id = ftr.account_id
                               join dwh.d_trading_firm tf on tf.trading_firm_unq_id = ac.trading_firm_unq_id
                               join dwh.historic_security_definition_all hsd on (hsd.instrument_id = ftr.instrument_id)
                               left join pre_base on ftr.alloc_instr_id = pre_base.alloc_instr_id)
           , aie as (select *
                     from staging.allocation_instruction_entry
                     where date_id between in_start_date_id and in_end_date_id
                     order by alloc_instr_id)
        select base."Trading Firm",
               base."Account",
               base."Date",
               coalesce(aie.occ_actionable_id, base.street_account_name) as "OCC AID",
               coalesce(ca.clearing_account_number, base."CMTA")         as "Clearing Account",
               base.account_nickname                                     as "Account Nickname",
               base."Settlement Date",
               base."Alloc ID",
               case
                   when ai.created_by_subsystem_id = 'RPS' then 'auto'
                   else ui.user_name
                   end                                                   as "Allocated By",
               to_char(ai.create_time, 'HH24:MI:SS.US')                  as "Alloc Time",
               base."Sec Type",
               base."Symbol",
               base."Side",
               base."O/C",
               --base."Exec Qty",
--               (case when in_include_all = 'Y' then base."Exec Qty" else ai.total_qty end)::bigint as "Exec Qty",
               coalesce(ai.total_qty, base."Exec Qty")                   as "Exec Qty",
               base."Avg Px",
               base."Alloc Qty",
               base."Principal Amount",
               base."CMTA",
               base."OSI Symbol",
               base."Root Symbol",
               base."Expiration",
               base."Put/Call",
               base."Strike",
               base."Commission",
               base."Execution Cost",
               base."Maker/Taker Fee",
               base."Transaction Fee",
               base."Trade Processing Fee",
               base."Royalty Fee",
               --base."Client Commission"
--               (aie.alloc_qty * 1.0 / ai.total_qty * client_commission_rate_sum)::numeric          as "Client Commission",
               coalesce(
                       (aie.alloc_qty * 1.0 / ai.total_qty * client_commission_rate_sum)::numeric,
                       ftr_client_commission_rate_sum)                   as "Client Commission"
        from base
                 left join lateral (select *
                                    from staging.allocation_instruction ai
                                    where ai.alloc_instr_id = base."Alloc ID"
                                      and ai.date_id between in_start_date_id and in_end_date_id
                                      and ai.is_deleted = 'N'
                                    limit 1) ai on true
                 left join aie on (aie.alloc_instr_id = base."Alloc ID" and
                                   aie.clearing_account_id = base."Clearing Account ID" and aie.date_id = ai.date_id)
                 left join dwh.d_user_identifier ui on (ui.user_id = ai.created_by_user_id)
                 left join dwh.d_clearing_account ca
                           on (ca.clearing_account_id = aie.clearing_account_id)
        where case
                  when coalesce(in_occ_actionable_id, '{}') = '{}' then true
                  else aie.occ_actionable_id = any (in_occ_actionable_id) end
        order by base."Date", base."Trading Firm", base."Account", base."Symbol", base."Side";
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_allocation_xls for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;



select tr.date_id,
       tr.trade_record_time::date                                  as trade_record_time,
       tr.instrument_type_id,
       sum(tr.last_qty)                                            as sum_last_qty,
       sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0) as avg_px,
       tr.open_close,
       --tr.order_id,
       tr.instrument_id,
       tr.account_id,
       tr.side,
       tr.cmta,
       at.alloc_qty                                                as alloc_qty,
       at.alloc_instr_id                                           as alloc_instr_id,
       at.clearing_account_id                                      as clearing_account_id,
       sum(coalesce(tr.tcce_maker_taker_fee_amount, 0.0))          as tcce_maker_taker_fee_amount,
       sum(coalesce(tr.tcce_account_dash_commission_amount, 0.0))  as tcce_account_dash_commission_amount, --
       sum(coalesce(tr.tcce_transaction_fee_amount, 0.0))          as tcce_transaction_fee_amount,
       sum(coalesce(tr.tcce_trade_processing_fee_amount, 0.0))     as tcce_trade_processing_fee_amount,
       sum(coalesce(tr.tcce_royalty_fee_amount, 0.0))              as tcce_royalty_fee_amount,
       sum(tr.principal_amount)                                    as principal_amount,
       sum(coalesce(tr.tcce_account_execution_cost, 0.0))          as tcce_account_execution_cost,
       sum(coalesce(tr.client_commission_rate, 0.0) * tr.last_qty) as client_commission_rate_sum,
       tr.street_account_name,
       tr.account_nickname
from dwh.flat_trade_record tr
         join dwh.d_account acc on (acc.account_id = tr.account_id and acc.is_active)
         left join lateral (select atr.trade_record_id,
                                   atr.alloc_qty,
                                   atr.alloc_instr_id,
                                   atr.clearing_account_id
                            from dwh.allocation2trade_record atr
                            where atr.trade_record_id = tr.trade_record_id
                              and atr.date_id = tr.date_id
                              and atr.is_active
                            limit 1) at on true
where tr.date_id between :in_start_date_id and :in_end_date_id
  and is_busted = 'N'
and tr.account_nickname is not null
group by tr.date_id, tr.open_close, tr.instrument_id, tr.account_id, tr.side, tr.cmta,
         at.alloc_qty, tr.trade_record_time::date,
         tr.instrument_type_id, at.alloc_instr_id, at.clearing_account_id, tr.street_account_name,
         tr.account_nickname