select array_agg(id)
from (select distinct dataset_id as id
      from dwh.execution
      where exec_date_id = 20240308
      order by 1
      limit 20 offset 0) x

select * from data_marts.f_parent_order;

drop table if exists data_marts.f_parent_order;
create table data_marts.f_parent_order
(
    parent_order_id     int8      not null,
    last_exec_id        int8,
    create_date_id      int4      not null,
    status_date_id      int4,
    time_in_force_id    bpchar(1),
    account_id          int4
        constraint f_parent_order_d_account_fk references dwh.d_account (account_id),
    trading_firm_unq_id int4
        constraint f_parent_order_d_trading_firm_fk references dwh.d_trading_firm (trading_firm_unq_id),
    instrument_id       int4
        constraint f_parent_order_d_instrument_fk references dwh.d_instrument (instrument_id),
    instrument_type_id  bpchar(1),
    street_count        int4,
    trade_count         int4,
    order_qty           int4,
    street_order_qty    int4, --sum order_qty streets
    last_qty            int8, -- sum last_qty exec
    amount              numeric, -- last_qty * price
    pg_db_create_time   timestamp not null default clock_timestamp(),
    pg_db_update_time   timestamp
--     process_time
);
alter table data_marts.f_parent_order set (fillfactor = 70);
alter table data_marts.f_parent_order add constraint f_parent_order_pk primary key (status_date_id, parent_order_id);

comment on table data_marts.f_parent_order is 'data mart for parent_orders incrementally updating during the market day';
comment on column data_marts.f_parent_order.parent_order_id is 'parent_order from dwh.client_order';
comment on column data_marts.f_parent_order.create_date_id is 'create_date_id for parent_order';
comment on column data_marts.f_parent_order.last_exec_id is 'last processed exec_id to info';
comment on column data_marts.f_parent_order.status_date_id is 'date_id of the day where parent_order was processed into the table. As sama as create_date_id for non GTC orders';
comment on column data_marts.f_parent_order.time_in_force_id is 'time_in_force_id of parent_order';
comment on column data_marts.f_parent_order.account_id is 'account_id of parent_order related to d_account';
comment on column data_marts.f_parent_order.trading_firm_unq_id is 'trading_firm_unq_id of parent_order related to d_trading_firm';
comment on column data_marts.f_parent_order.instrument_id is 'instrument_id of parent_order related to d_instrument';
comment on column data_marts.f_parent_order.instrument_type_id is 'instrument_type_id of parent_order';
comment on column data_marts.f_parent_order.pg_db_create_time is '';
comment on column data_marts.f_parent_order.pg_db_update_time is '';


create or replace function data_marts.load_parent_order_inc2(in_parent_order_ids bigint[] default null::bigint[],
                                                             in_date_id integer default null::integer,
                                                             in_dataset_ids bigint[] default null::bigint[])
    returns int4
    language plpgsql
as
$fn$
    -- SO: 20240307 https://dashfinancial.atlassian.net/browse/DS-8065
declare
    l_row_cnt int4;
    l_load_id int8;
    l_step_id int4;
    l_date_id int4 := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::int4);

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    raise notice '%, %, %', in_parent_order_ids, in_dataset_ids, in_date_id;
    -- the list of orders
    drop table if exists t_base;
    create temp table t_base as
    select cl.parent_order_id,
           min(create_date_id) as create_date_id, --??
           min(exec_id)        as min_exec_id,
           max(exec_id)        as max_exec_id
    from dwh.execution ex
             join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = l_date_id
    where exec_date_id = l_date_id
      and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
      and case when in_parent_order_ids is null then true else cl.parent_order_id = any(in_parent_order_ids) end
      and not is_parent_level
      and cl.parent_order_id is not null
    group by cl.parent_order_id;

    get diagnostics l_row_cnt = row_count;
    raise notice 't_base - %', l_row_cnt;

    -- new groupped by parent_order
    drop table if exists t_parent_orders;
    create temp table t_parent_orders as
    select bs.*,
           val.*,
           nup.need_update
    from t_base bs
             join lateral ( select case
                                       when exists (select null
                                                    from data_marts.f_parent_order fp
                                                    where fp.status_date_id = l_date_id
                                                      and fp.parent_order_id = bs.parent_order_id
                                                      and fp.last_exec_id > bs.min_exec_id)
                                           then true
                                       else false end as need_update
        ) nup on true
             join lateral (select street_count, trade_count, last_qty, amount
                           from data_marts.get_exec_for_parent_order(in_parent_order_id := bs.parent_order_id,
                                                                     in_date_id := l_date_id,
                                                                     in_min_exec_id := case when nup.need_update then 0 else bs.min_exec_id end
                                )
                           limit 1) val on true;
    get diagnostics l_row_cnt = row_count;
    raise notice 't_street_orders create - %', l_row_cnt;
    create index on t_parent_orders (parent_order_id);

    get diagnostics l_row_cnt = row_count;
    raise notice 't_parent_orders insert - %', l_row_cnt;

    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           street_count, trade_count,
                                           last_qty, amount, pg_db_create_time)
    select tp.parent_order_id,
           tp.max_exec_id,
           tp.create_date_id,
           l_date_id,
           case when tp.need_update then tp.street_count else tp.street_count + coalesce(fp.street_count, 0) end,
           case when tp.need_update then tp.trade_count else tp.trade_count + coalesce(fp.trade_count, 0) end,
           case when tp.need_update then tp.last_qty else tp.last_qty + coalesce(fp.last_qty, 0) end,
           case when tp.need_update then tp.amount else tp.amount + coalesce(fp.amount, 0) end,
           clock_timestamp()
    from t_parent_orders tp
             left join data_marts.f_parent_order fp
                       on fp.parent_order_id = tp.parent_order_id and fp.status_date_id = l_date_id
    on conflict (status_date_id, parent_order_id) do update
        set last_exec_id      = excluded.last_exec_id,
            street_count      = excluded.street_count,
            trade_count       = excluded.trade_count,
            last_qty          = excluded.last_qty,
            amount            = excluded.amount,
            pg_db_update_time = clock_timestamp();

    get diagnostics l_row_cnt = row_count;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' FINISHED ===', l_row_cnt, 'E')
    into l_step_id;

    return l_row_cnt;
end;
$fn$;


select *
from data_marts.load_parent_order_inc2(in_date_id := 20240315, in_dataset_ids := '{36247850,36247951,36247960,36247970,36248211,36248284,36248371,36248380,36248518,36248536,36248595,36248613,36248673,36248693,36248772,36248841,36248859,36248927,36248971,36248986,36249005,36249039,36249054,36249108,36249123,36249318,36249330,36249351,36249442,36249460,36249497,36249513,36249565,36249590,36249692,36249701,36249750,36249768,36249929,36249957,36249965,36249982,36250032,36250050,36250168,36250188,36250460,36250476,36250658,36250668,36250684,36250756,36250766,36250781,36250823,36250841,36250901,36250925,36256028,36256042}');

create temp drop table t_01 as
select *--parent_order_id, last_exec_id, street_count, trade_count, last_qty, amount
delete
from data_marts.f_parent_order
where status_date_id = 20240308

select * from t_04
except
select * from t_01;


delete from data_marts.f_parent_order
where status_date_id = 20240315;

select array_agg(dataset_id) from (select distinct dataset_id
                                    from dwh.execution
                                    where exec_date_id = 20240315
                                    limit 200 offset 0) x;

create or replace function data_marts.get_exec_for_parent_order(in_parent_order_id int8,
                                                                in_date_id int4 default to_char(current_date, 'YYYYMMDD')::int,
                                                                in_min_exec_id int8 default null)
    returns table
            (
                street_count int8,
                trade_count  int8,
                last_qty     numeric,
                amount       numeric
            )
    language plpgsql
as
$fx$
declare

begin
    return query
        select --cl.parent_order_id,
               count(distinct ex.order_id)   as street_count,
               count(*)                      as trade_count,
               sum(ex.last_qty)              as last_qty,
               sum(ex.last_qty * ex.last_px) as amount
        --        ,min(ex.exec_id)               as min_exec_id,
--        max(ex.exec_id)               as max_exec_id
        from dwh.execution ex
                 join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = in_date_id
        where ex.exec_date_id = in_date_id
          and cl.parent_order_id = in_parent_order_id
          and ex.exec_id > in_min_exec_id
          and ex.exec_type = 'F'
          and ex.is_busted = 'N'
        group by cl.parent_order_id;
end;
$fx$;

select * from data_marts.load_parent_order_inc2(in_date_id := 20240308), in_dataset_ids := '{35872659,35872674,35872684,35872693,35872708,35872718,35872728,35872742,35872751,35872761,35872776,35872786,35872795,35872811,35872820,35872830,35872845,35872854,35872864,35872878,35872888,35872898,35872914,35872923,35872933,35872948,35872957,35872966,35872981,35872991,35873000,35873015,35873025,35873034,35873049,35873059,35873068,35873083,35873092,35873102,35873117,35873136,35873150,35873161,35873170,35873184,35873195,35873211,35873221,35873233,35873248,35873258,35873267,35873284,35873294,35873319,35873329,35873338,35873353,35873363,35873373,35873388,35873397,35873406,35873421,35873431,35873440,35873455,35873465,35873475,35873489,35873499,35873508,35873523,35873533,35873542,35873557,35873567,35873583,35873592,35873602,35873617,35873626,35873636,35873652,35873662,35873671,35873687,35873696,35873705,35873721,35873731,35873741,35873756,35873766,35873775,35873790,35873800,35873810,35873826,35873836,35873850,35873862,35873872,35873886,35873895,35873904,35873918,35873929,35873938,35873954,35873962,35873972,35873988,35873996,35874006,35874022,35874031,35874041,35874054,35874066,35874074,35874083,35874097,35874107,35874116,35874132,35874141,35874150,35874165,35874174,35874183,35874197,35874207,35874216,35874231,35874240,35874250,35874265,35874274,35874283,35874299,35874308,35874317,35874332,35874342,35874351,35874367,35874377,35874386,35874401,35874410,35874435,35874445,35874455,35874470,35874479,35874489,35874503,35874513,35874522,35874537,35874546,35874555,35874571,35874580,35874590,35874605,35874614,35874624,35874639,35874648,35874657,35874673,35874683,35874693,35874707,35874716,35874726,35874742,35874751,35874762,35874777,35874786,35874796,35874812,35874822,35874838,35874848,35874858,35874873,35874883,35874893,35874907,35874917,35874926,35874941,35874951,35874961,35874975,35874984,35874993,35875008,35875017,35875027,35875042,35875051,35875061,35875123,35875133,35875143,35875203,35875213,35875223,35875285,35875294,35875365,35875376,35875388,35875447,35875457,35875518,35875528,35875538,35875600,35875610,35875619,35875681,35875692,35875701,35875762,35875772,35875782,35875843,35875852,35875862,35875923,35875933,35875943,35876004,35876014,35876036,35876084,35876094,35876116,35876164,35876174,35876189,35876245,35876254,35876276,35876325,35876335,35876395,35876405,35876415,35876476,35876485,35876495,35876556,35876565,35876574,35876636,35876646,35876655,35876717,35876728,35876738,35876800,35876810,35876819,35876880,35876891,35876925,35876963,35876973,35877034,35877044,35877053,35877115,35877124,35877133,35877195,35877204,35877214,35877275,35877285,35877294,35877355,35877365,35877374,35877436,35877446,35877456,35877517,35877526,35877535,35877595,35877604,35877614,35877676,35877685,35877694,35877755,35877765,35877774,35877835,35877845,35877854,35877915,35877925,35877934,35877995,35878004,35878013,35878074,35878084,35878093,35878155,35878165,35878175,35878236,35878246,35878260,35878317,35878328,35878363,35878400,35878410,35878471,35878480,35878491,35878551,35878562,35878571,35878632,35878642,35878652,35878713,35878725,35878788,35878798,35878808,35878868,35878888,35879505,35879515,35879747,35879756,35879827,35879896,35880115,35880131,35880184,35880205,35880218,35880228,35880242,35880608,35880634,35880658,35880683,35880692,35880702,35880754,35880773,35880860,35880877,35880935,35880944,35880952,35880967,35880976,35880986,35881015,35881027,35881039,35881048,35881058,35881074,35881084,35881094,35881109,35881118,35881144,35881153,35881165,35881176,35881198,35881231,35881248,35881258,35881383,35881404,35881607,35881632,35881644,35881660}');

select * from data_marts.load_parent_order_inc2(in_date_id := 20240308), in_parent_order_ids := '{284736457}');



select *
 into trash.so_parent_orders_1
-- delete
from data_marts.f_parent_order
         where true
               and parent_order_id = 284719151
    and status_date_id = 20240308;


select parent_order_id, street_count, trade_count, last_qty, amount
from trash.so_parent_orders_1
where parent_order_id = 284719151
union all
select parent_order_id, street_count, trade_count, last_qty, amount
from trash.so_parent_orders_2
where parent_order_id = 284719151;


select * from dwh.client_order where parent_order_id = 284719151;

select count(distinct ex.order_id)   as street_count,
               count(*)                      as trade_count,
               sum(ex.last_qty)              as last_qty,
               sum(ex.last_qty * ex.last_px) as amount
--select      distinct cl.dataset_id
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id
where cl.parent_order_id = 284719151
          and ex.exec_type = 'F'
          and ex.is_busted = 'N';

select * from t_base

