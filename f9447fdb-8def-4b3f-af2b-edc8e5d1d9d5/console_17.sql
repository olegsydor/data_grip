--Executing procedure:("dash360.allocations_create"). 
-- Parameters: "@in_user_id=6690; @in_date_id=20250509; 
-- @in_change_vector={"2347039623":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":12,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040157":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":10,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040125":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":6,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347039341":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":4,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040158":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":1,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}]}; "

select jsonb_object_keys (:l_change_vector)::bigint;

select '{"2347039623":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":12,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040157":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":10,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040125":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":6,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347039341":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":4,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040158":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":1,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}]}'::jsonb;

select e.clearing_instr_id
                 from  clearing_instruction_entry e
--                  inner join clearing_instruction ca on e.clearing_instr_id = ca.clearing_instr_id and e.date_id = ca.date_id
                 where true
--     and e.date_id = :in_date_id
--                  and ca.status in ('P', 'C')
                 and e.trade_record_id in (select jsonb_object_keys (:l_change_vector)::bigint );


select * from genesis2.trade_record
                 where true
--     and e.date_id = :in_date_id
--                  and ca.status in ('P', 'C')
                 and trade_record_id in (select jsonb_object_keys (:l_change_vector)::bigint );



   create temp table whole as
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


  create temp table slct2 as
  select   (jsonb_populate_record(rw, jsn)).*
	from slct;

select * from slct2