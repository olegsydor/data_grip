-- DROP FUNCTION dash360.allocations_create(int4, int4, varchar);

CREATE FUNCTION trash.allocations_create(in_date_id integer, in_user_id integer, in_change_vector character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
 -- SY 20210319 Initial creation
 -- SY 20210420 DS-3363 Fix CCRU has been added
-- SY 20240716 https://dashfinancial.atlassian.net/browse/DS-8581 disable trade_record_update_ccru because the same is done inside ptm_process_trades for all commissions via flat_trade_record_inherit_fees subscription
-- SY 20240813 https://dashfinancial.atlassian.net/browse/DS-8581 Reverted
-- SY 20240816 https://dashfinancial.atlassian.net/browse/DS-8208 in_user_id has been propagated to f_get_clearing_account_id to make possible user_id autocreation save
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

  for scr in (select e.clearing_instr_id
                 from  clearing_instruction_entry e
                 inner join clearing_instruction ca on e.clearing_instr_id = ca.clearing_instr_id and e.date_id = ca.date_id
                 where e.date_id = in_date_id
                 and ca.status in ('P', 'C')
                 and e.trade_record_id in (select jsonb_object_keys (l_change_vector)::bigint )
                 limit 1) loop
--   raise exception using message = 'S 167', detail = 'D 167', hint = 'H 167', errcode = 'P3333';

     raise exception 'Error: Clearing change request is in progress. Please wait till it is processed' using errcode='CLRIP', /*message='Can''t be allocated due to pending clearing',*/ hint='Please finish or reject clearing request before allocating it' ;
     end loop;

  select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Before PTM', 1, 'I'::char)
  into l_step_id;

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
     pre_aie as (select l_alloc_instr
                      , in_date_id
                      , dash360.f_get_clearing_account_id(tr.account_id, tr.clearing_account_number,
                                                          tr.account_nickname, tr.street_account_name,
                                                          tr.instrument_type_id, in_user_id)                as clearing_account_id
                      , tr.street_account_name
                      , tr.account_nickname
                      , sum(last_qty) as last_qty
                      , nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as alloc_instr_entry_id,
                        array_agg(trade_record_id) as trade_record_ids
                 from tr
                 group by clearing_account_id, street_account_name, account_nickname
)
 ,      aie as( INSERT INTO allocation_instruction_entry (alloc_instr_id, date_id, clearing_account_id, occ_actionable_id, account_nickname, alloc_qty, allocation_instruction_entry_id)
			   select l_alloc_instr, in_date_id, clearing_account_id, street_account_name, account_nickname,  last_qty, alloc_instr_entry_id
			   from pre_aie
               returning *),
        a2tr as (INSERT INTO alloc_instr2trade_record (trade_record_id, alloc_instr_id, date_id, dataset_id, allocation_instruction_entry_id)
                 select trade_record_id, l_alloc_instr, in_date_id, l_load_batch_id
                 from tr
                        join pre_aie on tr.trade_record_id = any (pre_aie.trade_record_ids)
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
