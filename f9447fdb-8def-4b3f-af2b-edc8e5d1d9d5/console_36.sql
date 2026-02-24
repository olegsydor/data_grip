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

select jsn->>'trade_record_id', jsn->>'alloc_config_id'
   from whole


select (jsn->>'trade_record_id')::int8,
       (jsn->>'account_id')::int4,
       (jsn->>'instrument_id')::int8,
       (jsn->>'last_qty')::int4,
       (jsn->>'allocation_avg_price')::numeric(12, 6),
       jsn->>'open_close',
       jsn->>'side',
       jsn->>'street_account_name',
       jsn->>'account_nickname',
       jsn->>'cmta',
       jsn->>'clearing_account_number',
       i.instrument_type_id
from whole
         left join genesis2.instrument i on (jsn->>'instrument_id')::int8 = i.instrument_id

select tr.trade_record_id,
       tr.account_id,
       tr.instrument_id,
       tr.last_qty,
       tr.allocation_avg_price,
       tr.open_close,
       tr.side,
       tr.street_account_name,
       tr.account_nickname,
       tr.cmta,
       tr.clearing_account_number,
       i.instrument_type_id,
       wh.jsn->>'alloc_config_id'
from genesis2.trade_record tr
         join genesis2.instrument i on tr.instrument_id = i.instrument_id
join whole wh on (wh.jsn->>'trade_record_id')::int8 = tr.trade_record_id
where date_id = in_date_id
  and trade_record_id = any (l_new_trade_record_ids)
  and is_busted = 'N'



drop table if exists slct;
create temp table slct as
select (jsonb_populate_record(rw, jsn)).*
from (select null::genesis2.trade_record         as rw,
             row_to_json(tr)::jsonb || whole.jsn as jsn
      from whole
               left join genesis2.trade_record tr on (tr.trade_record_id = whole.id and tr.date_id = :in_date_id)) slct;


    insert into genesis2.trade_record
    select * from slct;


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




-- DROP FUNCTION dash360.allocations_create(int4, int4, varchar);

CREATE OR REPLACE FUNCTION dash360.allocations_create(in_date_id integer, in_user_id integer,
                                                      in_change_vector character varying)
    RETURNS bigint
    LANGUAGE plpgsql
AS
$function$
    -- SY 20210319 Initial creation
    -- SY 20210420 DS-3363 Fix CCRU has been added
-- SY 20240716 https://dashfinancial.atlassian.net/browse/DS-8581 disable trade_record_update_ccru because the same is done inside ptm_process_trades for all commissions via flat_trade_record_inherit_fees subscription
-- SY 20240813 https://dashfinancial.atlassian.net/browse/DS-8581 Reverted
-- SY 20240816 https://dashfinancial.atlassian.net/browse/DS-8208 in_user_id has been propagated to f_get_clearing_account_id to make possible user_id autocreation save
-- SY\SO 20250704 https://dashfinancial.atlassian.net/browse/DS-10177 providing alloc_instr_entry_id into alloc_instr2trade_record
-- SO 20251220 https://dashfinancial.atlassian.net/browse/DS-10030
-- SO 20260210 https://dashfinancial.atlassian.net/browse/DS-11079 add sg_allocation_configuration
declare
    l_change_vector        jsonb;
    l_new_trade_record_ids bigint[];
    scr                    record;
    l_alloc_instr          int;
    l_load_batch_id        bigint;
    l_step_id              int;
    l_row_cnt              int;
    l_sg_alloc_config_id   int4;


begin
    l_step_id := 0;
    select nextval('genesis2.allocation_instruction_alloc_instr_id_seq'::regclass) into l_alloc_instr;
    select nextval('load_batch_load_batch_id_seq') into l_load_batch_id;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create STARTED =====', 0, 'S'::char)
    into l_step_id;


    l_change_vector := in_change_vector::jsonb;

    select min(val ->> 'alloc_config_id')
    into l_sg_alloc_config_id
    from (select jsonb_array_elements(value) as val
          from jsonb_each(l_change_vector)) x;


    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'l_change_vector converted to jsonb', 1, 'I'::char)
    into l_step_id;

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

    l_new_trade_record_ids := dash360.ptm_process_trades(in_date_id, in_user_id, l_change_vector);

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'PTM DONE', cardinality(l_new_trade_record_ids),
                             'I'::char)
    into l_step_id;


    with tr as materialized
             (select tr.trade_record_id
                   , tr.account_id
                   , tr.instrument_id
                   , tr.last_qty
                   , tr.allocation_avg_price
                   , tr.open_close
                   , tr.side
                   , tr.street_account_name
                   , tr.account_nickname
                   , tr.cmta
                   , tr.clearing_account_number
                   , i.instrument_type_id
                   , wh.jsn ->> 'alloc_config_id' as alloc_config_id
              from genesis2.trade_record tr
                       inner join genesis2.instrument i on tr.instrument_id = i.instrument_id
                       join whole wh on (wh.jsn ->> 'trade_record_id')::int8 = tr.trade_record_id
              where date_id = in_date_id
                and trade_record_id = any (l_new_trade_record_ids)
                and is_busted = 'N'),
         pre_aie as (select --l_alloc_instr,
                          -- in_date_id,
                         dash360.f_get_clearing_account_id(tr.account_id, tr.clearing_account_number,
                                                           tr.account_nickname, tr.street_account_name,
                                                           tr.instrument_type_id, in_user_id)                   as clearing_account_id
                          , tr.street_account_name
                          , tr.account_nickname
                          , sum(last_qty)                                                                       as last_qty
                          , nextval('genesis2.allocation_instruction_entry_allocation_instruction_entry_i_seq') as alloc_instr_entry_id
                          , array_agg(trade_record_id)                                                          as trade_record_ids
                          , alloc_config_id
                     from tr
                     group by clearing_account_id, street_account_name, account_nickname, alloc_config_id)
            ,
         aie as ( INSERT INTO allocation_instruction_entry (alloc_instr_id, date_id, clearing_account_id,
                                                            occ_actionable_id,
                                                            account_nickname, alloc_qty,
                                                            allocation_instruction_entry_id, sg_alloc_config_id)
             select l_alloc_instr,
                    in_date_id,
                    clearing_account_id,
                    street_account_name,
                    account_nickname,
                    last_qty,
                    alloc_instr_entry_id,
                    alloc_config_id::int4
             from pre_aie
             returning *),
         a2tr as (INSERT INTO alloc_instr2trade_record (trade_record_id, alloc_instr_id, date_id, dataset_id,
                                                        allocation_instruction_entry_id)
             select unnest(trade_record_ids), l_alloc_instr, in_date_id, l_load_batch_id, alloc_instr_entry_id
             from pre_aie
             /* inner join aie on aie.clearing_account_id = tr.clearing_account_id and
                                coalesce(tr.occ_actionable_id, '---') = coalesce(aie.occ_actionable_id, '---') and
                                coalesce(tr.account_nickname, '---') = coalesce(aie.account_nickname, '---') */ )
    INSERT
    INTO allocation_instruction
    (alloc_instr_id, date_id, create_time, account_id, instrument_id, total_qty, avg_px, open_close, side,
     created_by_user_id, dataset_id)
    select l_alloc_instr,
           in_date_id,
           clock_timestamp(),
           account_id,
           instrument_id,
           sum(last_qty),
           allocation_avg_price,
           open_close,
           side,
           in_user_id,
           l_load_batch_id
    from tr
    group by account_id, instrument_id, allocation_avg_price, open_close, side;

    GET DIAGNOSTICS l_row_cnt = ROW_COUNT;

    select genesis2.load_log(l_load_batch_id::int, l_step_id, 'Allocation tables popultaed', l_row_cnt, 'I'::char)
    into l_step_id;


    -- Fix CCRU
--    select count(1)
    -- into l_cnt;
--	from (
    perform dash360.trade_record_update_ccru(in_user_id =>in_user_id, in_date_id => in_date_id,
                                             in_trade_record_id =>l.trade_record_id, in_rate => l.rate,
                                             in_amount=>l.amount, in_load_batch_id =>l_load_batch_id::int)
    from (select tr.trade_record_id::bigint,
                 tlbr.rate,
                 tr.last_qty * tlbr.rate                                                                                 as amount,
                 row_number()
                 over (partition by tr.trade_record_id, tlbr.trade_record_id, tlbr.billing_entity order by brc.priority) as rn
          from genesis2.trade_record tr
                   inner join genesis2.trade_level_book_record tlbr
                              on tlbr.date_id = tr.date_id and tlbr.trade_record_id = tr.orig_trade_record_id and
                                 book_record_type_id = 'CCRU'
                   inner join genesis2.book_record_creator brc
                              on tlbr.book_record_creator_id = brc.book_record_creator_id
          where tr.date_id = in_date_id
            and tr.trade_record_id = any (array [l_new_trade_record_ids])) l
    where rn = 1
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

exception
    when others then
        select genesis2.load_log(l_load_batch_id::int, l_step_id,
                                 left(sqlstate || ': ' || REPLACE(sqlerrm, ''::text, ''::text), 250), 0, 'E'::char)
        into l_step_id;
        -- RAISE notice '% %', sqlstate, sqlerrm;

        select genesis2.load_log(l_load_batch_id::int, l_step_id, 'allocations_create DONE ====', 0, 'E'::char)
        into l_step_id;

        PERFORM genesis2.load_error_log('allocations_create'::varchar, 'I'::char,
                                        REPLACE(sqlerrm, ''::text, ''::text)::varchar, l_load_batch_id::int);
        RAISE;

end;
$function$
;

select instrument_id, ac.opt_occ_id, ca.occ_actionable_id, aie.occ_actionable_id, ac.*, *
 from
     genesis2.allocation_instruction ai
     join genesis2.allocation_instruction_entry aie on aie.alloc_instr_id = ai.alloc_instr_id
                                    left join genesis2.sg_allocation_configuration ca
                                              on (ca.sg_alloc_config_id = aie.sg_alloc_config_id)
                                    join genesis2.account ac on ac.account_id = ai.account_id
                           where aie.alloc_instr_id = -113865
                             and aie.date_id = 20260224;

select * from instrument
where instrument_id = 181832091