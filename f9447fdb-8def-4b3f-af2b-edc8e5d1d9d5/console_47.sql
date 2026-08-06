-- blaze7.v_lifecycle_order source

CREATE OR REPLACE VIEW blaze7.v_lifecycle_order
AS SELECT DISTINCT ON (co.order_id, co.chain_order_id) co.order_id,
    co.chain_order_id AS lifecycle_orderid,
    ( SELECT
                CASE
                    WHEN ((rep.payload ->> 'OrderStatus'::text) = ANY (ARRAY['2'::text, '4'::text, 'P'::text, '3'::text])) AND (rep.payload ->> 'BlazeOrderStatus'::text) <> 't'::text THEN 'F'::text
                    ELSE 'N'::text
                END AS lifecycle_orderid_status
           FROM blaze7.order_report rep
          WHERE rep.order_id = co.order_id AND rep.leg_ref_id IS NULL
          ORDER BY rep.exec_id DESC
         LIMIT 1) AS lifecycle_orderid_status
   FROM blaze7.client_order co
  WHERE true AND co.parent_order_id IS NULL AND co.db_create_time >= CURRENT_DATE AND co.db_create_time <= (CURRENT_DATE + '1 day'::interval);

drop table if exists genesis2.blaze_lifecycle_order;
create table if not exists genesis2.blaze_lifecycle_order
(
    parent_order_id          int8        not null
        constraint blaze_lifecycle_order_pk primary key,
    lifecycle_orderid        int8        null,
    lifecycle_orderid_status char(1)     not null,
    last_exec_id             varchar(30) not null
);
create index blaze_lifecycle_order_last_exec_id_idx on genesis2.blaze_lifecycle_order (last_exec_id);

create or replace function
insert into genesis2.blaze_lifecycle_order (parent_order_id, lifecycle_orderid, lifecycle_orderid_status)
select order_id, lifecycle_orderid, lifecycle_orderid_status
from staging.v_lifecycle_order vl
on conflict (parent_order_id)
    do update set lifecycle_orderid        = excluded.lifecycle_orderid,
                  lifecycle_orderid_status = excluded.lifecycle_orderid_status
where blaze_lifecycle_order.lifecycle_orderid_status is distinct from excluded.lifecycle_orderid_status
   or blaze_lifecycle_order.lifecycle_orderid is distinct from excluded.lifecycle_orderid;


select * from genesis2.blaze_lifecycle_order

-- DROP FUNCTION genesis2.load_away_trade(text, text);

CREATE OR REPLACE FUNCTION genesis2.load_away_trade(in_min_report_id text DEFAULT NULL::text, in_max_report_id text DEFAULT NULL::text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
-- 20241217 SO added account_name_gvp and mic_code
declare
    l_last_loaded_report_id text;
    l_maxt_report_id        text;
    l_row_cnt               int4;
    l_load_id               int4;
    l_step_id               int4;

begin