-- DROP PROCEDURE db_management.add_partitions();

CREATE OR REPLACE PROCEDURE db_management.add_partitions()
 LANGUAGE plpgsql
AS $procedure$
 declare
  scr record;
  int_rec record;
	fk record;
  l_load_id int;
  l_step_id int;
  l_new_part_name varchar(255);
  l_existed_part_name varchar(255);
	fSource_table varchar(255);
	fPrevDT varchar(10);
  l_existed_sets text;

 begin
   select nextval('load_timing_seq') into l_load_id;
   l_step_id:=1;

 select load_log(l_load_id, l_step_id, 'DB_MANAGEMENT.ADD_PARTITIONS STARTED===', 0, 'O')
  into l_step_id;

	 for scr in (select schema_name, table_name, part_schema_name, upper(part_type) as part_type, upper(part_schedule) as part_schedule
	             from  db_management.table_partman
	             where is_active
	             order by part_priority) loop
	    if (select count(1)
	        from pg_class c
	        JOIN pg_namespace n ON n.oid = c.relnamespace
	        where c.relname = scr.table_name and n.nspname =scr.schema_name and relkind ='p') = 0
	     then select load_log(l_load_id, l_step_id, 'The Table '||scr.schema_name||'.'||scr.table_name||' does not exists or is not partitioned', 0, 'O')
				  into l_step_id;
	     else
			   case scr.part_schedule
			    when 'DAY'
			     then
			     l_existed_part_name :='';
			      for int_rec in (select dt, to_dt from (select dt, --to_char(public.get_business_date(to_date(dt::varchar,'YYYYMMDD'),1), 'YYYYMMDD')::int as to_dt
			      							 lead(dt) over (order by dt) as to_dt
			                      from unnest(public.get_last_workdate_ids_arr(22, (now() + interval '30 day')::date)) dt) dates_range
			                      where to_dt is not null
			                       union
								select dt::int, to_dt
								from (select right(child.relname,8) as dt, -1 as to_dt
									 FROM pg_inherits
								JOIN pg_class AS child ON (inhrelid=child.oid)
								JOIN pg_class as parent ON (inhparent=parent.oid)
								JOIN pg_namespace pn ON pn.oid = parent.relnamespace
								JOIN pg_namespace cn ON cn.oid = child.relnamespace
								where child.relkind not in ('i', 'f')
								  and parent.relkind not in ('i')
								  and child.relispartition
								  and pn.nspname =scr.schema_name
								  and parent.relname = scr.table_name
								  and cn.nspname = scr.part_schema_name
  								  and child.relname like parent.relname||'_________' -- table_name + date (YYYYMMDD)
								 order by child.relname	desc
								limit 1) for_like
								order by 2) loop
							/* CURSOR CONTAINS At least one existing partition. It must be the first partition */
			       l_new_part_name:=scr.part_schema_name||'.'||scr.table_name||'_'||int_rec.dt;
			        if (select Count(1)
							FROM pg_inherits
							JOIN pg_class AS child ON (inhrelid=child.oid)
							JOIN pg_class as parent ON (inhparent=parent.oid)
							JOIN pg_namespace pn ON pn.oid = parent.relnamespace
							JOIN pg_namespace cn ON cn.oid = child.relnamespace
							where child.relkind not in ('i')
							  and parent.relkind not in ('i')
							  and child.relispartition
							  and pn.nspname =scr.schema_name
							  and parent.relname = scr.table_name
							  and child.relname = scr.table_name||'_'||int_rec.dt
							  and cn.nspname = scr.part_schema_name) = 0
						then /* Partition needs to be created */
						  select load_log(l_load_id, l_step_id, 'DAILY Partition '||l_new_part_name||' needs to be added ', 0, 'O')
						  into l_step_id;

						 RAISE NOTICE 'l_existed_part_name is %', l_existed_part_name;

						  execute 'CREATE TABLE '||l_new_part_name||'( LIKE '||l_existed_part_name||' INCLUDING ALL);';
						  execute 'ALTER TABLE '||scr.schema_name||'."'||scr.table_name||'" ATTACH PARTITION '||l_new_part_name||'  FOR VALUES FROM (' ||int_rec.dt||') TO ('||int_rec.to_dt||')';
                          if l_existed_sets is not null
                           then
--                          raise notice '%', l_existed_sets;
                            execute 'ALTER TABLE '||l_new_part_name||' set ('||l_existed_sets||')';
                          end if;
						  commit;

						  select load_log(l_load_id, l_step_id, 'DAILY Partition '||l_new_part_name||' added ', 0, 'O')
						  into l_step_id;

						 -- Create Foreign key from partition to partition \/
						 fSource_table := replace(l_existed_part_name, scr.part_schema_name||'.',''); -- orig partition to copy the FK
						 for fk in (SELECT nsp.nspname, rel.relname, con."oid", con.conname
       										FROM pg_catalog.pg_constraint con
							           		INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
							            INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace
							       			WHERE nsp.nspname = scr.part_schema_name
							             AND rel.relname = fSource_table
							            and con.contype = 'f' ) loop
								if (SELECT count(1) -- check whether constrain already exists on new partition
       								FROM pg_catalog.pg_constraint con
						            INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = connamespace
					       			WHERE nsp.nspname = scr.part_schema_name
							       	AND con.conname = replace(fk.conname, fPrevDT, int_rec.dt::text) -- new constraint name
							        AND con.contype = 'f') = 0 then
									raise notice 'FK Constraint to be created for %', l_new_part_name;
							 		execute replace(format('alter table %s add constraint %s %s', l_new_part_name, fk.conname, pg_get_constraintdef(fk.oid)), fPrevDT, int_rec.dt::text);
							 	else
							 		raise notice '************  FK Constraint already exists for %', l_new_part_name;
								end if;
						 end loop;
						-- Create Foreign key from partition to partition /\

						else
						 if l_existed_part_name = ''
						 then
							select load_log(l_load_id, l_step_id, 'Last table '||scr.schema_name||'.'||scr.table_name||' partition is '||l_new_part_name||'', 0, 'O')
						  	into l_step_id;
						 else
						 	select load_log(l_load_id, l_step_id, 'DAILY Partition '||l_new_part_name||' already exists', 0, 'O')
						  	into l_step_id;
						  end if;

                          l_existed_part_name:=	scr.part_schema_name||'.'||scr.table_name||'_'||int_rec.dt;
                          l_existed_sets = (select array_to_string(reloptions, ',')
                                            from pg_class c
                                                     join pg_namespace n on (n.oid = c.relnamespace)
                                            where nspname = scr.part_schema_name
                                              and relname = scr.table_name||'_'||int_rec.dt);
							fPrevDT := int_rec.dt::text;
						end if;
		            end loop; /* 10 day forwar loop to create some extra partitions*/
				when 'MONTH'
			     then
			     l_existed_part_name :='';
			      for int_rec in (
							select dt, to_dt from (select to_char(dt,'YYYYMM')::int as dt, (lead(to_char(dt,'YYYYMM')) over (order by dt))::int as to_dt
							from generate_series(now(), now()+interval '5 month', '1 month') dt) month_range
							where to_dt is not null
							union
							select dt::int, to_dt::int
							from (
							select right(child.relname,6) as dt, -1 as to_dt
								 FROM pg_inherits
							JOIN pg_class AS child ON (inhrelid=child.oid)
							JOIN pg_class as parent ON (inhparent=parent.oid)
							JOIN pg_namespace pn ON pn.oid = parent.relnamespace
							JOIN pg_namespace cn ON cn.oid = child.relnamespace
							where child.relkind not in ('i', 'f')
							  and parent.relkind not in ('i')
							  and child.relispartition
							  and pn.nspname =scr.schema_name
							  and parent.relname = scr.table_name
							  and cn.nspname = scr.part_schema_name
							  and child.relname like parent.relname||'_______' --table_name + date(YYYYMM)
							order by child.relname	desc
							limit 1) for_like
							order by 2) loop
			       l_new_part_name:=scr.part_schema_name||'."'||scr.table_name||'_'||int_rec.dt||'"';
			        if (select Count(1)
							FROM pg_inherits
							JOIN pg_class AS child ON (inhrelid=child.oid)
							JOIN pg_class as parent ON (inhparent=parent.oid)
							JOIN pg_namespace pn ON pn.oid = parent.relnamespace
							JOIN pg_namespace cn ON cn.oid = child.relnamespace
							where child.relkind not in ('i')
							  and parent.relkind not in ('i')
							  and child.relispartition
							  and pn.nspname =scr.schema_name
							  and parent.relname = scr.table_name
							  and child.relname = scr.table_name||'_'||int_rec.dt
							  and cn.nspname = scr.part_schema_name) = 0
						then /* Partition needs to be created */
						  select load_log(l_load_id, l_step_id, 'MONTHLY Partition '||l_new_part_name||' need to be added ', 0, 'O')
						  into l_step_id;
						  --raise notice '%, %', l_new_part_name, l_existed_part_name;
						  execute 'CREATE TABLE '||l_new_part_name||'( LIKE '||l_existed_part_name||' INCLUDING ALL);';
						  execute 'ALTER TABLE '||scr.schema_name||'."'||scr.table_name||'" ATTACH PARTITION '||l_new_part_name||'  FOR VALUES FROM (' ||int_rec.dt||'01) TO ('||int_rec.to_dt||'01)';
--						  execute 'CREATE TABLE '||l_new_part_name||' PARTITION OF '||scr.schema_name||'.'||scr.table_name||' FOR VALUES FROM ('||int_rec.dt||'01) TO ('||int_rec.dt::int+1||'01)';
                          if l_existed_sets is not null then
--                          raise notice '%', l_existed_sets;
                            execute 'ALTER TABLE '||l_new_part_name||' set ('||l_existed_sets||')';
                          end if;
						  commit;

						  select load_log(l_load_id, l_step_id, l_new_part_name||' added ', 0, 'O')
						  into l_step_id;
						else
						 if l_existed_part_name = ''
						 then
							select load_log(l_load_id, l_step_id, 'Last table '||scr.schema_name||'.'||scr.table_name||' partition is '||l_new_part_name||'', 0, 'O')
						  	into l_step_id;
						 else
						 	select load_log(l_load_id, l_step_id, 'MONTHLY Partition '||l_new_part_name||' already exists', 0, 'O')
						  	into l_step_id;
						  end if;

						 l_existed_part_name:=	scr.part_schema_name||'."'||scr.table_name||'_'||int_rec.dt||'"';
                          l_existed_sets = (select array_to_string(reloptions, ',')
                                            from pg_class c
                                                     join pg_namespace n on (n.oid = c.relnamespace)
                                            where nspname = scr.part_schema_name
                                              and relname = scr.table_name||'_'||int_rec.dt);
						end if;
		            end loop; /* 4 months */

   		       when 'YEAR'
			     then
			     l_existed_part_name :='';
			      for int_rec in (
							select dt, to_dt from (select to_char(dt,'YYYY')::int as dt, (lead(to_char(dt,'YYYY')) over (order by dt))::int as to_dt
							from generate_series(now(), now()+interval '2 year', '1 year') dt) year_range
							where to_dt is not null
							union
							select dt::int, to_dt::int
							from (
							select right(child.relname,4) as dt, -1 as to_dt
								 FROM pg_inherits
							JOIN pg_class AS child ON (inhrelid=child.oid)
							JOIN pg_class as parent ON (inhparent=parent.oid)
							JOIN pg_namespace pn ON pn.oid = parent.relnamespace
							JOIN pg_namespace cn ON cn.oid = child.relnamespace
							where child.relkind not in ('i', 'f')
							  and parent.relkind not in ('i')
							  and child.relispartition
							  and pn.nspname =scr.schema_name
							  and parent.relname = scr.table_name
							  and cn.nspname = scr.part_schema_name
							  and child.relname like parent.relname||'_____' --table_name + date(YYYY)
							order by child.relname	desc
							limit 1) for_like
							order by 2) loop
			       l_new_part_name:=scr.part_schema_name||'."'||scr.table_name||'_'||int_rec.dt||'"';
			        if (select Count(1)
							FROM pg_inherits
							JOIN pg_class AS child ON (inhrelid=child.oid)
							JOIN pg_class as parent ON (inhparent=parent.oid)
							JOIN pg_namespace pn ON pn.oid = parent.relnamespace
							JOIN pg_namespace cn ON cn.oid = child.relnamespace
							where child.relkind not in ('i')
							  and parent.relkind not in ('i')
							  and child.relispartition
							  and pn.nspname =scr.schema_name
							  and parent.relname = scr.table_name
							  and child.relname = scr.table_name||'_'||int_rec.dt
							  and cn.nspname = scr.part_schema_name) = 0
						then /* Partition needs to be created */
						  select load_log(l_load_id, l_step_id, 'YEAR Partition '||l_new_part_name||' needs to be added ', 0, 'O')
						  into l_step_id;

						  execute 'CREATE TABLE '||l_new_part_name||'( LIKE '||l_existed_part_name||' INCLUDING ALL);';
						  execute 'ALTER TABLE '||scr.schema_name||'."'||scr.table_name||'" ATTACH PARTITION '||l_new_part_name||'  FOR VALUES FROM (' ||int_rec.dt||'0101) TO ('||int_rec.to_dt||'0101)';
						  if l_existed_sets is not null then
--                          raise notice '%', l_existed_sets;
                            execute 'ALTER TABLE '||l_new_part_name||' set ('||l_existed_sets||')';
                          end if;
--						  execute 'CREATE TABLE '||l_new_part_name||' PARTITION OF '||scr.schema_name||'.'||scr.table_name||' FOR VALUES FROM ('||int_rec.dt||'01) TO ('||int_rec.dt::int+1||'01)';
						  commit;

						  select load_log(l_load_id, l_step_id, l_new_part_name||' added ', 0, 'O')
						  into l_step_id;
						else
					 	if l_existed_part_name = ''
						 then
						  	select load_log(l_load_id, l_step_id, 'Last table '||scr.schema_name||'.'||scr.table_name||' partition is '||l_new_part_name||'', 0, 'O')
						  	into l_step_id;
						 else
						 	select load_log(l_load_id, l_step_id, 'YEAR Partition '||l_new_part_name||' already exists', 0, 'O')
						  	into l_step_id;
						  end if;

						 l_existed_part_name:=	scr.part_schema_name||'."'||scr.table_name||'_'||int_rec.dt||'"';
						l_existed_sets = (select array_to_string(reloptions, ',')
                                            from pg_class c
                                                     join pg_namespace n on (n.oid = c.relnamespace)
                                            where nspname = scr.part_schema_name
                                              and relname = scr.table_name||'_'||int_rec.dt);
						end if;
		            end loop; /* 2 years */

			  else
			       raise notice 'nothing';
		        end case; /* CASE */
		end if; /* Check if table is partitioned */
    end loop;
 select load_log(l_load_id, l_step_id, 'DB_MANAGEMENT.ADD_PARTITIONS COMPLETED===', 0, 'O')
  into l_step_id;
 end;
	-- Enter function body here
 $procedure$
;
