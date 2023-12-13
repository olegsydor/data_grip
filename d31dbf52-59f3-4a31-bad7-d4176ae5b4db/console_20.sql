-- create temp table t_so_fmj as
with vhfm as (select fix_message_id, fix_message ->> '9000' tgt_strategy
              from fix_capture.fix_message_json fmj
              where date_id = 20231211
                and fix_message->>'9000' is not null --= 'VOLHEDGE'
                and fix_message->>'10057' is not null
                and fix_message->>'35' not in ('8'
                  , '9')
--and fix_message->>'9000' != 'SENSOR'
)
--      , clo as (
     select create_date_id,
                    order_id,
                    orig_order_id,
                    account_id,
                    di.instrument_type_id,
                    vhfm.tgt_strategy,
                    client_order_id,
                    fix_connection_id
             from dwh.client_order co
                      left join vhfm on vhfm.fix_message_id = co.fix_message_id
                      left join dwh.d_instrument di on co.instrument_id = di.instrument_id
             where create_date_id = 20231211
               and parent_order_id is null
             and order_id = 13946277655
    ),
     so as (select parent_order_id,
                   clo.orig_order_id,
                   clo.account_id,
                   clo.client_order_id,
                   clo.fix_connection_id,
                   clo.instrument_type_id,
                   clo.tgt_strategy,
                   so.order_id,
                   so.create_time
            from dwh.client_order so
                     join clo on clo.order_id = so.parent_order_id
                and so.create_date_id = {date_id}),
     preagg as (select so.parent_order_id as order_id
                     , count(1)              street_cnt
                     , min(so.create_time)   min_create_time
                     , max(so.create_time)   max_create_time
                from so
                group by 1)
select clo.create_date_id
     , clo.order_id
     , clo.orig_order_id
     , clo.account_id
     , clo.client_order_id
     , clo.fix_connection_id
     , clo.instrument_type_id
     , clo.tgt_strategy
     , preagg.street_cnt
     , preagg.min_create_time
     , preagg.max_create_time
     , case
           when preagg.street_cnt > 100 then
               preagg.street_cnt / case
                                       when extract(epoch from preagg.max_create_time - preagg.min_create_time) < 0.01
                                           then 1
                                       else extract(epoch from preagg.max_create_time - preagg.min_create_time) end
           else 1 end
    as street_order_eps
from preagg
         join clo on clo.order_id = preagg.order_id


select * from t_so_fmj;

delete from t_so_fmj
    where "?column?" = 'opt';

create temp table t_so_fmj as
select par.create_date_id,
       par.order_id,
       par.orig_order_id,
       par.account_id,
       par.client_order_id,
       par.fix_connection_id,
       di.instrument_type_id,
       fmj.tgt_strategy,
       str.street_cnt,
       str.min_create_time,
       str.max_create_time,
       case
           when str.street_cnt > 100 then
               str.street_cnt / case
                                    when extract(epoch from str.max_create_time - str.min_create_time) < 0.01 then 1
                                    else extract(epoch from str.max_create_time - str.min_create_time) end
           else 1 end as street_order_eps
-- into trash.so_to_delete_stats_collecting
from dwh.client_order par
         join dwh.d_instrument di on di.instrument_id = par.instrument_id
         join lateral (select count(1)             street_cnt
                            , min(str.create_time) min_create_time
                            , max(str.create_time) max_create_time
                       from dwh.client_order str
                       where str.create_date_id = 20231211
                         and str.parent_order_id = par.order_id
                       group by str.parent_order_id
                       limit 1) str on true
         join lateral (select fix_message ->> '9000'  as tgt_strategy,
                              fix_message ->> '10057' as t10057
                       from fix_capture.fix_message_json fmj
                       where date_id = 20231211
                         and fmj.fix_message_id = par.fix_message_id
--                               and fix_message ->> '9000' is not null --= 'VOLHEDGE'
--                               and fix_message ->> '10057' is not null
                         and fix_message ->> '35' not in ('8', '9')
                       limit 1) fmj on true
where par.create_date_id = 20231211
  and par.parent_order_id is null
  and fmj.t10057 is not null
  and fmj.tgt_strategy is not null
    limit 0

2,776,812 rows affected in 2 m 12 s 824 ms
2,776,812 rows affected in 1 m 39 s 806 ms

select create_date_id,
       order_id,
       orig_order_id,
       account_id,
       client_order_id,
       fix_connection_id,
       instrument_type_id,
       tgt_strategy,
       street_cnt,
       min_create_time,
       max_create_time,
       street_order_eps
from t_so_fmj
where "?column?" = 'opt'
except
select create_date_id,
       order_id,
       orig_order_id,
       account_id,
       client_order_id,
       fix_connection_id,
       instrument_type_id,
       tgt_strategy,
       street_cnt,
       min_create_time,
       max_create_time,
       street_order_eps
from t_so_fmj
where "?column?" = 'orig'
----------------------------------------------

select * from trash.stats_collecting3(in_date_id := 20231213);
select * from trash.stats_collecting(in_date_id := 20231204);


create or replace function trash.stats_collecting3(in_date_id int4)
    returns table
            (
                create_date_id     int4,
                order_id           int8,
                orig_order_id      int8,
                account_id         int4,
                client_order_id    varchar(256),
                fix_connection_id  int4,
                instrument_type_id bpchar(1),
                tgt_strategy       text,
                street_cnt         int8,
                min_create_time    timestamp,
                max_create_time    timestamp,
                street_order_eps   numeric
            )
    language plpgsql
as
$fx$
    declare
        row_cnt int4;
begin
    raise notice '%: start', clock_timestamp();
    create temp table t_fix_capture on commit drop as
    select fmj.fix_message_id,
           min(fix_message ->> '9000') as tgt_strategy
    from fix_capture.fix_message_json fmj
    where date_id = in_date_id
      and fmj.message_type not in ('8', '9')
      and fix_message ->> '9000' is not null --= 'VOLHEDGE'
      and fix_message ->> '10057' is not null
    group by fmj.fix_message_id;
    get diagnostics row_cnt = row_count;
    raise notice '%: t_fix_capture - %', clock_timestamp(), row_cnt;

    create temp table temp_stats_collecting on commit drop as
    select par.create_date_id,
           par.order_id,
           par.orig_order_id,
           par.account_id,
           par.client_order_id,
           par.fix_connection_id,
           di.instrument_type_id,
           tfc.tgt_strategy,
           str.street_cnt,
           str.min_create_time,
           str.max_create_time,
           case
               when str.street_cnt > 100 then
                   str.street_cnt / case
                                        when extract(epoch from str.max_create_time - str.min_create_time) < 0.01
                                            then 1
                                        else extract(epoch from str.max_create_time - str.min_create_time) end
               else 1 end as street_order_eps
    from t_fix_capture tfc
             join dwh.client_order par on tfc.fix_message_id = par.fix_message_id --and par.create_date_id = in_date_id
             join dwh.d_instrument di on di.instrument_id = par.instrument_id
             join lateral (select count(1)             street_cnt,
                                  min(str.create_time) min_create_time,
                                  max(str.create_time) max_create_time
                           from dwh.client_order str
                           where str.create_date_id = in_date_id
                             and str.parent_order_id = par.order_id
                           group by str.parent_order_id
                           limit 1) str on true
    where true
      and par.create_date_id = in_date_id
      and par.parent_order_id is null
      and tfc.tgt_strategy is not null;
    raise notice '%: temp table', clock_timestamp();
    return query
        select * from temp_stats_collecting;
    raise notice '%: finish', clock_timestamp();
end;
$fx$