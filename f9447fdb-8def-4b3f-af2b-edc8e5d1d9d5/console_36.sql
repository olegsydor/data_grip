select '{"2347865736":[{"cmta":"792","clearing_account_number":"792","street_account_name":"opt_aid1","account_nickname":"Option Main 1","last_qty":7,"allocation_avg_price":55.1,"trade_record_reason":"L","alloc_config_id ":364},{"cmta":"352","clearing_account_number":"352","street_account_name":"OCCAID3","account_nickname":"Option 3","last_qty":5,"allocation_avg_price":55.1,"trade_record_reason":"L","alloc_config_id ":390}]}'::jsonb


    create temp table t_base as
    select key::bigint as id, jsonb_array_elements(value) as val
    from jsonb_each(:in_change_vector::jsonb);



   drop table if exists whole;
   create temp table whole as
 	with nuls as
   ( select y.id, jsonb_object_agg(y.key, null) as val from (select id, (jsonb_each_text(val)).*
	 from t_base base) y
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
	from t_base base
	left join nuls on nuls.id = base.id;

select * from trade_record
    where trade_record_id = 2347865736;

 drop table if exists slct;
create temp table slct as
select (jsonb_populate_record(rw, jsn)).*
from (select null::genesis2.trade_record         as rw,
             row_to_json(tr)::jsonb || whole.jsn as jsn -- CONCAT OLD trade_record with new values
      from whole
               left join genesis2.trade_record tr on (tr.trade_record_id = whole.id and tr.date_id = :in_date_id)) slct;

GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
	raise INFO '%: create temp table slct % rows processed', clock_timestamp(), l_row_cnt;

    insert into genesis2.trade_record
    select * from slct;

  	GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
	raise INFO '%:  insert into genesis2.trade_record % rows processed', clock_timestamp(), l_row_cnt;

  select array_agg(slct.trade_record_id), array_agg(slct.orig_trade_record_id)
    from slct into l_inserted, l_origin;


   with upd as (
	update genesis2.trade_record
	set is_busted = 'Y'
	where date_id = in_date_id
		and trade_record_id = any(l_origin)
		and is_busted = 'N'
	returning trade_record_id as ids
	)
	select string_agg(ids::text, ', '),count(1)
	from upd
	into l_updated, l_row_cnt;

	select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Busted old trades: '||left(l_updated, 150), l_row_cnt, 'I')
	into l_step_id;
--	raise notice 'Updated: %', l_updated;

	select count(1) from (
		select genesis2.etl_subscribe(
			in_load_batch_id 		=> t.ids::int8,
			in_row_cnt 				=> 1,
			in_subscription_name 	=> 'big_data.flat_trade_record',
			in_source_table_name 	=> 'TRADE_RECORD.MANUAL_BUST',
			in_date_id 				=> in_date_id)
		from (select unnest(l_origin) as ids) t ) x
	into l_subscribed;

	select genesis2.load_log(l_load_batch_id::int, l_step_id, 'TRADE_RECORD.MANUAL_BUST Subscribed: ', l_subscribed, 'I')
	into l_step_id;

	select count(1) from (
		select genesis2.etl_subscribe(
			in_load_batch_id 		=> t.ids::int8,
			in_row_cnt 				=> 1,
			in_subscription_name 	=> 'flat_trade_record_inherit_fees',
			in_source_table_name 	=> 'TRADE_LEVEL_BOOK_RECORD',
			in_date_id 				=> in_date_id)
		from (select unnest(l_inserted) as ids) t ) x
	into l_subscribed;


	select genesis2.load_log(l_load_batch_id::int, l_step_id, 'flat_trade_record_inherit_fees Subscribed: ', l_subscribed, 'I')
	into l_step_id;
--	raise notice 'Subscribed: %', l_subscribed;

	select genesis2.load_log(l_load_batch_id::int, l_step_id, 'ptm_process_trades DONE ', 0, 'E')
	into l_step_id;


	return l_inserted;