with occ_trades_filtered as (select *
                             from occ_data.occ_trade_data as otd
                             where otd.date_id = {date_id}
                               and
                                 otd.clearing_member_number in ('00333'
                                 , '00733'
                                 , '333'
                                 , '733')
                               and
                                 otd.gup_clearing_firm_originator is null
                               and
                                 otd.trade_type = '0'
                               and not exists (
                                 select 1
                                 from occ_data.occ_trade_data x
                                 where x.rpt_id = otd.rpt_id
                               and x.side = otd.side
                               and x.trans_type = '1'
                               and x.date_id = otd.date_id
                               and x.clearing_member_number in ('00333'
                                 , '00733'
                                 , '333'
                                 , '733')
                               and x.gup_clearing_firm_originator is null
                                 )),
     occ_trade_data_matching_filtered as (select distinct on (otdm.trade_id) *
                                          from occ_data.occ_trade_data_matching otdm
                                          where otdm.date_id = {date_id}
                                            and otdm.trade_record_id <> -1
                                          order by
                                              otdm.trade_id,
                                              otdm.trade_record_id desc),
     date_time_now as (select to_char(now(), 'MM/DD/YYYY HH24:MI:SS') as generation_time),
     occ_trades as (select otd.instrument_id,
                           otd.open_close,
                           otd.customer_acct_originator,
                           case
                               when count(distinct otd.clearing_member_number) = 1
                                   then min(otd.clearing_member_number)
                               else null
                               end                                               as cmta,
                           sum(
                                   case
                                       when otd.side = '1' then otd.last_qty
                                       when otd.side = '2' then -otd.last_qty
                                       else 0
                                       end
                           )                                                     as position_qty,
                           abs(round(
                                   sum((otd.last_qty * otd.last_px) *
                                       case
                                           when otd.side = '1'
                                               then 1
                                           when otd.side = '2'
                                               then -1
                                           else 0
                                           end
                                   )::numeric,
                                   6
                               )) as notional_value,
                           otd.symbol,
                           case
                               when count(
                                            distinct
                                            case
                                                when otdm.rpt_id is not null
                                                    then a.account_name
                                                when omtr.transfer_matching_time - otd.pg_db_create_time <
                                                     interval '22 minutes'
                                                    then 'Pending'
                                                else 'Unknown'
                                                end
                                    ) = 1
                                   then min(
                                       case
                                           when otdm.rpt_id is not null
                                               then a.account_name
                                           when omtr.transfer_matching_time - otd.pg_db_create_time <
                                                interval '22 minutes'
                                               then 'Pending'
                                           else 'Unknown'
                                           end
                                        )
                               else null
                               end                                               as account,
                           string_agg(distinct otd.exec_broker_originator::text, ', '
                                      order by otd.exec_broker_originator::text) as exec_broker_originator,
                           case
                               when count(
                                            distinct
                                            case
                                                when otdm.rpt_id is not null
                                                    then tf.trading_firm_name
                                                when omtr.transfer_matching_time - otd.pg_db_create_time <
                                                     interval '22 minutes'
                                                    then 'Pending'
                                                else 'Unknown'
                                                end
                                    ) = 1
                                   then min(
                                       case
                                           when otdm.rpt_id is not null
                                               then tf.trading_firm_name
                                           when omtr.transfer_matching_time - otd.pg_db_create_time <
                                                interval '22 minutes'
                                               then 'Pending'
                                           else 'Unknown'
                                           end
                                        )
                               else null
                               end                                               as tf_name,
                           min(otd.exec_time_originator)                         as first_trade_exec_time,
                           max(otd.exec_time_originator)                         as last_trade_exec_time,
                           otd.date_id::text                                     as reported_date
                    from occ_trades_filtered as otd
                             left join occ_trade_data_matching_filtered otdm
                                       on otdm.trade_id = otd.trade_id and otdm.side = otd.side
                             left join genesis2.account a on a.account_id = otdm.account_id
                             left join genesis2.trading_firm tf on tf.trading_firm_id = a.trading_firm_id
                             left join occ_data.occ_matched_trade_record omtr on omtr.trade_id = otd.trade_id
                    where not exists (select 1
                                      from occ_data.occ_matched_trade_record omtr
                                      where omtr.trade_id = otd.trade_id
                                        and omtr.occ_transfer_to_trade_match_id is not null)
                    group by otd.date_id, otd.instrument_id, otd.open_close, otd.customer_acct_originator, otd.symbol)
select i.instrument_name || ' ' || abs(otd.position_qty) || ' ' ||
       case
           when otd.position_qty >= 0 then 'Bought'
           else 'Sold'
           end || ' @ ' ||
       case
           when otd.position_qty = 0 then 0
           else round(otd.notional_value / otd.position_qty, 6)
           end                                                       as "OCC Position",
       i.display_instrument_id2                                      as "Instrument",
       otd.symbol                                                    as "Underlying Symbol",
       case
           when otd.position_qty = 0 then 0
           else round(otd.notional_value / otd.position_qty, 6)
           end                                                       as "Avg Price",
       otd.position_qty                                              as "Position Qty",
       otd.account                                                   as "Account Name",
       otd.open_close                                                as "O/C",
       exec_broker_originator                                        as "Exec Broker",
       otd.cmta                                                      as "Clearing Member Number",
       otd.customer_acct_originator                                  as "OCC AID",
       otd.tf_name                                                   as "Trading Firm",
       otd.notional_value                                            as "Notional Value",
       to_char(otd.first_trade_exec_time, 'MM/DD/YYYY HH24:MI:SS')   as "First Trade Exec Time",
       to_char(otd.last_trade_exec_time, 'MM/DD/YYYY HH24:MI:SS')    as "Last Trade Exec Time",
       to_char(to_date(otd.reported_date, 'YYYYMMDD'), 'MM/DD/YYYY') as "Reported Date",
       dtn.generation_time                                           as "Report Generation Time"
from occ_trades otd
         left join genesis2.instrument i on otd.instrument_id = i.instrument_id
         cross join date_time_now dtn
order by i.display_instrument_id2 asc,
         otd.customer_acct_originator asc,
         otd.open_close desc


BRK.B,BRK/B
select replace(replace(:BaseCode,'.','/'),'-','/')

select regexp_replace(:BaseCode, '.|-', '/', 'g')

SELECT translate(:BaseCode, '.-', '//');