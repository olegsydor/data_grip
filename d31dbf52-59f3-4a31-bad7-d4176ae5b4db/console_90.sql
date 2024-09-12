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
    l_date_id   int;
    l_file_name varchar;
        l_load_id     int;
    l_row_cnt     int;
    l_step_id     int;
    l_account_ids int4[];
begin
    l_date_id := in_date_id;
    l_file_name := in_file_name;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'adh_ml_broadcort_clearing_equity for ' || l_date_id::text || 'and file ' ||
                           l_file_name::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    return query
    select 'title';

    return query
        select rpad(q.account_number, 8, ' '), -- as account_number,
               'S', -- as sec_id_type,
               q.sec_id, -- as sec_id
               '4'                                                                as price_code_type,
               round(sum(q.quantity * q.unit_price) / sum(q.quantity), unit_price_decimal) as unit_price,
               sum(q.quantity)                                                             as quantity,
               q.settle_date,
               q.trade_date,
               q.buy_sell_ind,
               q.short_ind                                                                 as short_ind,
               '8Z'::varchar                                                               as origin_exchange,
               '0'::varchar                                                                as trade_action,
               (case when sum(q.commission_amount) > 0 then '7' else '2' end)::varchar     as commission_type,
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
               '3Q800797'::varchar                                                         as opposing_account,
               '4'::varchar                                                                as nbr_misc_trailers,
               '2'::varchar                                                                as ae_credit_type,
               '0000'::varchar                                                             as financial_consultannt_nbr,
               '1'::varchar                                                                as exchang_1,
               '00'::varchar                                                               as percent_1,
               q.acted_as_ind,
               null::varchar                                                               as automated_trade_ind,
               null::varchar                                                               as tif_sec_fe_spp_rsn_cd,
               null::varchar                                                               as blue_sheet_acct_typ_ind,
               '160000'::varchar                                                           as exec_time,
               'Y'::varchar                                                                as taf_exemption_ind,
               null::varchar                                                               as td_xtnl_cli_rf_no
        from (select
                  --null::varchar as entity,
                  case
                      --when a.account_name in ('SAXOPROPCROSS', 'SAXORET') then a.account_name
                      when a.account_name in ('CIC3921C', 'CICMARCHES', 'ITAC') then tr.client_order_id
                      else null
                      end::varchar                                                                         as entity,
                  a.account_name,
                  case
                      when a.trading_firm_id = 'rhumba01'
                          then coalesce(c2a.ml_account, mb.ml_account) --Rhumbline Advisers
                      else mb.ml_account
                      end::varchar                                                                         as account_number,
                  replace(hsd.display_instrument_id, ' ', '')::varchar                                     as sec_id,
                  tr.last_px                                                                               as unit_price,
                  last_qty                                                                                 as quantity,
                  to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date, tr.instrument_type_id),
                          'YYYYMMDD')::varchar                                                             as settle_date,
                  to_char(tr.trade_record_time, 'YYYYMMDD')::varchar                                       as trade_date,
                  (case
                       when tr.side = '1' then '1'
                       when tr.side in ('2', '5', '6')
                           then '2' end)::varchar                                                          as buy_sell_ind,
                  --null::varchar as short_ind,
                  case
                      when tr.side in ('5', '6') then '1'
                      else null
                      end::varchar                                                                         as short_ind,
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
                      end                                                                                  as commission_amount,
                  coalesce(a.eq_order_capacity, 'A')::varchar                                              as acted_as_ind,
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
                and tr.date_id = l_date_id
                and tr.instrument_type_id = 'E'
                and tr.is_busted = 'N'
                and hsd.symbol not in ('ZVZZT')

              union all

              select tr.trading_firm_id                                                                             as entity,
                     a.account_name,
                     '3Q801987'::varchar                                                                            as account_number,
                     replace(hsd.display_instrument_id, ' ', '')::varchar                                           as sec_id,
                     tr.last_px                                                                                     as unit_price,
                     last_qty                                                                                       as quantity,
                     to_char(public.get_settle_date_by_instrument_type(tr.trade_record_time::date,
                                                                       tr.instrument_type_id),
                             'YYYYMMDD')::varchar                                                                   as settle_date,
                     to_char(tr.trade_record_time, 'YYYYMMDD')::varchar                                             as trade_date,
                     (case
                          when tr.side = '1' then '1'
                          when tr.side in ('2', '5', '6')
                              then '2' end)::varchar                                                                as buy_sell_ind,
                     --null::varchar as short_ind,
                     case
                         when tr.side in ('5', '6') then '1'
                         else null
                         end::varchar                                                                               as short_ind,
                     0.0 * tr.last_qty                                                                              as commission_amount,
                     coalesce(a.eq_order_capacity, 'A')::varchar                                                    as acted_as_ind,
                     4                                                                                              as unit_price_decimal
              from dwh.flat_trade_record tr
                       join dwh.d_account a on (a.account_id = tr.account_id)
                       join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                       join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
              where tr.date_id = l_date_id
                and tr.instrument_type_id = 'E'
                and tr.is_busted = 'N'
                and tr.trading_firm_id in ('pegasus', 'fnyqsg', 'fnyinva01') --'fnyglob01'
                and hsd.symbol not in ('ZVZZT')
                and l_file_name = 'BCT221XA') as q
        group by q.entity, q.account_number, q.sec_id, q.settle_date, q.trade_date, q.buy_sell_ind, q.short_ind,
                 q.acted_as_ind, q.unit_price_decimal
        order by q.trade_date, q.account_number, q.sec_id, q.buy_sell_ind;
end;
$function$
;

select rpad('os', 8, ' ') || 'eol'