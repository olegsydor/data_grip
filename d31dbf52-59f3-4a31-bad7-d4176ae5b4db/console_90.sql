-- DROP FUNCTION fintech_reports.adh_ml_broadcort_clearing_equity(int4, varchar);

CREATE FUNCTION trash.adh_ml_broadcort_clearing_equity(in_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                       in_file_name character varying DEFAULT 'BCT221XA'::character varying)
    RETURNS TABLE
            (
                ret_row text
            )
    LANGUAGE plpgsql
AS
$function$
declare
    l_date_id     int;
    l_file_name   varchar;
    l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;

    l_nothing text := ' ';
begin
    l_date_id := in_date_id;
    l_file_name := in_file_name;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'adh_ml_broadcort_clearing_equity for ' || l_date_id::text || 'and file ' ||
                           l_file_name::text || ' STARTED ===', 0, 'O')
    into l_step_id;
-- drop table t_equity;
    create temp table t_equity /*on commit drop*/ as
    select q.account_number,
           'S'                                                                         as sec_id_type,
           q.sec_id,
           '4'                                                                as price_code_type,
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
                  end::varchar                                   as entity,
              a.account_name,
              case
                  when a.trading_firm_id = 'rhumba01'
                      then coalesce(c2a.ml_account, mb.ml_account) --Rhumbline Advisers
                  else mb.ml_account
                  end::varchar                                   as account_number,
              replace(hsd.display_instrument_id, ' ', '')::text  as sec_id,
              tr.last_px                                         as unit_price,
              last_qty                                           as quantity,
              to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date, tr.instrument_type_id),
                      'YYYYMMDD')::varchar                       as settle_date,
              to_char(tr.trade_record_time, 'YYYYMMDD')::varchar as trade_date,
              case
                   when tr.side = '1' then '1'
                   when tr.side in ('2', '5', '6')
                       then '2'
                  else '' end                    as buy_sell_ind,
              --null::varchar as short_ind,
              case
                  when tr.side in ('5', '6') then '1'
                  else null
                  end::varchar                                   as short_ind,
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
                  end                                            as commission_amount,
              coalesce(a.eq_order_capacity, 'A')::varchar        as acted_as_ind,
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
          where mb.file_name = :l_file_name
            and tr.date_id = :l_date_id
            and tr.instrument_type_id = 'E'
            and tr.is_busted = 'N'
            and hsd.symbol not in ('ZVZZT')

          union all

          select tr.trading_firm_id                                   as entity,
                 a.account_name,
                 '3Q801987'::varchar                                  as account_number,
                 replace(hsd.display_instrument_id, ' ', '')::varchar as sec_id,
                 tr.last_px                                           as unit_price,
                 last_qty                                             as quantity,
                 to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date,
                                                                   tr.instrument_type_id),
                         'YYYYMMDD')::varchar                         as settle_date,
                 to_char(tr.trade_record_time, 'YYYYMMDD')::varchar   as trade_date,
                 (case
                      when tr.side = '1' then '1'
                      when tr.side in ('2', '5', '6')
                          then '2' end)::varchar                      as buy_sell_ind,
                 --null::varchar as short_ind,
                 case
                     when tr.side in ('5', '6') then '1'
                     else null
                     end::varchar                                     as short_ind,
                 0.0 * tr.last_qty                                    as commission_amount,
                 coalesce(a.eq_order_capacity, 'A')::varchar          as acted_as_ind,
                 4                                                    as unit_price_decimal
          from dwh.flat_trade_record tr
                   join dwh.d_account a on (a.account_id = tr.account_id)
                   join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                   join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
          where tr.date_id = :l_date_id
            and tr.instrument_type_id = 'E'
            and tr.is_busted = 'N'
            and tr.trading_firm_id in ('pegasus', 'fnyqsg', 'fnyinva01') --'fnyglob01'
            and hsd.symbol not in ('ZVZZT')
            and :l_file_name = 'BCT221XA') as q
    group by q.entity, q.account_number, q.sec_id, q.settle_date, q.trade_date, q.buy_sell_ind, q.short_ind,
             q.acted_as_ind, q.unit_price_decimal;

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
               lpad('', 941); -- 60-1000

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
               lpad('A' || to_char(now(), 'YYYYMMDDHH24MISS') || lpad((row_number() over ())::text, 5, '0'), 20) || -- 806-825
               lpad('', 175) -- 826-1000
        from t_equity q
        order by q.trade_date, q.account_number, q.sec_id, q.buy_sell_ind;


end;
$function$
;

select clock_timestamp(), now()