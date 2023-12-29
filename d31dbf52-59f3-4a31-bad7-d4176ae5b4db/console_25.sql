select * from public.get_last_workdate('2023-12-27')


select * from trash.fix_upload_exec(in_date_id := 20231227);

create or replace function trash.fix_upload_exec(in_date_id int4)
    returns int4
    language plpgsql
as
$fx$

declare
    l_date_id_min int4 := to_char(public.get_business_date(in_date_id::text::date, -1), 'YYYYMMDD')::int4;
    l_date_ids    int4[];
    row_cnt       int4;
    l_load_id     int;
    l_step_id     int;
begin

    l_date_ids := array [l_date_id_min,
        in_date_id,
        to_char(public.get_business_date(in_date_id::text::date, 1), 'YYYYMMDD')::int4];

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec for ' || l_date_ids::text || ' started====', 0, 'O')
    into l_step_id;

    truncate staging.fix_upload_exec_order;

    insert into staging.fix_upload_exec_order
    select co.order_id, fx.*
    from trash.fix_upload_exec as fx
             join dwh.client_order co
                  on co.client_order_id = fx.client_order_id
    where co.create_date_id = any (l_date_ids)
      and to_char(fx.create_or_exec_ts, 'YYYYMMDD')::int4 = any (l_date_ids);

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;

    insert into staging.fix_upload_exec_order
    select co.order_id, fx.*
    from trash.fix_upload_exec as fx
             join dwh.client_order co on co.client_order_id = fx.cl_order_id_orig
    where co.create_date_id = any (l_date_ids)
      and to_char(fx.create_or_exec_ts, 'YYYYMMDD')::int4 = any (l_date_ids);

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;

    insert into staging.fix_upload_exec_order
    select co.order_id, fx.*
    from trash.fix_upload_exec as fx
             join dwh.client_order co on co.client_order_id = fx.client_order_id
             join dwh.gtc_order_status gos on gos.create_date_id = co.create_date_id and gos.order_id = co.order_id
    where true
      and co.create_date_id < l_date_id_min
      and to_char(fx.create_or_exec_ts, 'YYYYMMDD')::int4 = any (l_date_ids);

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;

    insert into staging.fix_upload_exec_order
    select co.order_id, fx.*
    from trash.fix_upload_exec as fx
             join dwh.client_order co on co.client_order_id = fx.cl_order_id_orig
             join dwh.gtc_order_status gos on gos.create_date_id = co.create_date_id and gos.order_id = co.order_id
    where true
      and co.create_date_id < l_date_id_min
      and to_char(fx.create_or_exec_ts, 'YYYYMMDD')::int4 = any (l_date_ids);

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;


    create temp table ex_tmp on commit drop as
    select fixex.*,
           ex.exec_id,
--            ex.order_id,
           ex.exec_time,
           ex.exec_type,
           ex.exec_date_id
    from staging.fix_upload_exec_order as fixex
             join dwh.execution ex on fixex.trans_type in ('8', '9')
        and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
        and fixex.order_id = ex.order_id
        and ex.exch_exec_id is not Null
        and fixex.exch_exec_id = ex.exch_exec_id
        and abs(extract(epoch from (fixex.create_or_exec_ts - ex.exec_time))) < 120
        and ex.exec_date_id = any (l_date_ids)
        and to_char(fixex.create_or_exec_ts, 'YYYYMMDD')::int4 = any (l_date_ids);

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;

    create temp table ex_null_exchexecid_tmp on commit drop as
    select fixex.*,
           ex.exec_id,
--            ex.order_id,
           ex.exec_time,
           ex.exec_type,
           ex.exec_date_id
    from staging.fix_upload_exec_order as fixex
             join dwh.execution ex
                  on (fixex.trans_type in ('8', '9'))
--            and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
                      and fixex.order_id = ex.order_id
                      and ex.exch_exec_id is null
                      and fixex.exch_exec_id = 'NONE_'
                      --and left(to_char(ex.exec_time , 'HHMISS.MS'),12) = left(to_char(fixex.create_or_exec_ts , 'HHMISS.MS'),12)
                      and ex.exec_time - fixex.create_or_exec_ts between -interval '1 second' and interval '1 second'
                      and ex.exec_date_id = any (l_date_ids);

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;

    create temp table cex_tmp on commit drop as
    select fixex.*,
           ex.exec_id,
--            ex.order_id,
           ex.exec_time,
           ex.exec_type
    from staging.fix_upload_exec_order as fixex
             join dwh.conditional_execution ex
                  on (fixex.trans_type in ('8', '9'))
--            and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
                      and ex.exch_exec_id is not Null
                      and fixex.exch_exec_id = ex.exch_exec_id
                      and fixex.order_id = ex.order_id
                      and abs(extract(epoch from (fixex.create_or_exec_ts - ex.exec_time))) < 120;

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;

    create temp table cex_null_exchexecid_tmp on commit drop as
    select fixex.*,
           ex.exec_id,
           ex.exec_time,
           ex.exec_type
    from staging.fix_upload_exec_order
             as fixex
             join dwh.conditional_execution ex
                  on (fixex.trans_type in ('8', '9'))
                      and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
                      and fixex.order_id = ex.order_id
                      and ex.exch_exec_id is null;

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec' || l_step_id::text, 0, 'O')
    into l_step_id;

    drop table if exists staging.fix_upload_exec;

    create table staging.fix_upload_exec as
    with ex as (select *
                from (select *
                      from ex_tmp
                      union
                      select *
                      from ex_null_exchexecid_tmp) ex_tmp
                where exists
                          (select null
                           from dwh.client_order co
                           where co.order_id = ex_tmp.order_id
                             and co.client_order_id = ex_tmp.client_order_id
                             and co.create_date_id <= ex_tmp.exec_date_id)),
         cex as (select *
                 from (select *
                       from cex_tmp
                       union
                       select cex_null_exchexecid_tmp.*
                       from cex_null_exchexecid_tmp) cex_tmp
                 where exists
                           (select null
                            from dwh.conditional_order con_o
                            where con_o.order_id = cex_tmp.order_id
                              and con_o.client_order_id = cex_tmp.client_order_id
                              and con_o.create_time <= cex_tmp.exec_time))

    select trans_type,
           client_order_id,
           cl_order_id_orig,
           exch_exec_id,
           exec_time as create_or_exec_db,
           order_id
    from ex

    union all

    select trans_type,
           client_order_id,
           cl_order_id_orig,
           exch_exec_id,
           exec_time as create_or_exec_db,
           order_id
    from cex;

    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'fix_upload_exec for ' || l_date_ids::text || ' finished====', row_cnt, 'O')
    into l_step_id;

    return row_cnt;
end;

$fx$;

select * from staging.fix_upload_exec;