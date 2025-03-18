-- DROP FUNCTION dash360.report_fintech_eod_alaric01_option_trade(int4, int4);

create or replace function dash360.report_fintech_eod_alaric01_option_trade(in_start_date_id integer, in_end_date_id integer)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$

declare
    l_load_id     int;
    l_step_id     int;
    l_row_cnt     int;
    l_account_ids int4[];

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_velocity_option_trade for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;


    select array_agg(d_account.account_id)
    into l_account_ids
    from dwh.d_account
    where trading_firm_id in ('alaric01', 'OFP0052')
      and is_active;

    return query
        select array_to_string(ARRAY [
                                   'TRD' , -- as entry_type,
                                   tr.open_close || case
                                                        when tr.side = '1' then 'B'
                                                        when tr.side in ('2', '5', '6') then 'S' end, -- as trd_type,
                                   tr.date_id::text , -- as trade_dt,
                                   null , -- as settle_dt,
                                   null , -- as exec_dt,
                                   oc.opra_symbol , -- as symbol,
                                   sum(tr.last_qty)::text , -- as qty,
                                   round(sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0),
                                         6)::text, -- as price,
                                   null , -- as g_amt,
                                   round(sum(tr.tcce_account_dash_commission_amount), 6)::text , -- as comm,
                                   null , -- as sec_fee,
                                   null , -- as exch_fee,
                                   null , -- as clr_fee,
                                   null , -- as ecn_fee,
                                   null , -- as brk_fee,
                                   null , -- as occ_fee,
                                   null , -- as oth_fee,
                                   'VCWC' , -- as corr,
                                   'ALC' , -- as office,
                                   '545764' , -- as acct_no,
                                   'P' , -- as acct_type,
                                   null , -- as sub_acct_noSub,
                                   'DASH' , -- as contra_code,
                                   null , -- as contra_corr,
                                   null , -- as contra_office,
                                   null , -- as contra_acct_no,
                                   null , -- as contra_acct_type,
                                   null , -- as contra_sub_acct_no,
                                   '51' , -- as blot_exch_cd,
                                   'O2' , -- as blot_clr_typ,
                                   '00' , -- as blot_method,
                                   '545764' , -- as trd_tag,
                                   null , -- as descr,
                                   null , -- as memo1,
                                   null , -- as memo2,
                                   null , -- as tax_lot,
                                   null , -- as lot_tr_no,
                                   null , -- as buy_interest,
                                   null , -- as finc_yield,
                                   null , -- as yield_type,
                                   'A' , -- as capacity,
                                   null , -- as ac_grp_cd,
                                   null , -- as trailer_codes,
                                   null , -- as rr_cd,
                                   null , -- as ad_cd,
                                   null , -- as an_cd,
                                   null , -- as tr_cd,
                                   null , -- as currency,
                                   null , -- as set_currency,
                                   null , -- as set_country,
                                   null , -- as set_location,
                                   null , -- as reported_price,
                                   null , -- as sales_credit,
                                   null , -- as discretion_flg,
                                   null , -- as solicited,
                                   null , -- as comm_type,
                                   null , -- as taxlot_tr_no,
                                   null , -- as cl_order_id,
                                   null , -- as order_id,
                                   null , -- as exec_id,
                                   null -- as memo3
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
                 inner join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)

                 inner join dwh.d_trading_firm tf on (acc.trading_firm_id = tf.trading_firm_id and tf.is_active)
                 left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
        where true
          and tr.date_id between in_start_date_id and in_end_date_id
          and tr.instrument_type_id = 'O'
          and tr.is_busted = 'N'
          and acc.account_id = any (l_account_ids)
        group by tr.open_close, tr.side, tr.date_id, tr.order_id, oc.opra_symbol, tr.order_id
        order by tr.order_id;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_velocity_option_trade for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;

select * from dash360.report_fintech_eod_alaric01_option_trade(20250301, 20250315)