create temp table whole  as
with base as
 	(select key::bigint as id, jsonb_array_elements(value) as val
		from jsonb_each(:in_change_vector::jsonb)),
	nuls as
   ( select y.id, jsonb_object_agg(y.key, null) as val from (select id, (jsonb_each_text(val)).*
	 from base ) y
	 where value = 'NULL'
	 group by y.id)

	 select base.id, base.val||
	  jsonb_build_object(
		'trade_record_id', nextval('trade_record_trade_record_id_seq'),
		'db_create_time', clock_timestamp(),
		'orig_trade_record_id', base.id,
		'load_batch_id', :l_load_batch_id,
		'user_id', :in_user_id)||
		coalesce(nuls.val,'{}') as jsn
	from base
	left join nuls on nuls.id = base.id;


create temp table slct as
  select   null::genesis2.trade_record as rw, row_to_json(tr)::jsonb || whole.jsn  as jsn-- CONCAT OLD trade_record with new values
	from whole
	left join genesis2.trade_record tr on (tr.trade_record_id = whole.id and tr.date_id = :in_date_id);

select * from slct2;


 create temp table slct2  as
  select   (jsonb_populate_record(rw, jsn)).*
	from slct;