drop function if exists staging.get_timestamp_from_date_ts;
create or replace function staging.get_timestamp_from_date_ts(in_date_id int4 default null, in_ts text default null)
    returns timestamp
    language plpgsql
as
$fx$
begin
    return to_timestamp(in_date_id::text || in_ts, 'YYYYMMDDHH24:MI:SS.US');
exception
    when others then
        return null;
end;
$fx$;

select staging.get_timestamp_from_date_ts(20230506, '25:50:09.010453')
select :order_trade_date::text, :f_timestamp,
       to_timestamp(:order_trade_date::text || :f_timestamp, 'YYYYMMDDHH24:MI:SS.US')

SELECT co.cl_ord_id                                                                            AS orderid,
       co.payload -> 'OriginatorOrder',
       co.payload ->> 'IsFlex',
       co.crossing_side,
       case
           when is_q_time then staging.get_timestamp_from_date_ts(order_trade_date,
                                                                  q_time) end as boxqooannouncedtime
FROM (SELECT DISTINCT ON (cl.cl_ord_id) cl.order_id,
                                        cl.chain_id,
                                        cl.parent_order_id,
                                        cl.orig_order_id,
                                        cl.record_type,
                                        regexp_replace(cl.payload::text, '\\u0000'::text, ''::text,
                                                       'g'::text)::json AS payload,
                                        cl.db_create_time,
                                        cl.cl_ord_id,
                                        cl.crossing_side,
                                        cl.order_class,
                                        cl.secondary_order_id,
                                        cl.cross_order_id,
                                        big.payload                     AS big_payload,
                                        case
                                            when cl.route_destination = 'BOX QOO' and cl.payload ->> 'IsFlex' = 'Y'
                                                then true::boolean
                                            else false end as is_q_time,
                                        cl.order_trade_date::int,
                                        case
                                            when (cl.route_destination = 'BOX QOO' and cl.payload ->> 'IsFlex' = 'Y')
                                                then
                                                case
                                                    when cl.crossing_side = 'O'::bpchar
                                                        then cl.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                                                    when cl.crossing_side = 'C'::bpchar
                                                        then (select cl.payload #>> '{OriginatorOrder,OrderNotes}'
                                                              from blaze7.client_order co2
                                                              WHERE co2.cross_order_id = cl.cross_order_id
                                                                and co2.crossing_side = 'O'
                                                              order by cl.chain_id desc
                                                              limit 1)
                                                    end end             as q_time
      FROM blaze7.client_order cl
               LEFT JOIN LATERAL ( SELECT regexp_replace(co2.payload::text, '\\u0000'::text, ''::text,
                                                         'g'::text)::json AS payload
                                   FROM blaze7.client_order co2
                                   WHERE co2.order_id = cl.order_id
                                   ORDER BY co2.chain_id DESC
                                   LIMIT 1) big ON true
      WHERE true
        AND (cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
        and cl.route_destination = 'BOX QOO'
      ORDER BY cl.cl_ord_id, cl.chain_id DESC) co;
