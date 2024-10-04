drop table t_ordermisc;

create temp table t_ordermisc as
select ultransaction64,
       _order_id,
       _chain_id,
       order_trade_date_id,
       'pg' as src
from staging.tordermisc1_edw
-- where order_trade_date_id = 20240930;
where _db_create_time >= '2024-09-30'::timestamp
and _db_create_time < '2024-10-01'::timestamp;

insert into t_ordermisc
select ultransaction64,
       pg_order_id,
       pg_chain_id,
       order_trade_date_id,
       'edw'
from staging.edw_blaze7_tordermisc1 as tp
-- where coalesce(order_trade_date_id, 0) = 20240930
where date_id = 20240930
  and upper(tp.pg_entity) = 'UAT';

select array_agg(_order_id) from (
select ultransaction64,
       _order_id,
       _chain_id,
       order_trade_date_id from t_ordermisc
where src = 'pg'
except
select ultransaction64,
       _order_id,
       _chain_id,
       order_trade_date_id
from t_ordermisc
where src != 'pg') x