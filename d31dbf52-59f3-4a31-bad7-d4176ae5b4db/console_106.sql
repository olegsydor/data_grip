	select co.ex_destination,
	       co.sub_strategy_id,
	       di.instrument_type_id,
	       lp_priority,
	       fc.fix_comp_id,
	    co.internal_order_id,
	    co.dash_rfr_id,
	       (select imc.internal_order_id::varchar from fix_capture.fix_message_json fmj
       		  		  join dwh.client_order imc on imc.client_order_id = fmj.fix_message->>'5059'
					  join dwh.d_fix_connection dfc on fmj.fix_message->>'5060' = dfc.fix_comp_id and dfc.fix_connection_id = imc.fix_connection_id
       		  		  where fmj.date_id = co.create_date_id
       		  		  and fmj.fix_message_id= co.fix_message_id
       		  		  limit 1),
	    (select (fix_message->>'10231'::text) from dwh.flat_trade_record ftr
					  join fix_capture.fix_message_json fmj on ftr.trade_fix_message_id = fmj.fix_message_id and ftr.date_id = fmj.date_id
					  where ftr.date_id >= co.create_date_id
					  and ftr.order_id = co.order_id
					  limit 1),
	    string_to_array((case when co.ex_destination = 'ALGO' and co.sub_strategy_id in (71, 78) and di.instrument_type_id in ('M','O')
       		  	then co.internal_order_id::varchar
       		  when left(dclp.lp_priority,1) = '1' and fc.fix_comp_id = 'IMCCONS'
       		  	then (select imc.internal_order_id::varchar from fix_capture.fix_message_json fmj
       		  		  join dwh.client_order imc on imc.client_order_id = fmj.fix_message->>'5059'
					  join dwh.d_fix_connection dfc on fmj.fix_message->>'5060' = dfc.fix_comp_id and dfc.fix_connection_id = imc.fix_connection_id
       		  		  where fmj.date_id = co.create_date_id
       		  		  and fmj.fix_message_id= co.fix_message_id
       		  		  limit 1)
       		  when left(dclp.lp_priority,1) = '2' and fc.fix_comp_id = 'IMCCONS'
       		  	then (select (fix_message->>'10231'::text) from dwh.flat_trade_record ftr
					  join fix_capture.fix_message_json fmj on ftr.trade_fix_message_id = fmj.fix_message_id and ftr.date_id = fmj.date_id
					  where ftr.date_id >= co.create_date_id
					  and ftr.order_id = co.order_id
					  limit 1)
       	 end),',')|| clp.rfr_ids
-- 	into rfr_id_arr
	from dwh.client_order co
	left join consolidator.d_cons_lp_priority dclp on dclp.liquidity_provider_id = co.liquidity_provider_id
	join dwh.d_instrument di on di.instrument_id = co.instrument_id
	left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id
	left join lateral (select array_agg(clptr.rfr_id) as rfr_ids from consolidator.cons_lite_parent_to_rfr clptr
					   where clptr.date_id = co.create_date_id and clptr.parent_client_order_id = co.client_order_id) clp on true
	where co.order_id = 18287651947--in (18287651956,18287661361,18287671246)
	and co.create_date_id between :in_start_date_id and :in_end_date_id;


{7600146055494}

select * from dwh.client_order
where parent_order_id = 18287651947;



 SELECT t1.rfr_id, jsonb_agg(jsonb_build_object('date_id', date_id, 'request_numbers', request_numbers)) AS date_ids
	  FROM (
	    SELECT cm.rfr_id, cm.date_id, jsonb_agg(jsonb_build_object('request_number', request_number, 'message_type', message_type)) AS request_numbers
	    FROM consolidator.consolidator_message cm
	    where cm.rfr_id in ('7600146055495','7600146055794','7600146056080')
-- 	    and cm.date_id >= in_start_date_id
	    GROUP BY cm.rfr_id, cm.date_id
  ) AS t1
	  GROUP BY t1.rfr_id;




-- DROP FUNCTION dash360.get_rfr_msg_types_by_order_id(int8, int4, int4);

CREATE OR REPLACE FUNCTION trash.so_get_rfr_msg_types_by_order_id(in_order_id bigint, in_start_date_id integer, in_end_date_id integer DEFAULT NULL::integer)
 RETURNS TABLE(rfr_id character varying, json_arr jsonb)
 LANGUAGE plpgsql
AS $function$
-- 2024-12-09 OS added (78, 71) instead of 78 for rfr_id_arr (Slavko Dmytriv)
-- 2024-12-13 OS
declare
rfr_id_arr varchar[];
date_ids_arr int[];
BEGIN


	select string_to_array((case when co.ex_destination = 'ALGO' and co.sub_strategy_id in (71, 78) and di.instrument_type_id in ('M','O')
       		  	then co.internal_order_id::varchar
       		  when left(dclp.lp_priority,1) = '1' and fc.fix_comp_id = 'IMCCONS'
       		  	then (select imc.internal_order_id::varchar from fix_capture.fix_message_json fmj
       		  		  join dwh.client_order imc on imc.client_order_id = fmj.fix_message->>'5059'
					  join dwh.d_fix_connection dfc on fmj.fix_message->>'5060' = dfc.fix_comp_id and dfc.fix_connection_id = imc.fix_connection_id
       		  		  where fmj.date_id = co.create_date_id
       		  		  and fmj.fix_message_id= co.fix_message_id
       		  		  limit 1)
       		  when left(dclp.lp_priority,1) = '2' and fc.fix_comp_id = 'IMCCONS'
       		  	then (select (fix_message->>'10231'::text) from dwh.flat_trade_record ftr
					  join fix_capture.fix_message_json fmj on ftr.trade_fix_message_id = fmj.fix_message_id and ftr.date_id = fmj.date_id
					  where ftr.date_id >= co.create_date_id
					  and ftr.order_id = co.order_id
					  limit 1)
       	 end),',')|| clp.rfr_ids into rfr_id_arr
	from dwh.client_order co
	left join consolidator.d_cons_lp_priority dclp on dclp.liquidity_provider_id = co.liquidity_provider_id
	join dwh.d_instrument di on di.instrument_id = co.instrument_id
	left join dwh.d_fix_connection fc on fc.fix_connection_id = co.fix_connection_id
	left join lateral (select array_agg(clptr.rfr_id) as rfr_ids from consolidator.cons_lite_parent_to_rfr clptr
					   where clptr.date_id = co.create_date_id and clptr.parent_client_order_id = co.client_order_id) clp on true
	where co.order_id = in_order_id
	and co.create_date_id between in_start_date_id and in_end_date_id;



	return query
	  SELECT t1.rfr_id, jsonb_agg(jsonb_build_object('date_id', date_id, 'request_numbers', request_numbers)) AS date_ids
	  FROM (
	    SELECT cm.rfr_id, cm.date_id, jsonb_agg(jsonb_build_object('request_number', request_number, 'message_type', message_type)) AS request_numbers
	    FROM consolidator.consolidator_message cm
	    where cm.rfr_id = any(rfr_id_arr)
	    and cm.date_id >= in_start_date_id
	    GROUP BY cm.rfr_id, cm.date_id
	  ) AS t1
	  GROUP BY t1.rfr_id;
END;
$function$
;
