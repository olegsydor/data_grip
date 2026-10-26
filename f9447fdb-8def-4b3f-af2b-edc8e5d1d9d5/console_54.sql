-- https://dashfinancial.atlassian.net/browse/DS-12217
-- OCC positions in Dash Account (v2)
create or replace function occ_data.occ_position_in_dash_account(in_date_id int4 default to_char(current_date, 'YYYYMMDD')::int,
                                                                 in_record_source varchar[] default null::varchar[])
    returns table
            (
                "OCC Position"           text,
                "Instrument"             varchar(100),
                "Underlying Symbol"      varchar,
                "Avg Price"              numeric,
                "Position Qty"           int8,
                "Account Name"           text,
                "O/C"                    varchar,
                "Exec Broker"            text,
                "Clearing Member Number" text,
                "OCC AID"                varchar,
                "Trading Firm"           text,
                "Notional Value"         numeric,
                "First Trade Exec Time"  text,
                "Last Trade Exec Time"   text,
                "Reported Date"          text,
                "Report Generation Time" text
            )
    language plpgsql
as
$fx$
declare

begin
    drop table if exists tmp_occ_trades;
    create temp table tmp_occ_trades as
    with occ_trades_filtered
        as (select otd.instrument_id,
                   otd.open_close,
                   otd.customer_acct_originator,
                   otd.clearing_member_number,
                   otd.side,
                   otd.last_qty,
                   otd.last_px,
                   otd.symbol,
                   otd.pg_db_create_time,
                   otd.exec_broker_originator,
                   otd.exec_time_originator,
                   otd.date_id,
                   otd.trade_id
            from occ_data.occ_trade_data as otd
            where otd.date_id = in_date_id
              and (
                (coalesce(cardinality(in_record_source), 0) = 0
                    and otd.clearing_member_number = any (array ['00333', '00733', '333', '733']))
                    or ('333' = any (in_record_source) and otd.clearing_member_number = any (array ['00333', '333']))
                    or ('733' = any (in_record_source) and otd.clearing_member_number = any (array ['00733', '733']))
                )
              and otd.gup_clearing_firm_originator is null
              and otd.trade_type = '0'
              and not exists (select null
                              from occ_data.occ_trade_data x
                              where x.rpt_id = otd.rpt_id
                                and x.side = otd.side
                                and x.trans_type = '1'
                                and x.date_id = in_date_id
                                and (
                                  (coalesce(cardinality(in_record_source), 0) = 0
                                      and x.clearing_member_number = any (array ['00333', '00733', '333', '733']))
                                      or ('333' = any (in_record_source) and
                                          x.clearing_member_number = any (array ['00333', '333']))
                                      or ('733' = any (in_record_source) and
                                          x.clearing_member_number = any (array ['00733', '733']))
                                  )
                                and x.gup_clearing_firm_originator is null))
       , occ_trade_data_matching_filtered as (select distinct on (otdm.trade_id) otdm.rpt_id,
                                                                                 otdm.date_id,
                                                                                 otdm.trade_id,
                                                                                 otdm.side,
                                                                                 otdm.account_id
                                              from occ_data.occ_trade_data_matching otdm
                                              where otdm.date_id = in_date_id
                                                and otdm.trade_record_id <> -1)
    select otd.instrument_id,
           otd.open_close,
           otd.customer_acct_originator,
           case
               when count(distinct otd.clearing_member_number) = 1
                   then min(otd.clearing_member_number)
               end                                               as cmta,
           sum(
                   case
                       when otd.side = '1' then otd.last_qty
                       when otd.side = '2' then -otd.last_qty
                       else 0
                       end
           )                                                     as position_qty,
           round(
                   sum(
                           case
                               when otd.side = '1'
                                   then otd.last_qty * otd.last_px
                               when otd.side = '2'
                                   then -(otd.last_qty * otd.last_px)
                               else 0
                               end
                   )::numeric,
                   6
           )                                                     as notional_value,
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
    group by otd.date_id, otd.instrument_id, otd.open_close, otd.customer_acct_originator,
             otd.symbol;

    return query
        select i.instrument_name || ' ' || abs(otd.position_qty) || ' ' ||
               case
                   when otd.position_qty >= 0 then 'Bought'
                   else 'Sold'
                   end || ' @ ' ||
               case
                   when otd.position_qty = 0 then 0
                   else round(otd.notional_value / otd.position_qty, 6)
                   end ||
               case
                   when i.last_trade_date is not null then ' @ ' ||
                                                           to_char(i.last_trade_date, 'DDMONYYYY')
                   else '' end                                               as "OCC Position",
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
               abs(otd.notional_value)                                       as "Notional Value",
               to_char(otd.first_trade_exec_time, 'MM/DD/YYYY HH24:MI:SS')   as "First Trade Exec Time",
               to_char(otd.last_trade_exec_time, 'MM/DD/YYYY HH24:MI:SS')    as "Last Trade Exec Time",
               to_char(to_date(otd.reported_date, 'YYYYMMDD'), 'MM/DD/YYYY') as "Reported Date",
               to_char(now(), 'MM/DD/YYYY HH24:MI:SS')                       as "Report Generation Time"
        from tmp_occ_trades otd
                 left join genesis2.instrument i on otd.instrument_id = i.instrument_id
        order by i.display_instrument_id2,
                 otd.customer_acct_originator,
                 otd.open_close desc;
end;
$fx$;

select *
from occ_data.occ_position_in_dash_account();

select *
from occ_data.occ_position_in_dash_account(in_record_source := '{"333","733"}');

select *
from occ_data.occ_position_in_dash_account(in_record_source := '{"733"}');

select *
from occ_data.occ_position_in_dash_account(in_record_source := '{"333"}');


select *
from occ_data.occ_position_in_dash_account(in_date_id := 20261026, in_record_source := '333');

select *
from occ_data.occ_position_in_dash_account();

select *
from occ_data.occ_position_in_dash_account();

select to_char(i.last_trade_date, 'DDMONYYYY')
from instrument i

select '{1,2,3}'::int4[] && 7