-- DROP FUNCTION dash360.order_blotter_wave_market_data(int8, int4);

CREATE OR REPLACE FUNCTION dash360.order_blotter_wave_market_data(p_transaction_id bigint, p_date_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                instrument_id      integer,
                instrument_type_id character,
                exchange_id        character varying,
                bid_price          numeric,
                bid_quantity       bigint,
                ask_price          numeric,
                ask_quantity       bigint,
                account_id         integer
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$

-- 20220713 PD added coalesce to instrument_type_id (https://dashfinancial.atlassian.net/browse/DS-5341)
-- 20260112 OS https://dashfinancial.atlassian.net/browse/DS-10614 added account_id
begin

RETURN QUERY
	select
		i.instrument_id,
		coalesce(i.instrument_type_id,'O') as instrument_type_id,
		l1.exchange_id,
		l1.bid_price,
		l1.bid_quantity,
		l1.ask_price,
		l1.ask_quantity,
		dash360.get_account_id_by_transaction_id(l1.transaction_id, l1.start_date_id) as account_id
	from dwh.l1_snapshot l1
	left join dwh.d_instrument i on i.instrument_id=l1.instrument_id
	where
	    true
		and l1.transaction_id = p_transaction_id
		and (p_date_id is null or l1.start_date_id = p_date_id)
	order by
		i.instrument_id,
		nullif(l1.exchange_id, 'NBBO') nulls first;

end;
$function$
;
