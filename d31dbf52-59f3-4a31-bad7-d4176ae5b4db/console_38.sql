with vhfm as (select fix_message_id, fix_message ->> '9000' tgt_strategy
              from fix_capture.fix_message_json fmj
              where date_id = :date_id
                and fix_message ->> '9000' is not null --= 'VOLHEDGE'
                and fix_message ->> '10057' is not null
                and fix_message ->> '35' not in ('8', '9')
--and fix_message->>'9000' != 'SENSOR'
),
     clo as (select create_date_id,
                    order_id,
                    orig_order_id,
                    account_id,
                    di.instrument_type_id,
                    vhfm.tgt_strategy,
                    client_order_id,
                    fix_connection_id
             from dwh.client_order co
                      join vhfm on vhfm.fix_message_id = co.fix_message_id
                      left join dwh.d_instrument di on co.instrument_id = di.instrument_id
             where create_date_id = :date_id
               and parent_order_id is null),
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
                and so.create_date_id = :date_id),
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
;


-----------------------
drop table t_so;
create temp table t_so as
select co.create_date_id,
       co.order_id as parent_order_id,
       co.orig_order_id,
       co.account_id,
       di.instrument_type_id,
       vhfm.tgt_strategy,
       co.client_order_id,
       co.fix_connection_id,
       str.order_id,
       str.create_time,
       vhfm.t_10057
from dwh.client_order co
         join lateral (select fix_message_id, fix_message ->> '9000' tgt_strategy, fix_message ->> '10057' as t_10057
                       from fix_capture.fix_message_json fmj
                       where fmj.date_id = co.create_date_id
                         and fmj.fix_message_id = co.fix_message_id
--                          and fix_message ->> '9000' is not null --= 'VOLHEDGE'
--                          and fix_message ->> '10057' is not null
                         and fmj.message_type not in ('8', '9')
                         and fmj.date_id = :date_id
                       limit 1) vhfm on true
         join dwh.client_order str on str.parent_order_id = co.order_id and str.create_date_id >= co.create_date_id and
                                      str.create_date_id >= :date_id
         left join dwh.d_instrument di on co.instrument_id = di.instrument_id
where co.create_date_id = :date_id
  and co.parent_order_id is null;

create index on t_so (parent_order_id);

select so.parent_order_id as order_id
                     , count(1)              street_cnt
                     , min(so.create_time)   min_create_time
                     , max(so.create_time)   max_create_time
                from t_so so
                group by 1


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
         join clo on clo.order_id = preagg.order_id;

drop table if exists t_os;
create temp table t_os as
select clo.create_date_id,
       clo.order_id,
       clo.orig_order_id,
       clo.account_id,
       clo.client_order_id,
       clo.fix_connection_id,
       di.instrument_type_id,
       dss.target_strategy_name,
       str.street_cnt,
       str.min_create_time,
       str.max_create_time,
       case
           when str.street_cnt > 100 then
               str.street_cnt / case
                                    when extract(epoch from str.max_create_time - str.min_create_time) < 0.01
                                        then 1
                                    else extract(epoch from str.max_create_time - str.min_create_time) end
           else 1 end as street_order_eps,
    par_nbbo.ask_price as par_ask_price,
    par_nbbo.bid_price as par_bid_price,
    par_nbbo.ask_quantity as par_ask_quantity,
    par_nbbo.bid_quantity as par_bid_quantity,
    nbbo.*
from dwh.client_order clo
         join dwh.d_instrument di on di.instrument_id = clo.instrument_id
         join lateral (select count(1)            street_cnt,
                              min(so.create_time) min_create_time,
                              max(so.create_time) max_create_time,
                              min(so.transaction_id) as min_transaction_id
                       from dwh.client_order so
                       where so.parent_order_id = clo.order_id
                         and so.create_date_id = :date_id
                         and so.parent_order_id is not null
                       group by so.parent_order_id) str on true
         join dwh.d_target_strategy dss on dss.target_strategy_id = clo.sub_strategy_id
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = clo.transaction_id
                                  and ls.exchange_id = 'NBBO'
                                  and ls.start_date_id = :date_id--to_char(clo.create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                limit 1
        ) par_nbbo on true
             left join lateral (select ls.ask_price, ls.bid_price, ls.ask_quantity, ls.bid_quantity
                                from dwh.l1_snapshot ls
                                where ls.transaction_id = str.min_transaction_id
                                  and ls.exchange_id = 'NBBO'
                                  and ls.start_date_id = :date_id--to_char(str.min_create_time, 'YYYYMMDD')::int4
--                                    and ls.start_date_id = str.create_date_id
                                limit 1
        ) nbbo on true
where create_date_id = :date_id
  and parent_order_id is null;


select * from t_os