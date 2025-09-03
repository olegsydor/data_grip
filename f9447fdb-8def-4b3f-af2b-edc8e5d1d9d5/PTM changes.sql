

select '{"2347432612": [{"last_qty": 6, "trade_record_reason": "S"}, {"last_qty": 4, "trade_record_reason": "S"}], "2347432613": [{"last_qty": 6, "trade_record_reason": "S"}, {"last_qty": 4, "trade_record_reason": "S"}]}'::jsonb

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


 drop table if exists t_base;
    create temp table t_base as
        select key::bigint as id, jsonb_array_elements(value) as val
		from jsonb_each(:in_change_vector1::jsonb);

    if exists (select null
               from genesis2.trade_record tr
               join t_base on t_base.id = tr.trade_record_id
               where tr.date_id = 20250731
                 and tr.is_busted = 'Y'
                 ) then
        raise exception 'At least one of trade_records was busted before';
    end if;
    -- end (OS)

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


  drop table if exists slct;
  create temp table slct on commit drop as
  select   null::genesis2.trade_record as rw, row_to_json(tr)::jsonb || whole.jsn  as jsn-- CONCAT OLD trade_record with new values
	from whole
	left join genesis2.trade_record tr on (tr.trade_record_id = whole.id and tr.date_id = in_date_id);

GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
	raise INFO '%: create temp table slct % rows processed', clock_timestamp(), l_row_cnt;

  drop table if exists slct;
create temp table slct on commit drop as
select (jsonb_populate_record(rw, jsn)).*
from (select null::genesis2.trade_record         as rw,
             row_to_json(tr)::jsonb || whole.jsn as jsn -- CONCAT OLD trade_record with new values
      from whole
               left join genesis2.trade_record tr on (tr.trade_record_id = whole.id and tr.date_id = :in_date_id)) slct;
-------------------

-- DROP FUNCTION dash360.ptm_process_trades(int4, int4, jsonb);
alter FUNCTION dash360.ptm_process_trades rename to ptm_process_trades_old;

CREATE FUNCTION dash360.ptm_process_trades(in_date_id integer, in_user_id integer, in_change_vector jsonb)
 RETURNS bigint[]
 LANGUAGE plpgsql
AS $function$
-- OS 20210617 https://dashfinancial.atlassian.net/browse/DS-3519 The function has been rewritten to be able to process more than 1000 trades
-- SY 20230524 https://dashfinancial.atlassian.net/browse/DS-6777 Performance improvement
-- SO 20230904 https://dashfinancial.atlassian.net/browse/DS-7206 drop temp tables statments were added to prevent errors run within a single transactiongit
-- AK 20231009 https://dashfinancial.atlassian.net/browse/DS-7304 added flat_trade_record_inherit_fees subscription creation
-- OS 20250801 no task so far The fix to prevent creating new trade(s) from originally nusted trade
declare
	l_load_batch_id		int4;
	l_step_id 			int4;
	l_inserted 			int8[];
	l_origin			int8[];
	l_updated 			text;
	l_subscribed		int4;
	l_row_cnt			int4;
    l_busted_trades     text;
begin

	l_step_id:=0;
	select nextval('load_batch_load_batch_id_seq')  into l_load_batch_id;

	select genesis2.load_log(l_load_batch_id::int, l_step_id, 'ptm_process_trades STARTED ====='::varchar, 0, 'S'::char)
	into l_step_id;
	raise INFO '%: START', clock_timestamp();

    -- OS: this piece of code was added to prevent processing the trade that was already busted
    drop table if exists t_base;
    create temp table t_base as
    select key::bigint as id, jsonb_array_elements(value) as val
    from jsonb_each(in_change_vector::jsonb);

    select string_agg(distinct tr.trade_record_id::text, ', ')
    into l_busted_trades
    from genesis2.trade_record tr
             join t_base on t_base.id = tr.trade_record_id
    where tr.date_id = in_date_id
      and tr.is_busted = 'Y';

    if l_busted_trades is not null then
        raise exception 'trade_records % was\were busted before', l_busted_trades using ERRCODE = 'PTMNC';
    end if;
    -- end (OS)

   drop table if exists whole;
   create temp table whole on commit drop as
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
		'load_batch_id', l_load_batch_id,
		'user_id', in_user_id)||
		coalesce(nuls.val,'{}') as jsn
	from t_base base
	left join nuls on nuls.id = base.id;

	GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
	raise INFO '%: create temp table whole % rows processed', clock_timestamp(), l_row_cnt;

 drop table if exists slct;
create temp table slct on commit drop as
select (jsonb_populate_record(rw, jsn)).*
from (select null::genesis2.trade_record         as rw,
             row_to_json(tr)::jsonb || whole.jsn as jsn -- CONCAT OLD trade_record with new values
      from whole
               left join genesis2.trade_record tr on (tr.trade_record_id = whole.id and tr.date_id = in_date_id)) slct;

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

end;
$function$
;
select *
from trash.ptm_process_trades(in_date_id := 20250731, in_user_id := -1, in_change_vector := '{
  "2347432612": [
    {
      "last_qty": 6,
      "trade_record_reason": "S"
    },
    {
      "last_qty": 4,
      "trade_record_reason": "S"
    }
  ],
  "2347432613": [
    {
      "last_qty": 6,
      "trade_record_reason": "S"
    },
    {
      "last_qty": 4,
      "trade_record_reason": "S"
    }
  ]
}')


;


-- DROP FUNCTION trash.ptm_process_trades(int4, int4, jsonb);

CREATE or replace FUNCTION dash360.ptm_process_trades(in_date_id integer, in_user_id integer, in_change_vector jsonb)
 RETURNS bigint[]
 LANGUAGE plpgsql
AS $function$
-- OS 20210617 https://dashfinancial.atlassian.net/browse/DS-3519 The function has been rewritten to be able to process more than 1000 trades
-- SY 20230524 https://dashfinancial.atlassian.net/browse/DS-6777 Performance improvement
-- SO 20230904 https://dashfinancial.atlassian.net/browse/DS-7206 drop temp tables statments were added to prevent errors run within a single transactiongit
-- AK 20231009 https://dashfinancial.atlassian.net/browse/DS-7304 added flat_trade_record_inherit_fees subscription creation
-- OS 20250801 no task so far The fix to prevent creating new trade(s) from originally nusted trade
declare
	l_load_batch_id		int4;
	l_step_id 			int4;
	l_inserted 			int8[];
	l_origin			int8[];
	l_updated 			text;
	l_subscribed		int4;
	l_row_cnt			int4;
    l_busted_trades     text;
begin

	l_step_id:=0;
	select nextval('load_batch_load_batch_id_seq')  into l_load_batch_id;

	select genesis2.load_log(l_load_batch_id::int, l_step_id, 'ptm_process_trades STARTED ====='::varchar, 0, 'S'::char)
	into l_step_id;
	raise INFO '%: START', clock_timestamp();

    -- OS: this piece of code was added to prevent processing the trade that was already busted
    drop table if exists t_base;
    create temp table t_base as
    select key::bigint as id, jsonb_array_elements(value) as val
    from jsonb_each(in_change_vector::jsonb);

    select string_agg(distinct tr.trade_record_id::text, ', ')
    into l_busted_trades
    from genesis2.trade_record tr
             join t_base on t_base.id = tr.trade_record_id
    where tr.date_id = in_date_id
      and tr.is_busted = 'Y';

    if l_busted_trades is not null then
        raise exception 'trade_records % was\were busted before', l_busted_trades using ERRCODE = 'PTMNC';
    end if;
    -- end (OS)

   drop table if exists whole;
   create temp table whole on commit drop as
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
		'load_batch_id', l_load_batch_id,
		'user_id', in_user_id)||
		coalesce(nuls.val,'{}') as jsn
	from t_base base
	left join nuls on nuls.id = base.id;

	GET DIAGNOSTICS l_row_cnt = ROW_COUNT;
	raise INFO '%: create temp table whole % rows processed', clock_timestamp(), l_row_cnt;

 drop table if exists slct;
create temp table slct on commit drop as
select (jsonb_populate_record(rw, jsn)).*
from (select null::genesis2.trade_record         as rw,
             row_to_json(tr)::jsonb || whole.jsn as jsn -- CONCAT OLD trade_record with new values
      from whole
               left join genesis2.trade_record tr on (tr.trade_record_id = whole.id and tr.date_id = in_date_id)) slct;

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

end;
$function$
;



select '{"2347499695": [{"cmta": "123", "last_qty": 21, "account_id": 257078, "open_close": "O", "trade_text": "qty21v2", "exec_broker": "019", "opt_customer_firm": "0", "street_exec_broker": "EBS1", "trade_record_reason": "P", "trade_liquidity_indicator": "R"}]}'::jsonb
select * from genesis2.trade_record
    where trade_record_id = 2347499420


select * from trash.so_log_ptm


do
$$
    declare
        in_change_vector text := '{"2347499695": [{"cmta": "123", "last_qty": 21, "account_id": 257078, "open_close": "O", "trade_text": "qty21v2", "exec_broker": "019", "opt_customer_firm": "0", "street_exec_broker": "EBS1", "trade_record_reason": "P", "trade_liquidity_indicator": "R"}]}';
        l_busted_trades  text;
        in_date_id int4 := 20250815;
    begin
        drop table if exists t_base;
        create temp table t_base as
        select key::bigint as id, jsonb_array_elements(value) as val
        from jsonb_each(in_change_vector::jsonb);


        select string_agg(distinct tr.trade_record_id::text, ', ')
         into l_busted_trades
        from genesis2.trade_record tr
                 join t_base on t_base.id = tr.trade_record_id
        where tr.date_id = in_date_id
          and tr.is_busted = 'Y';

        if l_busted_trades is not null then
            raise exception 'trade_records % was\were busted before', l_busted_trades using ERRCODE = 'PTMNC';
        end if;
        raise notice 'AXAXA - %', l_busted_trades;
    end;
$$;

select * from t_base

select * from genesis2.trade_record
where orig_trade_record_id =2347499695


select * from dash360.clearing_complete_instruction;
    select '{ "2347499420": [ { "account_id": 257077, "open_close": "O", "last_qty": 21, "exec_broker": "019", "street_exec_broker": "EBS1", "opt_customer_firm": "1", "cmta": "123", "trade_liquidity_indicator": "R", "trade_text": "qty21", "trade_record_reason": "P" } ] }'::jsonb


    