-- DROP FUNCTION dash360.allocations_create(int4, int4, varchar);

CREATE FUNCTION trash.so_allocations_create(in_date_id integer, in_user_id integer, in_change_vector character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
 -- SY 20210319 Initial creation
 -- SY 20210420 DS-3363 Fix CCRU has been added
-- SY 20240716 https://dashfinancial.atlassian.net/browse/DS-8581 disable trade_record_update_ccru because the same is done inside ptm_process_trades for all commissions via flat_trade_record_inherit_fees subscription
-- SY 20240813 https://dashfinancial.atlassian.net/browse/DS-8581 Reverted
-- SY 20240816 https://dashfinancial.atlassian.net/browse/DS-8208 in_user_id has been propagated to f_get_clearing_account_id to make possible user_id autocreation save
-- SO 20250520 https://dashfinancial.atlassian.net/browse/DS-10030 rebuilding flow
declare
 l_change_vector jsonb;
 l_new_trade_record_ids bigint[];
 scr record;
 l_alloc_instr int;
 l_load_batch_id bigint;
 l_step_id int;
 l_row_cnt int;

begin
  l_step_id:=0;
  select nextval('genesis2.allocation_instruction_alloc_instr_id_seq'::regclass) into l_alloc_instr;
  select nextval('load_batch_load_batch_id_seq')  into l_load_batch_id;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create STARTED =====', 0, 'S'::char)
	into l_step_id;


 l_change_vector:=in_change_vector::jsonb;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'l_change_vector converted to jsonb', 1, 'I'::char)
  into l_step_id;

  -- checking if any of the trades from change_vector is in progress of clearing change request now
  for scr in (select e.clearing_instr_id
              from clearing_instruction_entry e
                       inner join clearing_instruction ca
                                  on e.clearing_instr_id = ca.clearing_instr_id and e.date_id = ca.date_id
              where e.date_id = in_date_id
                and ca.status in ('P', 'C')
                and e.trade_record_id in (select jsonb_object_keys(l_change_vector)::bigint)
              limit 1)
      loop
          --   raise exception using message = 'S 167', detail = 'D 167', hint = 'H 167', errcode = 'P3333';

          raise exception 'Error: Clearing change request is in progress. Please wait till it is processed' using errcode = 'CLRIP', /*message='Can''t be allocated due to pending clearing',*/ hint = 'Please finish or reject clearing request before allocating it';
      end loop;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Before PTM', 1, 'I'::char)
  into l_step_id;

  insert into genesis2.allocation_instruction (alloc_instr_id, date_id, create_time, created_by_user_id)
  select l_alloc_instr, in_date_id, clock_timestamp(), in_user_id;

INSERT INTO allocation_instruction_entry (alloc_instr_id, date_id, clearing_account_id, occ_actionable_id, account_nickname, alloc_qty)


    l_new_trade_record_ids:=dash360.ptm_process_trades(in_date_id, in_user_id, l_change_vector);

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'PTM DONE', cardinality (l_new_trade_record_ids), 'I'::char)
  into l_step_id;


 with tr as materialized
            (select tr.trade_record_id, tr.account_id , tr.instrument_id,  tr.last_qty, tr.allocation_avg_price, tr.open_close , tr.side, tr.street_account_name , tr.account_nickname, tr.cmta, tr.clearing_account_number, i.instrument_type_id
              from genesis2.trade_record tr
              inner join genesis2.instrument i on tr.instrument_id =i.instrument_id
              where date_id = in_date_id
    			and trade_record_id = any(l_new_trade_record_ids)
    			and is_busted ='N'
    		 ),
       aie as( INSERT INTO allocation_instruction_entry (alloc_instr_id, date_id, clearing_account_id, occ_actionable_id, account_nickname, alloc_qty)
			   select l_alloc_instr, in_date_id, dash360.f_get_clearing_account_id(tr.account_id, tr.clearing_account_number, tr.account_nickname , tr.street_account_name , tr.instrument_type_id, in_user_id) as clearing_account_id
			   , tr.street_account_name, tr.account_nickname,  sum(last_qty)
			   from tr
			  /* inner join clearing_account ca on tr.clearing_account_number = ca.clearing_account_number
			   									and tr.account_id = ca.account_id
			   									and coalesce(tr.occ_actionable_id, '---') = coalesce(ca.occ_actionable_id, '---')
			   									and coalesce(tr.account_nickname, '---') = coalesce(ca.clearing_account_name, '---')
			   									and ca.is_deleted ='N'*/
              -- group by  tr.clearing_account_id, tr.occ_actionable_id, tr.account_nickname
			     group by 3, 4, 5

               returning *),
        a2tr as (INSERT INTO alloc_instr2trade_record (trade_record_id, alloc_instr_id, date_id, dataset_id)
                 select trade_record_id, l_alloc_instr, in_date_id, l_load_batch_id
                 from tr
                /* inner join aie on aie.clearing_account_id = tr.clearing_account_id and
                                   coalesce(tr.occ_actionable_id, '---') = coalesce(aie.occ_actionable_id, '---') and
                                   coalesce(tr.account_nickname, '---') = coalesce(aie.account_nickname, '---') */ )
   INSERT INTO allocation_instruction
	(alloc_instr_id, date_id, create_time, account_id, instrument_id, total_qty, avg_px, open_close, side, created_by_user_id,  dataset_id)
	select l_alloc_instr, in_date_id, clock_timestamp(), account_id , instrument_id,  sum(last_qty), allocation_avg_price, open_close , side, in_user_id, l_load_batch_id
    from tr
    group by account_id , instrument_id, allocation_avg_price, open_close, side;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Allocation tables popultaed', l_row_cnt, 'I'::char)
  into l_step_id;


   -- Fix CCRU
--    select count(1)
   -- into l_cnt;
--	from (
		perform dash360.trade_record_update_ccru(in_user_id =>in_user_id , in_date_id => in_date_id, in_trade_record_id =>l.trade_record_id, in_rate => l.rate, in_amount=>l.amount, in_load_batch_id =>l_load_batch_id::int)
		from (select tr.trade_record_id::bigint, tlbr.rate ,  tr.last_qty*tlbr.rate as amount  , row_number () over (partition by tr.trade_record_id, tlbr.trade_record_id, tlbr.billing_entity order by brc.priority) as rn
					from genesis2.trade_record tr
					inner join genesis2.trade_level_book_record tlbr on tlbr.date_id = tr.date_id  and tlbr.trade_record_id = tr.orig_trade_record_id and book_record_type_id ='CCRU'
					inner join genesis2.book_record_creator brc on tlbr.book_record_creator_id = brc.book_record_creator_id
					where tr.date_id = in_date_id
					and tr.trade_record_id = any(array[l_new_trade_record_ids]) ) l
		where rn=1
--				) L2
			;
  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'CCRU subscribed', 0, 'I'::char)
  into l_step_id;


  Perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id,
			  					 in_row_cnt => 1,
			  					 in_subscription_name => 'allocation_to_big_data',
			  					 in_source_table_name => 'genesis2.allocation_instruction',
			  					 in_date_id => in_date_id);

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Allocations subscribed', 0, 'I'::char)
  into l_step_id;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'DONE', 0, 'E'::char)
  into l_step_id;

   return l_alloc_instr;

 exception when others then
   select genesis2.load_log(l_load_batch_id::int, l_step_id, left(sqlstate||': '||REPLACE(sqlerrm, ''::text, ''::text),250), 0, 'E'::char)
   into l_step_id;
 -- RAISE notice '% %', sqlstate, sqlerrm;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create DONE ====', 0, 'E'::char)
  into l_step_id;

  PERFORM genesis2.load_error_log('allocations_create'::varchar,  'I'::char, REPLACE(sqlerrm, ''::text, ''::text)::varchar, l_load_batch_id::int);
  RAISE;

end;
 $function$
;

/*



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