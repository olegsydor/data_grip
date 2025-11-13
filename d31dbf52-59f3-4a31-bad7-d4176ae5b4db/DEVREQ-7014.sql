-- DROP FUNCTION dash360.report_fintech_eod_saxopts_execution(int4, int4);

select * from dwh.d_account
where account_name in ('108259','113143','113144','113145','113146');

select *
from dash360.report_fintech_clear_street_client_booking(20251101, 20251111);

create or replace function dash360.report_fintech_clear_street_client_booking(in_start_date_id integer, in_end_date_id integer)
    returns table
            (
                rec text
            )
    language plpgsql
as
$fx$
-- 20251113 OS https://dashfinancial.atlassian.net/browse/DEVREQ-7014
declare
    l_load_id     int;
    l_step_id     int;
    l_row_count   int4;
    l_account_ids int4[];
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_clear_street_client_booking for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::Text || ' STARTED ====', 0,
                           'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account
    where account_name in ('108259', '113143', '113144', '113145', '113146');

    return query
        select 'type,timestamp,client_trade_id,date,account_id,quantity,price,instrument.identifier,instrument.identifier_type,instrument.country,instrument.currency,side.direction,side.qualifier,side.position,capacity,contra_mpid,exec_mpid';
    return query
        select array_to_string(ARRAY [
                                   case tr.instrument_type_id
                                       when 'O' then 'away_trade'
                                       when 'E' then 'bilateral_trade' end, -- type
                                   round(extract(EPOCH from tr.trade_record_time))::text, -- timestamp
                                   tr.exec_id::text, -- client_trade_id
                                   tr.date_id::text, -- date
                                   da.account_name, -- account_id
                                   tr.last_qty::text, -- quantity
                                   tr.last_px::text, -- price
                                   case tr.instrument_type_id
                                       when 'O' then hsd.opra_symbol
                                       when 'E' then hsd.display_instrument_id end, -- instrument.identifier
                                   'ticker', -- instrument.identifier_type
                                   'USA', -- instrument.country
                                   'USD', -- instrument.currency
                                   case tr.side
                                       when '1' then 'buy'
                                       when '2' then 'sell'
                                       when '5' then 'sell'
                                       when '6' then 'sell'
                                       end, -- side.direction
                                   case
                                       when tr.instrument_type_id = 'E' and tr.side in ('5', '6')
                                           then 'short' end, -- side.qualifier
                                   case
                                       when tr.instrument_type_id = 'O' and tr.open_close = 'O' then 'open'
                                       when tr.instrument_type_id = 'O' and tr.open_close = 'C' then 'close'
                                       end, -- side.position
                                   'principal', --capacity,
                                   'DFIN', --contra_mpid,
                                   'CSMM' --exec_mpid
                                   ], ',', '')
        from dwh.flat_trade_record tr
                 join dwh.d_account da on (da.account_id = tr.account_id)
                 join dwh.historic_security_definition_all hsd on (hsd.instrument_id = tr.instrument_id)
        where tr.date_id between in_start_date_id and in_end_date_id
          and tr.is_busted <> 'Y'
          and tr.account_id = any (l_account_ids)
          and tr.multileg_reporting_type in ('1', '2')
        order by tr.date_id, tr.trade_record_id;
    get diagnostics l_row_count = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_fintech_clear_street_client_booking FINISHED ====', l_row_count,
                           'O')
    into l_step_id;
end ;
$fx$
;
comment on function dash360.report_fintech_clear_street_client_booking is 'Clear Street Trades file for Summit Securities EOS Options Flow';