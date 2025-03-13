select * from dwh.gtc_get_closed_orders_by_reason(in_time := '16:20', in_date_id := 20250303)
select * from dwh.gtc_get_closed_orders_by_reason(in_time := '16:20', in_date_id := 20250303, in_reason := 'E');
select * from dwh.gtc_get_closed_orders_by_reason(in_time := '16:20', in_date_id := 20250303, in_reason := 'P');
select * from dwh.gtc_get_closed_orders_by_reason(in_time := '16:20', in_date_id := 20250303, in_reason := 'L');

drop function dwh.gtc_get_closed_orders_by_reason;
create or replace function dwh.gtc_get_closed_orders_by_reason(in_time time,
                                                               in_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                               in_reason char default 'I')
    --     returns table
--             (
--                 order_id                int8,
--                 create_date_id          int4,
--                 order_status            bpchar(1),
--                 exec_time               timestamp(6),
--                 last_trade_date         timestamp(0),
--                 last_mod_date_id        int4,
--                 is_parent               bool,
--                 close_date_id           int4,
--                 account_id              int4,
--                 time_in_force_id        bpchar(1),
--                 db_create_time          timestamp,
--                 db_update_time          timestamp,
--                 closing_reason          bpchar(1),
--                 client_order_id         varchar(256),
--                 instrument_id           int8,
--                 multileg_reporting_type bpchar(1)
--             )
    returns int8[]
    language plpgsql
as
$fx$
    -- 20250312 OS https://dashfinancial.atlassian.net/browse/DS-9702
declare
    l_order_ids int8[];
begin
    /*    return query
            select gtc.order_id,
                   gtc.create_date_id,
                   gtc.order_status,
                   gtc.exec_time,
                   gtc.last_trade_date,
                   gtc.last_mod_date_id,
                   gtc.is_parent,
                   gtc.close_date_id,
                   gtc.account_id,
                   gtc.time_in_force_id,
                   gtc.db_create_time,
                   gtc.db_update_time,
                   gtc.closing_reason,
                   gtc.client_order_id,
                   gtc.instrument_id,
                   gtc.multileg_reporting_type
     */

    select array_agg(gtc.order_id)
    into l_order_ids
    from dwh.gtc_order_status gtc
    where true
      and gtc.closing_reason = in_reason
      and gtc.close_date_id = in_date_id
      and gtc.close_date_id is not null
      and gtc.db_update_time::time > in_time;
    return l_order_ids;
end ;

$fx$;
comment on function dwh.gtc_get_closed_orders_by_reason is 'the funtion that returns records of gtc_order_status have been closed after in_time';