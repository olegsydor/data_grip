-- DROP FUNCTION dash360.report_ecr(int4, int4, _varchar, _int8, varchar, varchar, varchar, int4, bpchar, bpchar, _varchar, bpchar);

CREATE OR REPLACE FUNCTION dash360.report_fintech_abnus_ecr(in_start_date_id integer DEFAULT NULL::integer,
                                                            in_end_date_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
--                 "Date"                     date,
--                 "Account"                  character varying,
--                 "wbAccount"                character varying,
--                 "ClOrdID"                  character varying,
--                 "ClientID"                 character varying,
--                 "SecurityType"             character,
--                 "SubStrategy"              character varying,
--                 "OSISymbol"                character varying,
--                 "Symbol"                   character varying,
--                 "Side"                     character,
--                 "ExecQty"                  bigint,
--                 "AvgPx"                    numeric,
--                 "PrincipalAmount"          numeric,
--                 "ExecCost"                 numeric,
--                 "DashCommissionAmount"     numeric,
--                 "MakerTakerFeeAmount"      numeric,
--                 "TransactionFeeAmount"     numeric,
--                 "TradeProcessingFeeAmount" numeric,
--                 "RoyaltyFeeAmount"         numeric,
--                 "MaturityYear"             smallint,
--                 "MaturityMonth"            smallint,
--                 "MaturityDay"              smallint
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
l_comm_mode bpchar := '1'
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
and ac.trading_firm_id in ('abnus', 'abnnv')


    return query
        select 'Date,Account,Client ID,Cl Ord ID,Security Type,Strategy,OSI Symbol,Symbol,Side,Exec Qty,Avg Px,Principal Amount,Execution Cost,Execution Cost/Unit,DashCommission,Maker/Taker Fee,Transaction Fee';




SELECT "Date",
coalesce(ano.overriden_account_name, acc.ACCOUNT_NAME)   as "Account",
                 "ClientID",
               "ClOrdID",
               "SecurityType",
               --, "SubStrategy"
               COALESCE(replace(ed.EX_DESTINATION_CODE_NAME, 'LiquidPoint', 'DASH'), L1."SubStrategy")::varchar as "Strategy",
                OC.OPRA_SYMBOL                 AS "OSISymbol",
               "Symbol",
               "Side",
               "ExecQty",
               "AvgPx",
               "PrincipalAmount",
               case l_comm_mode
                   when '1' then coalesce("MakerTakerFeeAmount", 0.0) + coalesce("TransactionFeeAmount", 0.0) + coalesce("TradeProcessingFeeAmount", 0.0) + coalesce("RoyaltyFeeAmount", 0.0)
                   else "ExecCost"
                 end as "ExecCost",
    0 as "DashCommissionAmount",
                "MakerTakerFeeAmount",
                "TransactionFeeAmount",
                "TradeProcessingFeeAmount",
               "RoyaltyFeeAmount",
                OC.MATURITY_YEAR   as "MaturityYear",
                OC.MATURITY_MONTH  as "MaturityMonth",
                OC.MATURITY_DAY    as "MaturityDay"
           FROM (


    select ft.order_id,
           ft.client_order_id as "ClOrdID",
                 ft.SIDE           as  "Side",
                 ft.INSTRUMENT_ID,
                 ft.trade_record_time::date as "Date",
                 ft.ACCOUNT_ID,
                 ft.TRADING_FIRM_ID,
                 coalesce (cno.overriden_client_name, ft.CLIENT_ID)        as "ClientID",
                 i.INSTRUMENT_TYPE_ID    as "SecurityType",
                 I.DISPLAY_INSTRUMENT_ID   AS "Symbol",
                --, ft.sub_strategy       as "SubStrategy"
                upper(coalesce(bsn.bloomberg_strategy_name, ft.sub_strategy))::character varying        as "SubStrategy",
                 ft.ex_destination,
                 sum(last_qty)                   as "ExecQty",
                 ROUND(sum(last_qty * last_px) / NULLIF(sum(last_qty),0),4)::numeric as "AvgPx",
                 0                     as BUSTED_EXEC_QTY,
                 sum(ft.principal_amount)          as "PrincipalAmount",
                 sum(ft.tcce_account_execution_cost )      as "ExecCost",
                 sum(ft.tcce_account_dash_commission_amount) as "DashCommissionAmount",
                 sum(ft.tcce_maker_taker_fee_amount)     AS  "MakerTakerFeeAmount",
        		 sum(ft.tcce_transaction_fee_amount)     AS "TransactionFeeAmount",
        		 sum(ft.tcce_trade_processing_fee_amount)  AS "TradeProcessingFeeAmount",
                 sum(ft.tcce_royalty_fee_amount)  AS "RoyaltyFeeAmount"
    from flat_trade_record ft
    inner join d_instrument i on (ft.instrument_id = i.instrument_id)
        left join dwh.d_client_name_override cno on (ft.trading_firm_id = cno.trading_firm_id and coalesce(ft.client_id, '-1') = coalesce(cno.original_client_name, '-1'))
        left join dwh.client_order fm on (ft.order_id = fm.order_id and fm.create_date_id between in_start_date_id and in_end_date_id)
        left join dwh.d_bloomberg_strategy_name bsn on (ft.trading_firm_id = bsn.trading_firm_id and ft.sub_strategy = bsn.original_sub_strategy and coalesce(fm.aggression_level, -1) = coalesce(bsn.aggression_level, -1))
    where date_id between in_start_date_id and in_end_date_id
      and 
    and is_busted='N'
              group by ft.order_id,
         ft.client_order_id,
                 ft.SIDE,
                 ft.INSTRUMENT_ID,
                 ft.trade_record_time::date ,
                 ft.ACCOUNT_ID,
                 ft.TRADING_FIRM_ID,
                 coalesce (cno.overriden_client_name, ft.CLIENT_ID),
                 I.DISPLAY_INSTRUMENT_ID,
                 i.INSTRUMENT_TYPE_ID,
                 ft.sub_strategy,
                 ft.ex_destination,
                 bsn.bloomberg_strategy_name
        ) L1
    left join d_option_contract oc on (L1.instrument_id = oc.instrument_id)
    inner join d_account acc on (L1.account_id = acc.account_id)
    left join dwh.d_account_name_override ano on (acc.account_id = ano.account_id)
    left join d_ex_destination_code ed on COALESCE(L1."SubStrategy", 'DMA') = 'DMA' and ed.is_active = true AND ed.ex_destination_code = L1.ex_destination
        order by "Date", "Symbol"
    ;

end;
$function$
;
