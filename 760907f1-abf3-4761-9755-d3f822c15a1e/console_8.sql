create schema external_data;
create schema external_data_partitions;


-- external_data.activ_us_equity_option definition

-- Drop table

-- DROP TABLE external_data.activ_us_equity_option;

CREATE TABLE external_data.activ_us_equity_option (
	permission_id int4 NULL,
	state int4 NULL,
	bid_condition varchar(5) NULL,
	record_status int4 NULL,
	update_id int4 NULL,
	bid_size int4 NULL,
	bid float8 NULL,
	bid_time time(3) NULL,
	bid_exchange varchar(10) NULL,
	ask_time time(3) NULL,
	ask_condition varchar(10) NULL,
	last_update_date date NULL,
	ask_size int4 NULL,
	ask float8 NULL,
	ask_exchange varchar(10) NULL,
	quote_date date NULL,
	previous_close float8 NULL,
	option_type bpchar(1) NULL,
	create_date date NULL,
	trade_size int4 NULL,
	trade float8 NULL,
	trade_exchange varchar(10) NULL,
	trade_date date NULL,
	"open" float8 NULL,
	expiration_type int4 NULL,
	close_date date NULL,
	cumulative_value float8 NULL,
	trade_id varchar(20) NULL,
	trade_high float8 NULL,
	entity_type int4 NULL,
	close_status int4 NULL,
	cumulative_price float8 NULL,
	trade_time time(3) NULL,
	previous_trading_date date NULL,
	trade_low float8 NULL,
	closing_quote_date date NULL,
	trade_count int4 NULL,
	previous_trade_time time(3) NULL,
	reset_date date NULL,
	"close" float8 NULL,
	previous_quote_date date NULL,
	cumulative_volume int4 NULL,
	closing_bid float8 NULL,
	previous_open float8 NULL,
	closing_bid_exchange varchar(5) NULL,
	trade_correction_time time(3) NULL,
	closing_ask float8 NULL,
	trade_condition varchar(10) NULL,
	previous_trade_high float8 NULL,
	close_cumulative_volume_date date NULL,
	strike_price float8 NULL,
	previous_ask float8 NULL,
	open_exchange varchar(10) NULL,
	previous_trade_low float8 NULL,
	close_cumulative_volume_status int4 NULL,
	trade_id_cancel varchar(10) NULL,
	net_change float8 NULL,
	life_time_high float8 NULL,
	close_cumulative_value_tatus int4 NULL,
	mic varchar(10) NULL,
	previous_net_change float8 NULL,
	trade_low_time time(3) NULL,
	life_time_low float8 NULL,
	close_cumulative_volume int4 NULL,
	percent_change float8 NULL,
	trade_id_original varchar(10) NULL,
	"close_cumulative_vValue" float8 NULL,
	trade_high_time time(3) NULL,
	trade_correction_date date NULL,
	trade_id_corrected varchar(10) NULL,
	previous_cumulative_volume int4 NULL,
	previous_bid float8 NULL,
	trade_high_exchange varchar(10) NULL,
	open_interest_date date NULL,
	local_code varchar(21) NULL,
	trade_low_exchange varchar(10) NULL,
	previous_open_interest_date date NULL,
	context int4 NULL,
	close_exchange varchar(10) NULL,
	previous_cumulative_value float8 NULL,
	open_time time(3) NULL,
	life_time_high_date date NULL,
	open_interest int4 NULL,
	closing_ask_exchange varchar(2) NULL,
	previous_cumulative_volume_date date NULL,
	previous_percent_change float8 NULL,
	trade_high_condition varchar(10) NULL,
	life_time_low_date date NULL,
	previous_open_interest int4 NULL,
	close_condition varchar(5) NULL,
	previous_close_date date NULL,
	previous_cumulative_price float8 NULL,
	trade_low_condition varchar(10) NULL,
	expiration_date date NULL,
	open_condition varchar(10) NULL,
	symbol varchar(20) NULL,
	load_date_id int4 NULL DEFAULT to_char(now(), 'YYYYMMDD'::text)::integer,
	load_batch_id int8 NULL
);

-- Table Triggers


CREATE TABLE external_data_partitions.activ_us_equity_option_20240201 (
	permission_id int4 NULL,
	state int4 NULL,
	bid_condition varchar(5) NULL,
	record_status int4 NULL,
	update_id int4 NULL,
	bid_size int4 NULL,
	bid float8 NULL,
	bid_time time(3) NULL,
	bid_exchange varchar(10) NULL,
	ask_time time(3) NULL,
	ask_condition varchar(10) NULL,
	last_update_date date NULL,
	ask_size int4 NULL,
	ask float8 NULL,
	ask_exchange varchar(10) NULL,
	quote_date date NULL,
	previous_close float8 NULL,
	option_type bpchar(1) NULL,
	create_date date NULL,
	trade_size int4 NULL,
	trade float8 NULL,
	trade_exchange varchar(10) NULL,
	trade_date date NULL,
	"open" float8 NULL,
	expiration_type int4 NULL,
	close_date date NULL,
	cumulative_value float8 NULL,
	trade_id varchar(20) NULL,
	trade_high float8 NULL,
	entity_type int4 NULL,
	close_status int4 NULL,
	cumulative_price float8 NULL,
	trade_time time(3) NULL,
	previous_trading_date date NULL,
	trade_low float8 NULL,
	closing_quote_date date NULL,
	trade_count int4 NULL,
	previous_trade_time time(3) NULL,
	reset_date date NULL,
	"close" float8 NULL,
	previous_quote_date date NULL,
	cumulative_volume int4 NULL,
	closing_bid float8 NULL,
	previous_open float8 NULL,
	closing_bid_exchange varchar(5) NULL,
	trade_correction_time time(3) NULL,
	closing_ask float8 NULL,
	trade_condition varchar(10) NULL,
	previous_trade_high float8 NULL,
	close_cumulative_volume_date date NULL,
	strike_price float8 NULL,
	previous_ask float8 NULL,
	open_exchange varchar(10) NULL,
	previous_trade_low float8 NULL,
	close_cumulative_volume_status int4 NULL,
	trade_id_cancel varchar(10) NULL,
	net_change float8 NULL,
	life_time_high float8 NULL,
	close_cumulative_value_tatus int4 NULL,
	mic varchar(10) NULL,
	previous_net_change float8 NULL,
	trade_low_time time(3) NULL,
	life_time_low float8 NULL,
	close_cumulative_volume int4 NULL,
	percent_change float8 NULL,
	trade_id_original varchar(10) NULL,
	"close_cumulative_vValue" float8 NULL,
	trade_high_time time(3) NULL,
	trade_correction_date date NULL,
	trade_id_corrected varchar(10) NULL,
	previous_cumulative_volume int4 NULL,
	previous_bid float8 NULL,
	trade_high_exchange varchar(10) NULL,
	open_interest_date date NULL,
	local_code varchar(21) NULL,
	trade_low_exchange varchar(10) NULL,
	previous_open_interest_date date NULL,
	context int4 NULL,
	close_exchange varchar(10) NULL,
	previous_cumulative_value float8 NULL,
	open_time time(3) NULL,
	life_time_high_date date NULL,
	open_interest int4 NULL,
	closing_ask_exchange varchar(2) NULL,
	previous_cumulative_volume_date date NULL,
	previous_percent_change float8 NULL,
	trade_high_condition varchar(10) NULL,
	life_time_low_date date NULL,
	previous_open_interest int4 NULL,
	close_condition varchar(5) NULL,
	previous_close_date date NULL,
	previous_cumulative_price float8 NULL,
	trade_low_condition varchar(10) NULL,
	expiration_date date NULL,
	open_condition varchar(10) NULL,
	symbol varchar(20) NULL,
	load_date_id int4 NULL DEFAULT to_char(now(), 'YYYYMMDD'::text)::integer,
	load_batch_id int8 NULL,
	CONSTRAINT chk_activ_us_equity_option_20240201 CHECK ((load_date_id = 20240201))
)
INHERITS (external_data.activ_us_equity_option);


-- DROP FUNCTION external_data.activ_us_equity_option_part_func();

CREATE OR REPLACE FUNCTION external_data.activ_us_equity_option_part_func()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE

    load_date	    varchar(8)        := '';
    table_part      varchar(255)        := '';
    scheme 	    varchar(255) 	:= 'external_data_partitions.';

    a varchar(255)	:= '';
BEGIN
    table_part := scheme || TG_TABLE_NAME || '_'||NEW.load_date_id::TEXT ;
    load_date := NEW.load_date_id::TEXT;

    a := TG_TABLE_NAME || '_'||load_date ;

    PERFORM 1 FROM pg_class
    WHERE relname = a limit 1;

    IF NOT FOUND
    THEN
     EXECUTE 'CREATE TABLE ' || table_part || '
				( LIKE  external_data.'|| TG_TABLE_NAME ||' INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES INCLUDING STORAGE INCLUDING COMMENTS, CONSTRAINT chk_' || a||' CHECK( load_date_id = ' || load_date || ' )	)';

	 EXECUTE 'ALTER TABLE ' || table_part || ' OWNER TO "dwh"';
	 execute 'ALTER TABLE '|| table_part ||' INHERIT external_data.'|| TG_TABLE_NAME ;

    END IF;


      EXECUTE 'INSERT INTO ' || table_part || ' SELECT ( (' || QUOTE_LITERAL(NEW) || ')::external_data.' || TG_TABLE_NAME || ' ).*';

    RETURN NULL;
END;
$function$
;


create trigger activ_us_equity_option_part_trg before
insert
    on
    external_data.activ_us_equity_option for each row execute function external_data.activ_us_equity_option_part_func();



-- DROP PROCEDURE db_management.migrate_inherit_to_partition(varchar, varchar, varchar, varchar, varchar, varchar);

CREATE OR REPLACE PROCEDURE db_management.migrate_inherit_to_partition(IN in_table_schema character varying,
                                                                       IN in_table_name character varying,
                                                                       IN in_partition_schema character varying,
                                                                       IN in_part_field character varying DEFAULT 'date_id'::character varying,
                                                                       IN in_part_type character varying DEFAULT 'INT'::character varying,
                                                                       IN in_part_schedule character varying DEFAULT 'DAY'::character varying)
    LANGUAGE plpgsql
AS
$procedure$
    -- Enter function body here
declare
   l_load_id int;
   l_step_id int;
   l_sql varchar;
   scr record;
   scr2 record;
   l_row_cnt bigint;
   part_ref refcursor;
   l_pk_fields varchar;
   l_pk_name varchar;
   l_is_pk_ok smallint;
begin

 select nextval('public.load_timing_seq') into l_load_id;
 l_step_id:=1;
         select public.load_log(l_load_id, l_step_id, 'MIGRATE '||in_table_name||' STARTED', 0, 'O')
         into l_step_id;

  SELECT tc.constraint_name, string_agg( '"'||c.column_name||'"', ',') , max(case lower(c.column_name) when lower(in_part_field) then 1 else 0 end) as pk_ok
             into l_pk_name, l_pk_fields, l_is_pk_ok
                FROM information_schema.table_constraints tc
                JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
                JOIN information_schema.columns  c ON c.table_schema = tc.constraint_schema
                  AND tc.table_name = c.table_name AND ccu.column_name = c.column_name
                WHERE constraint_type = 'PRIMARY KEY' and tc.table_name = in_table_name
                and tc.table_schema=in_table_schema
           group by tc.constraint_name;

          if l_is_pk_ok = 0
          then
                            select public.load_log(l_load_id, l_step_id, 'PK must contains '||in_part_field||' field', 0, 'O')
                         into l_step_id;
                         raise INFO 'PK must contains % field', in_part_field;
						 execute 'ALTER TABLE '||in_table_schema||'.'||in_table_name||' DROP CONSTRAINT '||l_pk_name;
                         l_pk_fields:=l_pk_fields||','||in_part_field;
        end if;
       -- added for tables with oids;



         if (select count(1) from pg_class c
                                                JOIN pg_namespace n ON n.oid = c.relnamespace
                                              where c.relname = in_table_name and n.nspname = in_table_schema and relkind ='p') = 0
              then

              for scr in (select * from pg_indexes where tablename=in_table_name and schemaname=in_table_schema) loop
                      execute 'ALTER INDEX '||scr.schemaname||'.'||scr.indexname||' RENAME TO '||scr.indexname||'_old';
                     end loop;

                       execute 'alter table '||in_table_schema||'.'||in_table_name||' rename to '||in_table_name||'_old';

                         select public.load_log(l_load_id, l_step_id, in_table_schema||'.'||in_table_name||' rename to '||in_table_name||'_old', 0, 'O')
                         into l_step_id;


                        execute 'CREATE TABLE '||in_table_schema||'.'||in_table_name||'( LIKE '||in_table_schema||'.'||in_table_name||'_old
                                         INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES INCLUDING STORAGE INCLUDING COMMENTS
                     )
                          PARTITION BY RANGE ("'||in_part_field||'") ';


                          select public.load_log(l_load_id, l_step_id, 'Partitioned table created', 0, 'O')
                         into l_step_id;
-->>>>>>>>>>>>>>>>>>>>
						execute 'ALTER TABLE '||in_table_schema||'.'||in_table_name||' OWNER to '||tableowner||';'
						from pg_catalog.pg_tables
						where schemaname = in_table_schema
						and tablename = in_table_name||'_old';

						select public.load_log(l_load_id, l_step_id, 'Owner passed', 0, 'O')
						into l_step_id;

						for scr in (
							SELECT 'GRANT '||string_agg(privilege_type, ', ')||' ON '||in_table_schema||'.'||in_table_name||' TO '||grantee||';' as run_it
							FROM   information_schema.table_privileges
							WHERE table_schema = in_table_schema
							and table_name = in_table_name||'_old'
							group by table_schema, table_name, grantee
						)
						loop
						execute scr.run_it;
						end loop;

						select public.load_log(l_load_id, l_step_id, 'Privilegs Granted', 0, 'O')
						into l_step_id;
-->>>>>>>>>>>>>>>>>>>>

       else
                         select public.load_log(l_load_id, l_step_id, in_table_schema||'.'||in_table_name||' Has already been created as partitioned', 0, 'O')
                         into l_step_id;
     end if;

     case in_part_schedule
      when 'DAY' then

      FOR scr in (select right(relname,8)::int as dt_id , c.relname
                                                                  from pg_class c
                                                                                JOIN pg_namespace n ON n.oid = c.relnamespace
                                                                              where c.relname like  in_table_name||'_________'  and n.nspname =in_partition_schema and relkind  in ('r')
                                                                               and not relispartition
                                                                              order by 1 desc) loop
                                for  scr2 in (SELECT  tc.constraint_name, max(case c.column_name when in_part_field then 1 else 0 end) as pk_ok
                                                          FROM information_schema.table_constraints tc
                                                          JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
                                                      JOIN information_schema.columns  c ON c.table_schema = tc.constraint_schema AND tc.table_name = c.table_name AND ccu.column_name = c.column_name
                                                     WHERE constraint_type = 'PRIMARY KEY' and tc.table_name = scr.relname
                                                       and tc.table_schema=in_partition_schema
                                                 group by tc.constraint_name having max(case c.column_name when in_part_field then 1 else 0 end) = 0 ) loop

                                                 execute 'ALTER TABLE '||in_partition_schema||'.'||scr.relname||' DROP CONSTRAINT '||scr2.constraint_name;

                                                         select public.load_log(l_load_id, l_step_id, scr.dt_id||' Drop CONSTRAINT '||scr2.constraint_name, l_row_cnt::int , 'O')
                                                         into l_step_id;

                                end loop;
                                                    execute 'ALTER TABLE '||in_partition_schema||'.'||scr.relname||' NO INHERIT '||in_table_schema||'.'||in_table_name||'_old';
													-- added part for set table without oids
													/*
													if (select count(1) from pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
														where n.nspname = in_partition_schema and c.relname = scr.relname and c.relhasoids) = 1
													then
														raise INFO 'Set OIDS to OFF in the table % ', scr.relname;
														execute 'ALTER TABLE '||in_partition_schema||'.'||scr.relname||' SET WITHOUT oids;';
													end if;
													*/
													-- end of added part
                                                    execute 'ALTER TABLE '||in_table_schema||'.'||in_table_name||' ATTACH PARTITION  '||in_partition_schema||'.'||scr.relname||' FOR VALUES FROM ('||scr.dt_id||') TO ('||to_char(to_date(scr.dt_id::varchar,'YYYYMMDD')+ interval '1 day', 'YYYYMMDD')::int||')';

                                                                 select public.load_log(l_load_id, l_step_id, scr.dt_id||' ATTACHed', l_row_cnt::int , 'O')
                                                                 into l_step_id;

                                                         commit;
                                                end loop;
		when 'MONTH' then
		FOR scr in (
			select right(relname,6)::int as mn_id , c.relname
				from pg_class c
				JOIN pg_namespace n ON n.oid = c.relnamespace
			    join pg_inherits i on i.inhrelid = c.oid
				where c.relname like in_table_name||'_______'
                  and n.nspname = in_partition_schema
				and relkind  in ('r')
				and not relispartition
				order by 1 desc)
				loop
				for  scr2 in (
					SELECT  tc.constraint_name,
							max(case c.column_name when in_part_field then 1 else 0 end) as pk_ok
					FROM information_schema.table_constraints tc
					JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
					JOIN information_schema.columns  c
					ON c.table_schema = tc.constraint_schema
					AND tc.table_name = c.table_name
					AND ccu.column_name = c.column_name
					WHERE constraint_type = 'PRIMARY KEY'
					and tc.table_name = scr.relname
					AND tc.table_schema=in_partition_schema
					group by tc.constraint_name
					having max(case c.column_name when in_part_field then 1 else 0 end) = 0
					)
					loop
						execute 'ALTER TABLE '||in_partition_schema||'.'||scr.relname||' DROP CONSTRAINT '||scr2.constraint_name;
						select public.load_log(l_load_id, l_step_id, scr.mn_id||' Drop CONSTRAINT '||scr2.constraint_name, l_row_cnt::int , 'O')
						into l_step_id;
						raise INFO 'Dropped constraint - %', scr2.constraint_name;
					end loop;

					execute 'ALTER TABLE '||in_partition_schema||'.'||scr.relname||' NO INHERIT '||in_table_schema||'.'||in_table_name||'_old';
					-- added part for set table without oids
					/*
					if (select count(1) from pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
						where n.nspname = in_partition_schema and c.relname = scr.relname and c.relhasoids) = 1
					then
						raise INFO 'Set OIDS to OFF in the table % ', scr.relname;
						execute 'ALTER TABLE '||in_partition_schema||'.'||scr.relname||' SET WITHOUT oids;';
					end if;
					*/
					-- end of added part
					execute 'ALTER TABLE '||in_table_schema||'.'||in_table_name||' ATTACH PARTITION  '||in_partition_schema||'.'||scr.relname||
				   ' FOR VALUES FROM ('||scr.mn_id||'01) TO ('||to_char(to_date(scr.mn_id::varchar,'YYYYMM')+ interval '1 month', 'YYYYMMDD')::int||')';

					select public.load_log(l_load_id, l_step_id, scr.mn_id||' ATTACHed', l_row_cnt::int , 'O')
					into l_step_id;
					raise INFO 'Attached partition - %.% to table %', in_partition_schema, scr.relname, in_table_name;
				end loop;
			commit;
		end case;

         select public.load_log(l_load_id, l_step_id, 'MIGRATE '||in_table_name||' COMPLETED', 0, 'O')
         into l_step_id;

 /* exception when others then
         select public.load_log(l_load_id, l_step_id, sqlerrm , 0, 'E')
         into l_step_id;

         select public.load_log(l_load_id, l_step_id, 'MIGRATE '||in_table_name||' COMPLETED with ERROR', 0, 'O')
         into l_step_id;

           PERFORM public.load_error_log('load_trade_record_inc',  'I', sqlerrm, l_load_id);

 RAISE;
*/
end;

 $procedure$
;
--external_data.activ_us_equity_option
call db_management.migrate_inherit_to_partition(in_table_schema := 'external_data',
                                                in_table_name := 'activ_us_equity_option',
                                                in_partition_schema := 'external_data_partitions',
                                                in_part_field := 'load_date_id')





select array['ABR','AEHR','AMLP','ARRY','ASO','BBAI','BBWI','BE','BGFV','BKR','BLDR','BXMT','CANE','CDE','CFG','CL','CPER','CTRA','CWEB','D','DBI','DD','DFEN','DOCN','DRIP','DRV','DUG','DUST','DXD','EDV','EVGO','FENY','FOUR','GRAB','HIBS',
		'IAT','IEFA','ITA','ITOT','IWF','JDST','JNK','KBE','KEY','KNX','LIT','MBLY','NAIL','NOBL','NRG','NYCB','O','OHI','OKE','OMF','ONON','OVV','OZK','PATH','PBF','PSTG','QQQM','QYLD','RETL','RITM','RSP','SBLK','SCHD','SCHG','SIL',
		'SILJ','SLG','SOUN','SPLG','SPR','SPYG','SRTY','SSRM','SVIX','TECS','TFC','TOL','TUR','UBS','URA']
= array['ABR','AEHR','AMLP','ARRY','ASO','BBAI','BBWI','BE','BGFV','BKR','BLDR','BXMT','CANE','CDE','CFG','CL','CPER','CTRA','CWEB','D','DBI','DD','DFEN','DOCN','DRIP','DRV','DUG','DUST','DXD','EDV','EVGO','FENY','FOUR','GRAB','HIBS',
		'IAT','IEFA','ITA','ITOT','IWF','JDST','JNK','KBE','KEY','KNX','LIT','MBLY','NAIL','NOBL','NRG','NYCB','O','OHI','OKE','OMF','ONON','OVV','OZK','PATH','PBF','PSTG','QQQM','QYLD','RETL','RITM','RSP','SBLK','SCHD','SCHG','SIL',
		'SILJ','SLG','SOUN','SPLG','SPR','SPYG','SRTY','SSRM','SVIX','TECS','TFC','TOL','TUR','UBS','URA'];


select * from external_data.activ_us_equity_option;
select * from billing.activ;

-- insert into external_data.activ_us_equity_option(permission_id, state, bid_condition, record_status, update_id, bid_size, bid, bid_time, bid_exchange, ask_time, ask_condition, last_update_date, ask_size, ask, ask_exchange, quote_date, previous_close, option_type, create_date, trade_size, trade, trade_exchange, trade_date, open, expiration_type, close_date, cumulative_value, trade_id, trade_high, entity_type, close_status, cumulative_price, trade_time, previous_trading_date, trade_low, closing_quote_date, trade_count, previous_trade_time, reset_date, close, previous_quote_date, cumulative_volume, closing_bid, previous_open, closing_bid_exchange, trade_correction_time, closing_ask, trade_condition, previous_trade_high, close_cumulative_volume_date, strike_price, previous_ask, open_exchange, previous_trade_low, close_cumulative_volume_status, trade_id_cancel, net_change, life_time_high, close_cumulative_value_tatus, mic, previous_net_change, trade_low_time, life_time_low, close_cumulative_volume, percent_change, trade_id_original, "close_cumulative_vValue", trade_high_time, trade_correction_date, trade_id_corrected, previous_cumulative_volume, previous_bid, trade_high_exchange, open_interest_date, local_code, trade_low_exchange, previous_open_interest_date, context, close_exchange, previous_cumulative_value, open_time, life_time_high_date, open_interest, closing_ask_exchange, previous_cumulative_volume_date, previous_percent_change, trade_high_condition, life_time_low_date, previous_open_interest, close_condition, previous_close_date, previous_cumulative_price, trade_low_condition, expiration_date, open_condition, symbol, load_batch_id)
select permission_id, state, bid_condition, record_status, update_id, bid_size, bid, bid_time, bid_exchange, ask_time, ask_condition, last_update_date, ask_size, ask, ask_exchange, quote_date, previous_close, option_type, create_date, trade_size, trade, trade_exchange, trade_date, open, expiration_type, close_date, cumulative_value, trade_id, trade_high, entity_type, close_status, cumulative_price, trade_time, previous_trading_date, trade_low, closing_quote_date, trade_count, previous_trade_time, reset_date, close, previous_quote_date, cumulative_volume, closing_bid, previous_open, closing_bid_exchange, trade_correction_time, closing_ask, trade_condition, previous_trade_high, close_cumulative_volume_date, strike_price, previous_ask, open_exchange, previous_trade_low, close_cumulative_volume_status, trade_id_cancel, net_change, life_time_high, close_cumulative_value_tatus, mic, previous_net_change, trade_low_time, life_time_low, close_cumulative_volume, percent_change, trade_id_original, "close_cumulative_vValue", trade_high_time, trade_correction_date, trade_id_corrected, previous_cumulative_volume, previous_bid, trade_high_exchange, open_interest_date, local_code, trade_low_exchange, previous_open_interest_date, context, close_exchange, previous_cumulative_value, open_time, life_time_high_date, open_interest, closing_ask_exchange, previous_cumulative_volume_date, previous_percent_change, trade_high_condition, life_time_low_date, previous_open_interest, close_condition, previous_close_date, previous_cumulative_price, trade_low_condition, expiration_date, open_condition, symbol, load_batch_id
from billing.activ;
