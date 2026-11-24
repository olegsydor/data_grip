-- https://dashfinancial.atlassian.net/browse/DS-12262
dash360.delete_broker_comm_all_rates
dash360.delete_broker_comm_rates
dash360.delete_manual_broker
dash360.set_broker_comm_rates
dash360.update_broker_comm_symbol_list
dash360.update_manual_broker
genesis2.load_broker_commission_for_trade -- NO
dash360.delete_broker_comm_symbol_list -- ??


-- DROP FUNCTION dash360.delete_broker_comm_all_rates(text, int4);

CREATE OR REPLACE FUNCTION dash360.delete_broker_comm_all_rates(in_broker_code text, in_user_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
-- PD: 20260618 https://dashfinancial.atlassian.net/browse/DS-11567 Initial creation
-- OS: 20261124 https://dashfinancial.atlassian.net/browse/DS-12262 Preserve original creator's user_id when soft-deleting/updating configuration rows
DECLARE
	l_row_count int;

BEGIN
    IF in_broker_code IS NULL OR btrim(in_broker_code) = '' THEN
        RAISE EXCEPTION 'in_broker_code is required';
    END IF;

    PERFORM 1
    FROM genesis2.manual_brokers mb
    WHERE mb.broker_code = in_broker_code
      AND mb.is_deleted = 'N';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active manual broker % was not found.', in_broker_code;
    END IF;

    insert into broker_comm_rate (rate_id, broker_unq_id, broker_code, symbol_list_unq_id, symbol_list_id,
                                  instrument_type_id, commission_type, tier_type_id, min_price, min_qty, scope_type,
                                  rate_type_id, rate, user_id, is_deleted)
    select rate_id,
           broker_unq_id,
           broker_code,
           symbol_list_unq_id,
           symbol_list_id,
           instrument_type_id,
           commission_type,
           tier_type_id,
           min_price,
           min_qty,
           scope_type,
           rate_type_id,
           rate,
           in_user_id,
           'Y'
    from broker_comm_rate
    where broker_code = in_broker_code
      and is_deleted = 'N';

	update broker_comm_rate set is_deleted = 'Y', update_time = CURRENT_TIMESTAMP
	where broker_code = in_broker_code
	and is_deleted = 'N';

	GET DIAGNOSTICS l_row_count = ROW_COUNT;

    RETURN 'Updated rows: ' || l_row_count::varchar;

END
$function$
;
