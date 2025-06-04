drop function dash360.report_surveillance_disallowed_exchanges;
create function dash360.report_surveillance_disallowed_exchanges(in_trading_firm_ids character varying[] default '{}'::character varying[],
                                                                 in_account_ids int4[] default '{}'::int4[],
                                                                 in_instrument_type_id char default null)
    returns table
            (
                export_row text
            )
    language plpgsql
as
$fn$
    -- 2024-06-04 OS https://dashfinancial.atlassian.net/browse/DEVREQ-6193
declare
    l_row_cnt     integer;
    l_account_ids int4[];
    l_load_id     integer;
    l_step_id     integer;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_surveillance_disallowed_exchanges STARTED===', 0,
                           'O')
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
    return query
        select 'Trading Firm,Account,Asset Class,Exchange Name';
    return query
        select array_to_string(array [
                                   tf.trading_firm_name, -- as "Trading Firm",
                                   a.account_name, -- as "Account",
                                   (case
                                        when ex.instrument_type_id = 'E' then 'Equity'
                                        when ex.instrument_type_id = 'O'
                                            then 'Option' end), -- as "Asset Class",
                                   ex.exchange_name -- as "Exchange Name"
                                   ], ',', '')
        from dwh.d_account2disallowed_exchange ad
                 join dwh.d_account a on (a.account_id = ad.account_id and a.is_active)
                 join dwh.d_exchange ex on (ex.exchange_id = ad.exchange_id and ex.is_active)
                 join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
        where true
          and case when l_account_ids = '{}' then true else ad.account_id = any (l_account_ids) end
          and case when in_instrument_type_id is null then true else ex.instrument_type_id = instrument_type_id end
        order by tf.trading_firm_name, a.account_name, ex.instrument_type_id, ex.exchange_name;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, 'dash360.report_surveillance_disallowed_exchanges COMPLETED ===',
                           l_row_cnt,
                           'C')
    into l_step_id;
end;
$fn$;

select *
from dash360.report_surveillance_disallowed_exchanges(in_trading_firm_ids := '{"baycrstmp"}',
                                                      in_account_ids := '{12001,68174,73716}',in_instrument_type_id := 'E');

select
	a.account_id,
    tf.trading_firm_name as "Trading Firm",
	a.account_name as "Account",
	(case when ex.instrument_type_id = 'E' then 'Equity' when ex.instrument_type_id = 'O' then 'Option' end) as "Asset Class",
	ex.exchange_name as "Exchange Name"
from dwh.d_account2disallowed_exchange ad
join dwh.d_account a on (a.account_id = ad.account_id and a.is_active )
join dwh.d_exchange ex on (ex.exchange_id = ad.exchange_id and ex.is_active )
join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
where a.trading_firm_id in ('baycrstmp')
order by tf.trading_firm_name, a.account_name, ex.instrument_type_id, ex.exchange_name;