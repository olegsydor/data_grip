select di.* from dwh.flat_trade_record ftr
         join dwh.d_instrument di on di.instrument_id = ftr.instrument_id
    where true
        and ftr.date_id = 20220208
and display_instrument_id = 'TTCF 210917P00020000'


select * from dwh.d_option_contract
where opra_symbol = 'TTCF 210917P00020000'

select * from dwh.d_option_series
where root_symbol = 'TTCF 210917P00020000'

select * from dash360.report_fintech_eod_velocity_option_trade(20220208, 20220208)
drop function dash360.report_fintech_eod_velocity_option_trade;
create function dash360.report_fintech_eod_velocity_option_trade(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                entry_type         text,
                trd_type           text,
                trade_dt           int4,
                settle_dt          text,
                exec_dt            text,
                symbol             varchar(30),
                qty                int8,
                price              numeric(16, 8),
                g_amt              text,
                comm               numeric,
                sec_fee            text,
                exch_fee           text,
                clr_fee            text,
                ecn_fee            text,
                brk_fee            text,
                occ_fee            text,
                oth_fee            text,
                "corr"             text,
                office             text,
                acct_no            text,
                acct_type          text,
                sub_acct_nosub     text,
                contra_code        text,
                contra_corr        text,
                contra_office      text,
                contra_acct_no     text,
                contra_acct_type   text,
                contra_sub_acct_no text,
                blot_exch_cd       text,
                blot_clr_typ       text,
                blot_method        text,
                trd_tag            text,
                descr              text,
                memo1              text,
                memo2              text,
                tax_lot            text,
                lot_tr_no          text,
                buy_interest       text,
                finc_yield         text,
                yield_type         text,
                capacity           text,
                ac_grp_cd          text,
                trailer_codes      text,
                rr_cd              text,
                ad_cd              text,
                an_cd              text,
                tr_cd              text,
                currency           text,
                set_currency       text,
                set_country        text,
                set_location       text,
                reported_price     text,
                sales_credit       text,
                discretion_flg     text,
                solicited          text,
                comm_type          text,
                taxlot_tr_no       text,
                cl_order_id        text,
                order_id           text,
                exec_id            text,
                memo3              text
            )
    language plpgsql
as
$fx$

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
    where d_account.trading_firm_id in ('OFP0045', 'OFP0054', 'velcap01', 'velocltam', 'veloclear')
      and is_active;

    return query
        select 'TRD'                                                             as entry_type,
               tr.open_close || case
                                    when tr.side = '1' then 'B'
                                    when tr.side in ('2', '5', '6') then 'S' end as trd_type,
               tr.date_id                                                        as trade_dt,
               null                                                              as settle_dt,
               null                                                              as exec_dt,
               oc.opra_symbol                                                    as symbol,
               sum(tr.last_qty)                                                  as qty,
               sum(tr.last_qty * tr.last_px) / nullif(sum(tr.last_qty), 0)       as price,
               null                                                              as g_amt,
               sum(tr.tcce_account_dash_commission_amount)                       as comm,
               null                                                              as sec_fee,
               null                                                              as exch_fee,
               null                                                              as clr_fee,
               null                                                              as ecn_fee,
               null                                                              as brk_fee,
               null                                                              as occ_fee,
               null                                                              as oth_fee,
               'VCWC'                                                            as corr,
               'ALC'                                                             as office,
               '545764'                                                          as acct_no,
               'P'                                                               as acct_type,
               null                                                              as sub_acct_noSub,
               'DASH'                                                            as contra_code,
               null                                                              as contra_corr,
               null                                                              as contra_office,
               null                                                              as contra_acct_no,
               null                                                              as contra_acct_type,
               null                                                              as contra_sub_acct_no,
               'CMTA IN TO VELOCITY'                                             as blot_exch_cd,
               'CMTA IN TO VELOCITY'                                             as blot_clr_typ,
               'CMTA IN TO VELOCITY'                                             as blot_method,
               '545764'                                                          as trd_tag,
               null                                                              as descr,
               null                                                              as memo1,
               null                                                              as memo2,
               null                                                              as tax_lot,
               null                                                              as lot_tr_no,
               null                                                              as buy_interest,
               null                                                              as finc_yield,
               null                                                              as yield_type,
               'A'                                                               as capacity,
               null                                                              as ac_grp_cd,
               null                                                              as trailer_codes,
               null                                                              as rr_cd,
               null                                                              as ad_cd,
               null                                                              as an_cd,
               null                                                              as tr_cd,
               null                                                              as currency,
               null                                                              as set_currency,
               null                                                              as set_country,
               null                                                              as set_location,
               null                                                              as reported_price,
               null                                                              as sales_credit,
               null                                                              as discretion_flg,
               null                                                              as solicited,
               null                                                              as comm_type,
               null                                                              as taxlot_tr_no,
               null                                                              as cl_order_id,
               null                                                              as order_id,
               null                                                              as exec_id,
               null                                                              as memo3
        from dwh.flat_trade_record tr
                 inner join dwh.d_account acc on (tr.account_id = acc.account_id and acc.is_active)
                 inner join dwh.d_instrument i on (i.instrument_id = tr.instrument_id)

                 inner join dwh.d_trading_firm tf on (acc.trading_firm_id = tf.trading_firm_id and tf.is_active)
                 left join dwh.d_option_contract oc on (i.instrument_id = oc.instrument_id)
                 left join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.is_busted = 'N'
          and acc.account_id = any (l_account_ids)
        group by tr.open_close, tr.side, tr.date_id, tr.order_id, oc.opra_symbol, tr.order_id
        order by tr.order_id;


    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_eod_velocity_option_trade for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ====', 0, 'O')
    into l_step_id;
end;
$fx$


select * from d_exec_type et
    where et.exec_type in ('0', '4', '5', 'W')
or
        et.exec_type in ('F', '4', '5', 'W')







-- compare 1 PROD
-- DROP PROCEDURE dash_reporting.imc_report_making(int4);

