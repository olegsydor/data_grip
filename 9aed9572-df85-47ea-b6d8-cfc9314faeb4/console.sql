select
_db_create_time, _db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central' as _db_create_time,
* from blaze7.tprices_edw
where "_order_id" = 535802370555133952;


select
_db_create_time as "UTC",
_db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central' as _db_create_time,
_db_create_time at time zone 'US/Central' as _db_create_time
from blaze7.tprices_edw
where _db_create_time::date = '2023-07-18'
    and "_order_id" = 535822291003523072;


select to_char(boxqooannouncedtime, 'YYYY-MM-DD HH24:MI:SS.US'), *
from blaze7.tordermisc1_edw
where "_db_create_time"::date = '2023-07-18'
and "_order_id" = 535793635686367234;



SELECT id,
       clordid_to_guid(orderid)                                                  as orderid,
       legrefid::text,
       round(price::bigint / 10000.0, 4)                                         as price,
       legcount::int,
       legnumber::int,
       dashsecurityid,
       basecode,
       typecode,
       expirationdate::date,
       round(strike::numeric, 6)                                                 as strike,
       side::int,
       ratio::int,
       multiplier::int,
       quantity::int,
       filled::int,
       invested,
       round(avgprice::bigint / 100000000.0, 8)                                  as avgprice,
       stockquantity::bigint,
       stockopenquantity::int,
       stockfilled::int,
       stockcancelled::bigint,
       optionquantity::int,
       optionopenquantity::int,
       optionfilled::int,
       optioncancelled::int,
       mindatetime::timestamp at time zone 'UTC' at time zone 'US/Central'       as mindatetime,
       maxdatetime::timestamp at time zone 'UTC' at time zone 'US/Central'       as maxdatetime,
       firstfilldatetime::timestamp at time zone 'UTC' at time zone 'US/Central' as firstfilldatetime,
       lastfilldatetime::timestamp at time zone 'UTC' at time zone 'US/Central'  as lastfilldatetime,
       statuscode,
       timeinforcecode,
       openclose,
       systemid,   -- no data
       orderidint, -- no data
       rootcode,
       prevfillquantity::int,
       stockprevfillquantity::int,
       optionprevfillquantity::int,
       clordid_to_guid(legorderid)                                               as legorderid,
       _order_id::bigint,
       _chain_id,
       _db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central'   as _db_create_time,
       orderid                                                                   as cl_ord_id
select mx.*, *
FROM blaze7.tlegs_edw as x
left join lateral(SELECT rep.db_create_time as max_rep_time FROM blaze7.order_report rep WHERE rep.order_id = x._order_id AND rep.chain_id = x._chain_id order by rep.db_create_time desc limit 1) mx on true
where to_char(x._db_create_time, 'YYYYMMDD')::int = '20230718'::int
AND x._db_create_time >  '2023-07-18 06:15:15.237'::timestamp at time zone 'US/Central' at time zone 'UTC' - interval '10 minute'
and mx.max_rep_time >  '2023-07-18 06:15:15.237'::timestamp at time zone 'US/Central' at time zone 'UTC' - interval '10 minute';

select *
FROM blaze7.tlegs_edw as x
         left join lateral (SELECT rep.db_create_time as max_rep_time
                            FROM blaze7.order_report rep
                            WHERE rep.order_id = x._order_id
                              AND rep.chain_id = x._chain_id
                            order by rep.db_create_time desc
                            limit 1) mx on true
where to_char(x._db_create_time, 'YYYYMMDD')::int = '"+context.p_date_id+"'::int
  AND x._db_create_time > '"+context.max_processed_time_leg+"'::timestamp at time zone 'US/Central' at time zone
                          'UTC' - interval '10 minute'
  and mx.max_rep_time > '"+context.max_processed_time_leg+"'::timestamp at time zone 'US/Central' at time zone
                        'UTC' - interval '10 minute';


select *
FROM blaze7.torder_edw as x
where x._db_create_time >= '20230718'::date
and x._db_create_time < '''20230718'::date + interval '1 day'
AND x._last_mod_time::timestamp >  '"+context.max_processed_time_order+"'::timestamp at time zone 'US/Central' at time zone 'UTC' - interval '10 minute';
