'{28549,20505,19993,38549,30213,64810,64809,12410,64808,12909}';

select * from dash360.report_rps_wellsfarg_orders(in_start_date_id := 20231109, in_end_date_id := 20231109,
                                                   in_account_ids := '{28549,20505,19993,38549,30213,64810,64809,12410,64808,12909}');

create or replace function dash360.report_rps_wellsfarg_orders(in_start_date_id int4, in_end_date_id int4,
                                                   in_account_ids int4[] default '{}')
    RETURNs table
            (
                ret_row text
            )
    language plpgsql
as
$$
begin
    return query
        select 'Date,Account,Client ID,Cl Ord ID,Orig Cl Ord ID,Side,Symbol,Symbol Sfx,Security Type,TIF,Ord Type,Exec Qty,Avg Px,Root Symbol,Underlying Symbol,' ||
               'Is Mleg,Leg Ref ID,Ex Dest,Sub Strategy,Expiration Day,MPID,Capacity,Exec Broker,O/C,Principal Amount,Maker/Taker Fee,M/T Fee/Unit,' ||
               'Transaction Fee,Trade Processing Fee,Royalty Fee,Option Regulatory Fee,OCC Fee,SEC Fee,Dash Commission Account,Execution Cost Account,' ||
               'Exec Cost/Unit Account,Dash Commission Firm,Execution Cost Firm,Exec Cost/Unit Firm,OSI Symbol,Sending Firm,Trading Firm';

    return query
        SELECT to_char(cl.create_time, 'MM/DD/YYYY') || ',' ||
               AC.ACCOUNT_NAME || ',' ||
               coalesce(CL.CLIENT_ID_text::text, '') || ',' ||
               CL.CLIENT_ORDER_ID || ',' ||
               coalesce(ORIG.CLIENT_ORDER_ID, '') || ',' ||
               case CL.SIDE when '2' then 'SLD' when '5' then 'SLD SHORT' when '6' then 'SLD SHORT' else 'BOT' end ||
               ',' ||
               coalesce(I.DISPLAY_INSTRUMENT_ID, '') || ',' ||
               coalesce(I.SYMBOL_SUFFIX, '') || ',' ||
               case I.INSTRUMENT_TYPE_ID when 'O' then 'Option' else 'Equity' end || ',' ||
               TIF.TIF_NAME || ',' ||
               OT.ORDER_TYPE_SHORT_NAME || ',' ||
               DS.DAY_CUM_QTY || ',' ||
               to_char(round(DS.DAY_AVG_PX, 4), 'FM9999990.0000') || ',' ||
               coalesce(OS.ROOT_SYMBOL, I.SYMBOL) || ',' ||
               coalesce(UI.SYMBOL, I.SYMBOL) || ',' ||
               case CL.MULTILEG_REPORTING_TYPE when '1' then 'N' else 'Y' end || ',' ||
               coalesce(OL.CLIENT_LEG_REF_ID, '') || ',' ||
               EXC.EX_DESTINATION_CODE_NAME || ',' ||
               CL.sub_strategy_desc || ',' ||
               case
                   when I.INSTRUMENT_TYPE_ID = 'O'
                       then
                                       to_char(OC.MATURITY_MONTH, 'FM00') || '/' || to_char(OC.MATURITY_DAY, 'FM00') ||
                                       '/' || substr(OC.MATURITY_YEAR::text, 3)
                   else
                       ''
                   end || ',' ||

--              ac.mpid || ',' ||
               'DASH' || ',' ||
               CF.CUSTOMER_OR_FIRM_NAME || ',' ||
               case AC.OPT_IS_FIX_EXECBROK_PROCESSED
                   when 'Y' then coalesce(CL.OPT_EXEC_BROKER_id::text, OPX.OPT_EXEC_BROKER)
                   else OPX.OPT_EXEC_BROKER end || ',' ||
-- !!!!! CL.OPT_EXEC_BROKER_id maye should be joined to dwh.d_opt_exec_broker
               case CL.OPEN_CLOSE when 'O' then 'Open' when 'C' then 'Close' else '' end || ',' ||
               to_char(round(ds.day_cum_qty * ds.day_avg_px * coalesce(os.contract_multiplier, 1), 4),
                       'FM9999999990.0000') || ',' ||
               coalesce(to_char(round(ftr.maker_taker_fee_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.maker_taker_fee_amount / nullif(ds.day_cum_qty, 0), 4), 'FM9999999990.0000'),
                        '') || ',' ||
               coalesce(to_char(round(ftr.transaction_fee_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.trade_processing_fee_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.royalty_fee_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.option_regulatory_fee_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.occ_fee_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.sec_fee_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.account_dash_commission_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.account_execution_cost, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.account_execution_cost / nullif(ds.day_cum_qty, 0), 4), 'FM9999999990.0000'),
                        '') || ',' ||
               coalesce(to_char(round(ftr.firm_dash_commission_amount, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.firm_execution_cost, 4), 'FM9999999990.0000'), '') || ',' ||
               coalesce(to_char(round(ftr.firm_execution_cost / nullif(ds.day_cum_qty, 0), 4), 'FM9999999990.0000'),
                        '') || ',' ||
               coalesce(OC.OPRA_SYMBOL, '') || ',' ||
               coalesce(FC.FIX_COMP_ID, '') || ',' ||
               coalesce(TF.TRADING_FIRM_NAME, '')
                   as rec
        from dwh.client_order cl
                 join (select order_id, create_date_id
                       from dwh.client_order co
                       where create_date_id between in_start_date_id and in_end_date_id
                         and co.account_id = any (in_account_ids)
                       union all
                       select order_id, create_date_id
                       from dwh.gtc_order_status
                       where create_date_id <= in_start_date_id
                         and account_id = any (in_account_ids)
                         and close_date_id is null
                       union all
                       select order_id, create_date_id
                       from dwh.gtc_order_status
                       where create_date_id <= in_start_date_id
                         and account_id = any (in_account_ids)
                         and close_date_id >= in_start_date_id) x
                      on x.create_date_id = cl.create_date_id and x.order_id = cl.order_id
                 inner join lateral
            (select ex.order_id,
                    sum(ex.last_qty * ex.last_px) / nullif(sum(ex.last_qty), 0) day_avg_px,
                    sum(ex.last_qty)                                            day_cum_qty,
                    sum(ex.last_qty * ex.last_px)                               principal
             from execution ex
             where ex.order_id = cl.order_id
               and ex.exec_type in ('F', 'G')
               and ex.is_busted <> 'Y'
               and ex.exec_date_id between in_start_date_id and in_end_date_id
             group by ex.order_id
             limit 1
            ) ds on true
                 join dwh.mv_active_account_snapshot ac on ac.account_id = cl.account_id and ac.is_active
                 left join dwh.client_order orig on (orig.order_id = cl.orig_order_id)
                 inner join dwh.d_fix_connection fc on (cl.fix_connection_id = fc.fix_connection_id and fc.is_active)
                 inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
                 inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                 inner join dwh.d_time_in_force tif on (tif.tif_id = cl.time_in_force_id)
                 inner join dwh.d_ORDER_TYPE OT on (OT.ORDER_TYPE_ID = CL.ORDER_TYPE_id)
                 inner join dwh.d_EX_DESTINATION_CODE EXC on (EXC.EX_DESTINATION_CODE = CL.EX_DESTINATION)
                 left join dwh.d_OPTION_CONTRACT OC on OC.INSTRUMENT_ID = I.INSTRUMENT_ID
                 left join dwh.d_OPTION_SERIES OS on (OC.OPTION_SERIES_ID = OS.OPTION_SERIES_ID)
                 left join dwh.d_INSTRUMENT UI on (OS.UNDERLYING_INSTRUMENT_ID = UI.INSTRUMENT_ID)
                 left join dwh.client_order_leg ol on (ol.order_id = cl.order_id)
                 left join dwh.d_opt_exec_broker opx
                           on (opx.account_id = cl.account_id and opx.is_active and opx.is_default = 'Y')
                 left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = cl.customer_or_firm_id)

                 left join lateral (
            select sum(tr.tcce_maker_taker_fee_amount)         as maker_taker_fee_amount,
                   sum(tr.tcce_transaction_fee_amount)         as transaction_fee_amount,
                   sum(tr.tcce_trade_processing_fee_amount)    as trade_processing_fee_amount,
                   sum(tr.tcce_royalty_fee_amount)             as royalty_fee_amount,
                   sum(tr.tcce_option_regulatory_fee_amount)   as option_regulatory_fee_amount,
                   sum(tr.tcce_occ_fee_amount)                 as occ_fee_amount,
                   sum(tr.tcce_sec_fee_amount)                 as sec_fee_amount,
                   sum(tr.tcce_account_dash_commission_amount) as account_dash_commission_amount,
                   sum(tr.tcce_account_execution_cost)         as account_execution_cost,
                   sum(tr.tcce_firm_dash_commission_amount)    as firm_dash_commission_amount,
                   sum(tr.tcce_firm_execution_cost)            as firm_execution_cost

            from dwh.flat_trade_record tr
            where tr.order_id = cl.order_id
              and tr.date_id = cl.create_date_id
            limit 1
            ) ftr on true

        where true
          and cl.parent_order_id is null;
end;
$$;


select * from dwh.d_exec_type


select ftr.order_id, *--count(*)
from dwh.flat_trade_record ftr
join dwh.d_account ac on ac.account_id = ftr.account_id

--          inner join dwh.d_fix_connection fc on (ftr.fix_connection_id = fc.fix_connection_id and fc.is_active)
--       inner join dwh.d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
--       inner join dwh.d_instrument i on i.instrument_id = ftr.instrument_id
--       inner join dwh.d_time_in_force tif on (tif.tif_id = ftr.street_time_in_force)
--       inner join dwh.d_ORDER_TYPE OT on (OT.ORDER_TYPE_ID =ftr.street_order_type)
--       inner join dwh.d_EX_DESTINATION_CODE EXC on (EXC.EX_DESTINATION_CODE = ftr.EX_DESTINATION)

where true
--     and ftr.date_id = 20231109
  and ftr.order_id = 13664306595
and ac.trading_firm_id = 'wellsfarg'
group by ftr.order_id;


select *
FROM dwh.EXECUTION EX
WHERE 1 = 1
--   and EX.EXEC_TYPE IN ('F', 'G')
  AND EX.IS_BUSTED <> 'Y'
  and EX.EXEC_TIME::date = '2023-11-09'
  and ex.ORDER_ID = 13664305271;


SELECT order_id,
                  SUM(EX.LAST_QTY*EX.LAST_PX)/nullif(sum(ex.last_qty), 0)  DAY_AVG_PX,
                  SUM(EX.LAST_QTY) DAY_CUM_QTY,
                  SUM(EX.LAST_QTY*EX.LAST_PX) PRINCIPAL

                FROM EXECUTION EX
                WHERE ex.order_id = 13664305271
      and EX.EXEC_TYPE IN ('F', 'G')
                AND EX.IS_BUSTED <> 'Y'
                and ex.exec_date_id = :in_date_id
                group by order_id
limit 1


select distinct(street_mpid) from dwh.flat_trade_record
where account_id = 12909
  and date_id = 20231109
and order_id = 13678180140;


-- wellsfargo
select 'wf', cl.order_id, ex.* from dwh.client_order cl
    left join lateral(
select ex.order_id,
                    sum(ex.last_qty * ex.last_px) / nullif(sum(ex.last_qty), 0) day_avg_px,
                    sum(ex.last_qty)                                            day_cum_qty,
                    sum(ex.last_qty * ex.last_px)                               principal
             from execution ex
             where ex.order_id = cl.order_id
--                and ex.exec_type in ('F', 'G')
               and ex.is_busted <> 'Y'
               and ex.exec_date_id between :in_start_date_id and :in_end_date_id
             group by ex.order_id
             limit 1) ex on true
                 where cl.create_date_id = 20231109
and cl.create_date_id between :in_start_date_id and :in_end_date_id
and cl.client_order_id = '11017453246ESWC1'



select 'hkb', cl.order_id, ex.* from dwh.client_order cl
    left join lateral
              (
                select row_number() over (partition by ex.order_id order by ex.exec_id desc) as rn
                  , ex.order_status , ex.exec_type
                  , ex.cum_qty as ex_qty
                  , ex.avg_px
                  , sum(ex.last_px * ex.last_qty) over (partition by ex.order_id) as princ_amnt
                  , nullif(sum(ex.last_qty) over (partition by ex.order_id), 0) as last_qty
                  , case when sum(ex.last_qty) over (partition by ex.order_id) > 0
                           then round(sum(ex.last_px * ex.last_qty) over (partition by ex.order_id) / sum(ex.last_qty) over (partition by ex.order_id), 4)
                         else null
                    end as avg_px_calc
                  , ex.exec_time
                from dwh.execution ex
                where ex.order_id = cl.order_id
                  and ex.exec_date_id >= :l_start_date_id --20210301
              ) ex on rn=1
where cl.create_date_id = 20231109
and cl.create_date_id between :in_start_date_id and :in_end_date_id
and cl.client_order_id = '11017453246ESWC1'
