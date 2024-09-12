-- DROP FUNCTION fintech_reports.adh_ml_broadcort_clearing_equity(int4, varchar);

create or replace function dash360.report_fintech_ml_bct221x(in_file_name text default 'BCT221XA',
                                                             in_start_date_id int4 default get_dateid(current_date),
                                                             in_end_date_id int4 default get_dateid(current_date))
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$function$
declare

    l_file_name  text;
    l_load_id    int;
    l_row_cnt_eq int;
    l_row_cnt_op int;
    l_step_id    int;

begin

    l_file_name := in_file_name;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, 'report_fintech_ml_bct221x for ' || in_start_date_id::text || '-' ||
                                                 in_end_date_id::text || ' and file ' || l_file_name || ' STARTED ===',
                           0, 'O')
    into l_step_id;
-- EQUITY PART
    create temp table t_equity on commit drop as
    select q.account_number,
           'S'                                                                         as sec_id_type,
           q.sec_id,
           '4'                                                                         as price_code_type,
           round(sum(q.quantity * q.unit_price) / sum(q.quantity), unit_price_decimal) as unit_price,
           sum(q.quantity)                                                             as quantity,
           q.settle_date,
           q.trade_date,
           q.buy_sell_ind,
           coalesce(q.short_ind, '')                                                   as short_ind,
           '8Z'                                                                        as origin_exchange,
           '0'                                                                         as trade_action,
           case when sum(q.commission_amount) > 0 then '7' else '2' end                as commission_type,
           case
               when q.account_number in ('3Q802F21', '3Q802F30', '3Q830065') then
                   coalesce(nullif(round(sum(q.commission_amount), 2), 0), 0.01) -- Set minimum commission for certain ML accounts
               when q.account_number in ('3Q830059') then --'GRANAHAN', 'GRANAHANPT'
                   round(sum(q.quantity) * (
                       case
                           when round(sum(q.quantity * q.unit_price) / sum(q.quantity), unit_price_decimal) < 1.0
                               then 0.005
                           when round(sum(q.quantity * q.unit_price) / sum(q.quantity), unit_price_decimal) < 5.0
                               then 0.01
                           else 0.02
                           end
                       ), 2)
               else round(sum(q.commission_amount), 2)
               end                                                                     as commission_amount,
           --round(sum(q.commission_amount), 2) as commission_amount,
           '3Q800797'                                                                  as opposing_account,
           '4'                                                                         as nbr_misc_trailers,
           '2'                                                                         as ae_credit_type,
           '0000'                                                                      as financial_consultannt_nbr,
           '1'                                                                         as exchang_1,
           '00'                                                                        as percent_1,
           q.acted_as_ind,
           ''                                                                          as automated_trade_ind,
           ''                                                                          as tif_sec_fe_spp_rsn_cd,
           ''                                                                          as blue_sheet_acct_typ_ind,
           '160000'                                                                    as exec_time,
           'Y'                                                                         as taf_exemption_ind,
           ''                                                                          as td_xtnl_cli_rf_no
    from (select
              --null::varchar as entity,
              case
                  --when a.account_name in ('SAXOPROPCROSS', 'SAXORET') then a.account_name
                  when a.account_name in ('CIC3921C', 'CICMARCHES', 'ITAC') then tr.client_order_id
                  else ''
                  end                                           as entity,
              a.account_name,
              case
                  when a.trading_firm_id = 'rhumba01'
                      then coalesce(c2a.ml_account, mb.ml_account) --Rhumbline Advisers
                  else mb.ml_account
                  end                                           as account_number,
              replace(hsd.display_instrument_id, ' ', '')::text as sec_id,
              tr.last_px                                        as unit_price,
              last_qty                                          as quantity,
              to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date, tr.instrument_type_id),
                      'YYYYMMDD')                               as settle_date,
              to_char(tr.trade_record_time, 'YYYYMMDD')         as trade_date,
              case
                  when tr.side = '1' then '1'
                  when tr.side in ('2', '5', '6')
                      then '2'
                  else '' end                                   as buy_sell_ind,
              --null::varchar as short_ind,
              case
                  when tr.side in ('5', '6') then '1'
                  else null
                  end::text                                     as short_ind,
              case
                  when a.account_name in ('VANECK', 'VANECKPT', 'VANECKPTSP') then
                      (
                          case
                              when abs(tr.last_px) <= 1.99 then 0.001
                              when abs(tr.last_px) <= 4.99 then 0.002
                              when abs(tr.last_px) <= 9.99 then 0.005
                              else 0.008
                              end
                          ) * tr.last_qty
                  /*
                  when a.account_name in ('GRANAHAN', 'GRANAHANPT') then
                  (
                      case
                          when tr.last_px < 1.0 then 0.005
                          when tr.last_px < 5.0 then 0.01
                          else 0.02
                      end
                  ) * tr.last_qty
                  */
                  when a.account_name in ('MACQUARIE', 'MACQUARIEPT') then
                      (
                          case
                              when tr.last_px <= 5.0 then 0.04
                              when tr.last_px <= 25.0 then 0.05
                              else 0.06 end
                          ) * tr.last_qty
                  when a.account_name in ('SAXOPROPCROSS', 'SAXORET') then
                      (
                          case
                              when tr.exchange_id = 'LEVLX' then 0.0004
                              else 0.001 end
                          ) * tr.last_qty
                  when mb.commission_type = '1' and mb.commission_rate is not null
                      then mb.commission_rate * tr.last_qty
                  when mb.commission_type = '2' and mb.commission_rate is not null
                      then mb.commission_rate * tr.principal_amount
                  else coalesce(tr.tcce_account_dash_commission_amount, tr.tcce_firm_dash_commission_amount, 0.0)
                  end                                           as commission_amount,
              coalesce(a.eq_order_capacity, 'A')                as acted_as_ind,
              mb.unit_price_decimal
          from dwh.flat_trade_record tr
                   join fintech_reports.ml_broadcort_booking mb on (
              mb.account_id = tr.account_id
                  and mb.instrument_type_id = tr.instrument_type_id
                  and mb.ml_account is not null
                  and mb.is_active
              )
                   join dwh.d_account a on (a.account_id = tr.account_id)
                   join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                   join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
                   left join fintech_reports.client_id2ml_account c2a
                             on (upper(c2a.client_id) = upper(tr.client_id))
          where mb.file_name = l_file_name
            and tr.date_id between in_start_date_id and in_end_date_id
            and tr.instrument_type_id = 'E'
            and tr.is_busted = 'N'
            and hsd.symbol not in ('ZVZZT')

          union all

          select tr.trading_firm_id                          as entity,
                 a.account_name,
                 '3Q801987'                                  as account_number,
                 replace(hsd.display_instrument_id, ' ', '') as sec_id,
                 tr.last_px                                  as unit_price,
                 last_qty                                    as quantity,
                 to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date,
                                                                   tr.instrument_type_id),
                         'YYYYMMDD')                         as settle_date,
                 to_char(tr.trade_record_time, 'YYYYMMDD')   as trade_date,
                 case
                     when tr.side = '1' then '1'
                     when tr.side in ('2', '5', '6')
                         then '2' end                        as buy_sell_ind,
                 --null::varchar as short_ind,
                 case
                     when tr.side in ('5', '6') then '1'
                     else null
                     end::text                               as short_ind,
                 0.0 * tr.last_qty                           as commission_amount,
                 coalesce(a.eq_order_capacity, 'A')          as acted_as_ind,
                 4                                           as unit_price_decimal
          from dwh.flat_trade_record tr
                   join dwh.d_account a on (a.account_id = tr.account_id)
                   join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                   join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
          where tr.date_id between in_start_date_id and in_end_date_id
            and tr.instrument_type_id = 'E'
            and tr.is_busted = 'N'
            and tr.trading_firm_id in ('pegasus', 'fnyqsg', 'fnyinva01') --'fnyglob01'
            and hsd.symbol not in ('ZVZZT')
            and l_file_name = 'BCT221XA') as q
    group by q.entity, q.account_number, q.sec_id, q.settle_date, q.trade_date, q.buy_sell_ind, q.short_ind,
             q.acted_as_ind, q.unit_price_decimal;

-- TITLE
    return query
        select rpad(l_file_name, 8) || -- 1-8
               lpad('', 2) || -- 9-10
               'ENTRY DATE: ' || -- 11-22
               to_char(current_date, 'YYYYMMDD') || -- 23-30
               ' ' || -- 31-31
               to_char(clock_timestamp(), 'HH24MI') || -- 32-35
               lpad('', 14) || -- 36-49
               'E' || -- 50-50
               '  1' || -- 51-53
               ' ' || -- 54-54
               lpad('', 5) || -- 55-59
               lpad('', 941);
    -- 60-1000
-- EQUITY
    return query
        select rpad(q.account_number, 8) || -- 1-8
               q.sec_id_type || -- 9-9
               rpad(q.sec_id, 22) || -- 10-31
               lpad('', 2) || -- 32-33
               price_code_type || -- 34-34
               lpad(round(q.unit_price * 1000000)::text, 11, '0') || -- 35-45
               lpad(q.quantity::text, 9, '0') || -- 46-54
               lpad(settle_date, 8, ' ') || -- 55-62
               lpad(trade_date, 8, ' ') || -- 63-70
               rpad(buy_sell_ind, 1) || -- 71-71
               rpad(short_ind, 1) || -- 72-72
               lpad('', 5) || -- 73-77
               origin_exchange || -- 78-79
               lpad('', 10) || -- 80-89
               trade_action || -- 90-90
               commission_type || -- 91-91
               lpad(round(q.commission_amount * 100)::text, 9, '0') || -- 92-100
               opposing_account || -- 101-108
               nbr_misc_trailers || -- 109-109
               lpad('', 3) || -- 110-112
               ae_credit_type || -- 113-113
               lpad('', 9) || -- 114-122
               lpad(q.financial_consultannt_nbr, 4) || -- 123-126
               lpad('', 5) || -- 127-131
               q.exchang_1 || -- 132-132
               q.percent_1 || -- 133-134
               lpad('', 13) || -- 135-147
               acted_as_ind || -- 148-148
               lpad(automated_trade_ind, 1) || -- 149-149
               lpad('', 64) || -- 150-213
               rpad(
                       'Dash may receive(pay) rebates(fees) related to this trade. Details can be found via DASH360 or upon written request.',
                       120) || -- 214-333
               lpad('', 5) || -- 334-338
               lpad(tif_sec_fe_spp_rsn_cd, 3) || -- 339-341
               ' ' || -- 342-342
               lpad(blue_sheet_acct_typ_ind, 1) || -- 343-343
               lpad('', 9) || -- 344-352
               exec_time || -- 353-358
               lpad('', 161) || -- 359-519
               ' ' || -- 520-520
               taf_exemption_ind || -- 521-521
               lpad('', 284) || -- 522-805
               lpad('A' || to_char(now(), 'YYYYMMDDHH24MISS') ||
                    lpad((row_number() over (order by q.trade_date, q.account_number, q.sec_id, q.buy_sell_ind))::text,
                         5, '0'), 20) || -- 806-825
               lpad('', 175) -- 826-1000
        from t_equity q
        order by q.trade_date, q.account_number, q.sec_id, q.buy_sell_ind;
    get diagnostics l_row_cnt_eq = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_ml_bct221x EQUITY for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' and file ' || l_file_name || ' finished ===',
                           l_row_cnt_eq, 'O')
    into l_step_id;

    -- OPTION PART
    create temp table t_option on commit drop as
    select q.account_number,
           'O'                                                                 as sec_id_type,
           q.sec_id,
           '4'                                                                 as price_code_type,
           round(sum(q.quantity * q.unit_price) / sum(q.quantity), 6)          as unit_price,
           sum(q.quantity)                                                     as quantity,
           q.trade_date,
           q.buy_sell_ind,
           q.open_close_ind,
           q.origin_exchange,
           '0'                                                                 as trade_action,
           case when sum(q.commission_amount) > 0 then '7' else '2' end        as commission_type,
           round(sum(q.commission_amount), 2) + coalesce(q.ticket_charge, 0.0) as commission_amount,
           '0'                                                                 as nbr_misc_trailers,
           '1'                                                                 as unsolicited_ind,
           '0000'                                                              as ae_nbr,
           'C'                                                                 as covered_uncovered_ind,
           q.acted_as_ind,
           'C'                                                                 as cash_margin_ind,
           'C'                                                                 as blue_sheet_acct_type_ind,
           '160000'                                                            as exec_time,
           q.td_stk_px,
           q.opt_sc_xpr_dt,
           ''                                                                  as td_xtnl_cli_rf_no
    from (select mb.ml_account                             as account_number,
                 hsd.symbol                                as sec_id,
                 tr.last_px                                as unit_price,
                 tr.last_qty                               as quantity,
                 to_char(tr.trade_record_time, 'YYYYMMDD') as trade_date,
                 case
                     when tr.side = '1' then '1'
                     when tr.side in ('2', '5', '6')
                         then '2' end                      as buy_sell_ind,
                 tr.open_close                             as open_close_ind,
                 case
                     when hsd.put_call = '0' then 'P3'
                     when hsd.put_call = '1'
                         then 'C3' end                     as origin_exchange,
                 case
                     when a.account_name = 'LGCAP_VRP_8677'
                         then (case when hsd.symbol = 'SPX' then 1.0 else 2.0 end) * tr.last_qty
                     when a.trading_firm_id in ('wiltrst01', 'wiltrht')
                         then (case when tr.last_px < 1.0 then 2.0 else 2.5 end) * tr.last_qty
                     when mb.commission_type = '1' then mb.commission_rate * tr.last_qty
                     when mb.commission_type = '2' then mb.commission_rate * tr.principal_amount
                     else coalesce(tr.tcce_account_dash_commission_amount, tr.tcce_firm_dash_commission_amount, 0.0)
                     end                                   as commission_amount,
                 coalesce(a.eq_order_capacity, 'A')        as acted_as_ind,
                 hsd.strike_px                             as td_stk_px,
                 to_char(hsd.maturity_date, 'YYYYMMDD')    as opt_sc_xpr_dt,
                 mb.ticket_charge
          from dwh.flat_trade_record tr
                   join fintech_reports.ml_broadcort_booking mb on (
              mb.account_id = tr.account_id
                  and mb.instrument_type_id = tr.instrument_type_id
                  and mb.ml_account is not null
                  and mb.is_active
              )
                   join dwh.d_account a on (a.account_id = tr.account_id)
                   join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                   join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
          where mb.file_name = l_file_name
            and tr.date_id between in_start_date_id and in_end_date_id
            and tr.instrument_type_id = 'O'
            and tr.multileg_reporting_type in ('1', '2')
            and tr.is_busted = 'N'

          union all

          select aie.occ_actionable_id                                                         as account_number,
                 hsd.symbol                                                                    as sec_id,
                 ai.avg_px                                                                     as unit_price,
                 aie.alloc_qty                                                                 as quantity,
                 to_char(ai.create_time, 'YYYYMMDD')                                           as trade_date,
                 case when ai.side = '1' then '1' when ai.side in ('2', '5', '6') then '2' end as buy_sell_ind,
                 ai.open_close                                                                 as open_close_ind,
                 case when hsd.put_call = '0' then 'P3' when hsd.put_call = '1' then 'C3' end  as origin_exchange,
                 case
                     when mb.commission_type = '1' then mb.commission_rate * aie.alloc_qty
                     when mb.commission_type = '2' then mb.commission_rate * (aie.alloc_qty * ai.avg_px)
                     else 0.0
                     end                                                                       as commission_amount,
                 coalesce(a.eq_order_capacity, 'A')                                            as acted_as_ind,
                 hsd.strike_px                                                                 as td_stk_px,
                 to_char(hsd.maturity_date, 'YYYYMMDD')                                        as opt_sc_xpr_dt,
                 mb.ticket_charge
          from staging.allocation_instruction ai
                   join staging.allocation_instruction_entry aie
                        on (aie.date_id = ai.date_id and aie.alloc_instr_id = ai.alloc_instr_id)
                   join dwh.d_account a on (a.account_id = ai.account_id)
                   join dwh.historic_security_definition_all hsd on (hsd.instrument_id = ai.instrument_id)
                   join fintech_reports.ml_broadcort_booking mb on (
              mb.account_id = ai.account_id
                  and mb.instrument_type_id = hsd.instrument_type_id
                  and mb.ml_account is null
                  and mb.is_active
              )
          where ai.date_id between in_start_date_id and in_end_date_id
            and mb.file_name = l_file_name
            and ai.is_deleted = 'N'
            --and coalesce(aie.occ_actionable_id, '') <> ''
            and (aie.occ_actionable_id is not null and aie.occ_actionable_id <> '')
            and hsd.instrument_type_id = 'O') as q
    group by q.account_number, q.sec_id, q.trade_date, q.buy_sell_ind, q.open_close_ind, q.origin_exchange,
             q.acted_as_ind, q.td_stk_px, q.opt_sc_xpr_dt, q.ticket_charge;

    return query
        select rpad(q.account_number, 8) || -- 1-8
               q.sec_id_type || -- 9-9
               rpad(q.sec_id, 24) || -- 10-33
               price_code_type || -- 34-34
               lpad(round(q.unit_price * 1000000)::text, 11, '0') || -- 35-45
               lpad(q.quantity::text, 9, '0') || -- 46-54
               lpad('', 8) || -- 55-62
               lpad(trade_date, 8, ' ') || -- 63-70
               rpad(buy_sell_ind, 1) || -- 71-71
               rpad(q.open_close_ind, 1) || -- 72-72
               lpad('', 5) || -- 73-77
               origin_exchange || -- 78-79
               lpad('', 10) || -- 80-89
               trade_action || -- 90-90
               commission_type || -- 91-91
               lpad(round(q.commission_amount * 100)::text, 9, '0') || -- 92-100
               lpad('', 8) || -- 101-108
               nbr_misc_trailers || -- 109-109
               lpad('', 1) || -- 110-110
               unsolicited_ind || -- 111-111
               lpad('', 11) || -- 112-122
               q.ae_nbr || -- 123-126
               lpad('', 4) || -- 127-130
               q.covered_uncovered_ind || -- 131-131
               lpad('', 16) || -- 132-147
               q.acted_as_ind || -- 148-148
               cash_margin_ind || -- 149-149
               lpad('', 193) || -- 150-342
               q.blue_sheet_acct_type_ind || -- 343-343
               lpad('', 9) || -- 344-352
               q.exec_time || -- 353-358
               lpad('', 242) || -- 359-600
               lpad(round(td_stk_px * 10000000)::text, 13, '0') || -- 601-613
               q.opt_sc_xpr_dt || -- 614-621
               lpad('', 184) || -- 622-805
               lpad('A' || to_char(now(), 'YYYYMMDDHH24MISS') ||
                    lpad((row_number() over (order by q.trade_date, q.account_number, q.sec_id, q.buy_sell_ind) +
                          l_row_cnt_eq)::text,
                         5, '0'), 20) || -- 806-825
               lpad('', 175) -- 826-1000
        from t_option q
        order by q.trade_date, q.account_number, q.sec_id, q.buy_sell_ind;
    get diagnostics l_row_cnt_op = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_ml_bct221x OPTION for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' and file ' || l_file_name || ' finished ===',
                           l_row_cnt_op, 'O')
    into l_step_id;
    return query
        select '99999999 RECORD COUNT: ' || -- 1-23
               lpad((l_row_cnt_eq + l_row_cnt_op)::text, 10, '0') || -- 24-33
               lpad('', 967); -- 34-1000

    select public.load_log(l_load_id, l_step_id, 'report_fintech_ml_bct221x for ' || in_start_date_id::text || '-' ||
                                                 in_end_date_id::text || ' and file ' || l_file_name ||
                                                 ' COMPLETED ===',
                           l_row_cnt_eq + l_row_cnt_op, 'O')
    into l_step_id;

end;
$function$
;

select * from dash360.report_fintech_ml_bct221x()