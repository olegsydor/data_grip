-- DROP FUNCTION dash360.report_fintech_adh_occ_portfolio_cboe_hanweck_new(int4, int4);

CREATE FUNCTION dash360.report_fintech_adh_occ_portfolio_cboe_hanweck_new(in_start_date_id integer, in_end_date_id integer)
 RETURNS TABLE(ret_row text)
 LANGUAGE plpgsql
AS $function$
    -- 2025-05-20 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-6115
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_adh_occ_portfolio_cboe_hanweck for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;


    return query
        select 'Date,PortfolioId,SubPortfolioId,Symbols,Expiration,Strike,PutCall,InstType,PositionType,Exchange,Quantity,PosSettleDate,Cash,ClientInfo';

    return query
        select array_to_string(ARRAY [
                                   to_char(tr.trade_record_time, 'MM/dd/yyyy'),-- as "Date",
                                   coalesce(hpm.portfolio_id, ac.trading_firm_id),-- as "PortfolioId",
                                   null,-- as "SubPortfolioId",
                                   os.root_symbol,-- as "Symbols",
                                   to_char(oc.maturity_month, 'FM00') || to_char(oc.maturity_day, 'FM00') ||
                                   to_char(oc.maturity_year, 'FM0000'),-- as "Expiration",
                                   oc.strike_price::text,-- as "Strike",
                                   case when oc.put_call = '0' then 'P' when oc.put_call = '1' then 'C' end,-- as "PutCall",
                                   di.instrument_type_id,-- as "InstType",
                                   'O',-- as "PositionType",
                                   null,-- as "Exchange",
                                   sum(tr.last_qty * (case when tr.side = '1' then 1.0 else -1.0 end))::text,-- as "Quantity",
                                   null,-- as "PosSettleDate",
                                   null,-- as "Cash",
                                   null -- as "ClientInfo"
                                   ], ',', '')
        select *
        from genesis2.occ_data.occ_trade_data tr
                 join genesis2.account ac on (ac.account_id = tr.account_id)
                 join genesis2.instrument di on (di.instrument_id = tr.instrument_id)
                 join genesis2.option_contract oc on (oc.instrument_id = tr.instrument_id)
                 join genesis2.option_series os on (os.option_series_id = oc.option_series_id)
                 left join fintech.hanweck_portfolio_mapping hpm on (hpm.trading_firm_id = ac.trading_firm_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and di.instrument_type_id = 'O'
          and tr.is_busted = 'N'
          and coalesce(tr.is_billed, 'N') != 'R' --Unreported
          and ac.opt_report_to_mpid = 'MLCB'     --PTA Trades
        group by to_char(tr.trade_record_time, 'MM/dd/yyyy'), coalesce(hpm.portfolio_id, ac.trading_firm_id), os.root_symbol, oc.maturity_month,
                 oc.maturity_day,
                 oc.maturity_year, oc.strike_price, oc.put_call, di.instrument_type_id
        order by to_char(tr.trade_record_time, 'MM/dd/yyyy'), coalesce(hpm.portfolio_id, ac.trading_firm_id), os.root_symbol, oc.maturity_month,
                 oc.maturity_day,
                 oc.maturity_year, oc.strike_price, oc.put_call, di.instrument_type_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_laniakea_allocation for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;

end ;
$function$
;

create temp table t_os as
select coalesce(portfolio_id,  'A000' ) as portfolio_id, aacount_id, tr.*
from occ_data.occ_trade_data tr
         left join lateral ( select coalesce(hpm.portfolio_id, ac.trading_firm_id) as portfolio_id, ac.account_id as aacount_id
                             from occ_data.occ_trade_data_matching mtr
                                      join genesis2.account ac using (account_id)
                                      left join fintech.hanweck_portfolio_mapping hpm using (trading_firm_id)
                             where mtr.date_id = tr.date_id
                               and mtr.trade_id = tr.trade_id
                               and mtr.side = tr.side
                               and mtr.trade_record_id != -1
                             limit 1) on true
where tr.date_id between :in_start_date_id and :in_end_date_id
  and clearing_member_number in ('00333', '00733', '333', '733')
  and gup_clearing_firm_originator is null
  and trade_type = '0'
  and not exists (select null
                  from genesis2.occ_data.occ_trade_data cnc
                  where cnc.rpt_id = tr.rpt_id
                    and cnc.date_id = tr.date_id
                    and cnc.side = tr.side
                    and cnc.trans_type = '1')
  and not exists (select null
                  from genesis2.occ_data.occ_matched_trade_record mr
                  where mr.date_id = tr.date_id
                    and mr.trade_id = tr.trade_id);

select * from t_os
where aacount_id is not null


select * from genesis2.occ_data.occ_matched_trade_record;


select mtr.account_id, tr.account_id, * from occ_data.occ_trade_data_matching mtr
join genesis2.trade_record tr using (date_id, trade_record_id)
where mtr.account_id != tr.account_id
