-- DROP FUNCTION dash360.report_fintech_eod_strategas_allocation(int4, int4);
-- dash360.report_fintech_eod_spdradv01_allocation(in_start_date_id, in_end_date_id, in_trading_firm_ids, in_account_ids)
select * from dwh.d_account
where account_name = 'SPDRC_CHAS_EOS';


select * from dwh.gtc_order_status
where create_date_id > 2025001
and account_id = 75781

select *
from dash360.report_fintech_eod_spdradv01_allocation(in_start_date_id := 20251010, in_end_date_id := 20251015,
                                                     in_account_ids := '{75781}');



CREATE or replace FUNCTION dash360.report_fintech_eod_spdradv01_allocation(in_start_date_id integer,
                                                                           in_end_date_id integer,
                                                                           in_account_ids integer[] DEFAULT NULL::integer[],
                                                                           in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$fn$
declare
    l_load_id         int;
    l_row_cnt         int;
    l_step_id         int;
    l_account_ids     int4[];
    l_is_current_date bool := false;
begin
    l_step_id := 0;
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_spdradv01_allocation for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    drop table if exists t_report;
    create temp table t_report as
    select trade_record_id,
           order_id,
           '08423881'                                  as "Master",
           ui.symbol                                   as "Underlying Symbol",
           to_char(i.last_trade_date, 'MM/DD/YYYY')    as "Expiration",
           oc.strike_price                                "Strike",
           case
               when oc.put_call = '0' then 'PUT'
               when oc.put_call = '1' then 'CALL'
               end                                     as "Type",
           tr.last_qty                                 as "Contracts",
           case
               when tr.side = '2' and tr.open_close = 'C' then 'SCO'--'Sell to Close'
               when tr.side = '2' and tr.open_close = 'O' then 'SOO'--'Sell to Open'
               when tr.side = '1' and tr.open_close = 'C' then 'BCO'--'Buy to Close'
               when tr.side = '1' and tr.open_close = 'O' then 'BOO'--'Buy to Open'
               end                                     as "Action",
           tr.last_px                                  as "Price",
           tr.exchange_id                                 "Broker",
           round(tr.last_qty * 0.25, 4)                as "Comm",
           to_char(tr.trade_record_time, 'MM/DD/YYYY') as "T/D",
           to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date, tr.instrument_type_id),
                   'MM/DD/YYYY')                       as "S/D"
    from dwh.flat_trade_record tr
             join dwh.d_account ac
                  on tr.account_id = ac.account_id
             left join dwh.d_trading_firm tf
                       on ac.trading_firm_unq_id = tf.trading_firm_unq_id
             left join dwh.d_instrument i
                       on tr.instrument_id = i.instrument_id
             left join dwh.d_option_contract oc
                       on i.instrument_id = oc.instrument_id
             left join dwh.d_option_series dos on oc.option_series_id = dos.option_series_id
             left join dwh.d_instrument ui on ui.instrument_id = dos.underlying_instrument_id
    where true
      and tr.date_id between in_start_date_id and in_end_date_id -- 20210315 and 20210315
      and tr.instrument_type_id = 'O'
      and tr.is_busted = 'N'
      and ac.account_id = any (l_account_ids);

    return query
        select 'Master,Underlying Symbol,Expiration,Strike,Type,Contracts,Action,Price,Broker,Comm,T/D,S/D';

    return query
        select array_to_string(ARRAY ["Master",
                                   "Underlying Symbol",
                                   "Expiration",
                                   staging.trailing_dot("Strike"), -- as "Strike",
                                   "Type",
                                   sum("Contracts")::text, -- as "Contracts",
                                   "Action",
                                   to_char(round(sum("Contracts" * "Price") / sum("Contracts"), 4),
                                           'FM999990D0099'), -- as "Price",
                                   "Broker",
                                   to_char(sum("Comm"), 'FM999990D0099'), --as "Comm",
                                   "T/D",
                                   "S/D"
                                   ], ',', '')
        from t_report
        group by order_id, "Master", "Underlying Symbol", "Expiration", "Strike", "Type", "Action", "Price", "Broker",
                 "T/D",
                 "S/D"
    order by order_id, "T/D";
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_spdradv01_allocation for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===', l_row_cnt, 'O')
    into l_step_id;

end ;
$fn$
;
