-- https://dashfinancial.atlassian.net/browse/DEVREQ-8133
-- https://dashfinancial.atlassian.net/browse/DS-11455

create or replace function dash360.execution_tradestation(in_start_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                       in_end_date_id integer DEFAULT public.get_dateid(CURRENT_DATE),
                                                       in_trading_firm_ids character varying[] DEFAULT '{}'::character varying [])
returns table (ret_row text)
language plpgsql
as $fx$
    declare

    begin

    end;
    $fx$