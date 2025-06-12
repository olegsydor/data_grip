-- DROP FUNCTION dash360.report_fintech_abnus_ecr;
select * from dash360.report_fintech_abnus_ecr(20250603, 20250604)
CREATE FUNCTION dash360.report_fintech_abnus_ecr(in_start_date_id integer DEFAULT NULL::integer,
                                                 in_end_date_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql

AS
$function$
-- SO: 20250612 https://dashfinancial.atlassian.net/browse/DEVREQ-6272 based on dash360.report_ecr
declare
    l_row_cnt     integer;
    l_account_ids int4[];
    l_load_id     integer;
    l_step_id     integer;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_abnus_ecr STARTED===', 0,
                           'O')
    into l_step_id;


    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account ac
    where true
      and ac.trading_firm_id in ('abnus', 'abnnv');


    return query
        select 'Date,Account,Client ID,Cl Ord ID,Security Type,Strategy,OSI Symbol,Symbol,Side,Exec Qty,Avg Px,Principal Amount,Execution Cost,Execution Cost/Unit,DashCommission,Maker/Taker Fee,Transaction Fee';

    return query
        select array_to_string(ARRAY [to_char(ft.trade_record_time, 'MM/DD/YY') , -- as "Date",
                                   acc.ACCOUNT_NAME , -- as "Account",
                                   ft.CLIENT_ID, -- as "ClientID",
                                   ft.client_order_id , -- as "ClOrdID",
                                   case when i.INSTRUMENT_TYPE_ID = 'E' then 'Equuity' else 'Option' end, -- as "SecurityType",
                                   COALESCE(replace(ed.EX_DESTINATION_CODE_NAME, 'LiquidPoint', 'DASH'),
                                            upper(coalesce(bsn.bloomberg_strategy_name, ft.sub_strategy)))::varchar , -- as "Strategy",
                                   OC.OPRA_SYMBOL , -- as "OSISymbol",
                                   I.DISPLAY_INSTRUMENT_ID , -- as "Symbol",
                                   case when ft.SIDE in ('2', '5') then 'Sell' else 'Sell' end , -- as "Side",
                                   sum(last_qty)::text , -- as "ExecQty",
                                   ROUND(sum(last_qty * last_px) / NULLIF(sum(last_qty), 0), 4)::text , -- as "AvgPx",
                                   sum(ft.principal_amount)::text , -- as "PrincipalAmount",
                                   sum(ft.tcce_account_execution_cost)::text , -- as "Execution Cost",
                                   round(sum(ft.tcce_account_execution_cost) / nullif(sum(last_qty), 0),
                                         4)::text, -- as "Execution Cost/Unit",
                                   0::text , -- as "DashCommission",
                                   sum(ft.tcce_maker_taker_fee_amount)::text , -- as "Maker/Taker Fee",
                                   sum(ft.tcce_transaction_fee_amount)::text -- as "Transaction Fee"
                                   ], ',', '')
        from flat_trade_record ft
                 inner join d_instrument i on (ft.instrument_id = i.instrument_id)

                 left join dwh.client_order fm on (ft.order_id = fm.order_id and
                                                   fm.create_date_id between in_start_date_id and in_end_date_id)
                 left join dwh.d_bloomberg_strategy_name bsn on (ft.trading_firm_id = bsn.trading_firm_id and
                                                                 ft.sub_strategy =
                                                                 bsn.original_sub_strategy and
                                                                 coalesce(fm.aggression_level, -1) =
                                                                 coalesce(bsn.aggression_level, -1))
                 left join d_option_contract oc on (ft.instrument_id = oc.instrument_id)
                 inner join d_account acc on (ft.account_id = acc.account_id)
                 left join d_ex_destination_code ed
                           on coalesce(upper(bsn.bloomberg_strategy_name), upper(ft.sub_strategy), 'DMA') = 'DMA' and
                              ed.is_active = true and
                              ed.ex_destination_code = ft.ex_destination
        where date_id between in_start_date_id and in_end_date_id
          and ft.account_id = any (l_account_ids)
          and is_busted = 'N'
        group by
-- ft.order_id,
ft.client_order_id,
ft.side,
-- ft.instrument_id,
to_char(ft.trade_record_time, 'MM/DD/YY'),
ft.account_id,
-- ft.trading_firm_id,
ft.client_id,
i.display_instrument_id,
i.instrument_type_id,
ft.sub_strategy,
-- ft.ex_destination,
bsn.bloomberg_strategy_name,
acc.account_name,
ed.ex_destination_code_name,
oc.opra_symbol
        order by to_char(ft.trade_record_time, 'MM/DD/YY'), i.display_instrument_id;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_abnus_ecr COMPLETED===', l_row_cnt,
                           'O')
    into l_step_id;
end;
$function$
;

select * from dwh.client_order
where client_order_id = 'UTR8_NYA3abd5c3qi0ld'

select array_to_string(ARRAY [to_char(ft.trade_record_time, 'MM/DD/YY') , -- as "Date",
                           acc.ACCOUNT_NAME , -- as "Account",
                           ft.CLIENT_ID, -- as "ClientID",
                           ft.client_order_id , -- as "ClOrdID",
                           case when i.INSTRUMENT_TYPE_ID = 'E' then 'Equuity' else 'Option' end, -- as "SecurityType",
                           COALESCE(replace(ed.EX_DESTINATION_CODE_NAME, 'LiquidPoint', 'DASH'),
                                    upper(coalesce(bsn.bloomberg_strategy_name, ft.sub_strategy)))::varchar , -- as "Strategy",
                           OC.OPRA_SYMBOL , -- as "OSISymbol",
                           I.DISPLAY_INSTRUMENT_ID , -- as "Symbol",
                           case when ft.SIDE in ('2', '5') then 'Sell' else 'Sell' end , -- as "Side",
                           sum(last_qty)::text , -- as "ExecQty",
                           ROUND(sum(last_qty * last_px) / NULLIF(sum(last_qty), 0), 4)::text , -- as "AvgPx",
                           sum(ft.principal_amount)::text , -- as "PrincipalAmount",
                           sum(ft.tcce_account_execution_cost)::text , -- as "Execution Cost",
                           round(sum(ft.tcce_account_execution_cost) / nullif(sum(last_qty), 0),
                                 4)::text, -- as "Execution Cost/Unit",
                           0::text , -- as "DashCommission",
                           sum(ft.tcce_maker_taker_fee_amount)::text , -- as "Maker/Taker Fee",
                           sum(ft.tcce_transaction_fee_amount)::text -- as "Transaction Fee"
                           ], ',', '')
from flat_trade_record ft
         inner join d_instrument i on (ft.instrument_id = i.instrument_id)
         left join dwh.client_order fm on (ft.order_id = fm.order_id and
                                           fm.create_date_id between :in_start_date_id and :in_end_date_id)
         left join dwh.d_bloomberg_strategy_name bsn on (ft.trading_firm_id = bsn.trading_firm_id and
                                                         ft.sub_strategy =
                                                         bsn.original_sub_strategy and
                                                         coalesce(fm.aggression_level, -1) =
                                                         coalesce(bsn.aggression_level, -1))
         left join d_option_contract oc on (ft.instrument_id = oc.instrument_id)
         inner join d_account acc on (ft.account_id = acc.account_id)
         left join d_ex_destination_code ed
                   on coalesce(upper(bsn.bloomberg_strategy_name), upper(ft.sub_strategy), 'DMA') = 'DMA' and
                      ed.is_active = true and
                      ed.ex_destination_code = ft.ex_destination
where date_id between :in_start_date_id and :in_end_date_id
  and ft.account_id = any (:l_account_ids)
  and is_busted = 'N'
group by
-- ft.order_id,
ft.client_order_id,
ft.side,
-- ft.instrument_id,
to_char(ft.trade_record_time, 'MM/DD/YY') ,
ft.account_id,
-- ft.trading_firm_id,
ft.client_id,
i.display_instrument_id,
i.instrument_type_id,
ft.sub_strategy,
-- ft.ex_destination,
bsn.bloomberg_strategy_name,
acc.account_name,
ed.ex_destination_code_name,
oc.opra_symbol
order by ft.trade_record_time::date, i.display_instrument_id
