SELECT id,
       public.clordid_to_guid(orderid)                          as orderid,
       legrefid::text,
       round(price::bigint / 10000.0, 4)                        as price,
       legcount::int,
       legnumber::int,
       dashsecurityid,
       basecode,
       typecode,
       expirationdate::date,
       round(strike::numeric, 6)                                as strike,
       side::int,
       ratio::int,
       multiplier::int,
       quantity::int,
       filled::int,
       invested,
       round(avgprice::bigint / 100000000.0, 8)                 as avgprice,
       stockquantity::bigint,
       stockopenquantity::int,
       stockfilled::int,
       stockcancelled::bigint,
       optionquantity::int,
       optionopenquantity::int,
       optionfilled::int,
       optioncancelled::int,
       mindatetime::timestamptz at time zone 'US/Central'       as mindatetime,
       maxdatetime::timestamptz at time zone 'US/Central'       as maxdatetime,
       firstfilldatetime::timestamptz at time zone 'US/Central' as firstfilldatetime,
       lastfilldatetime::timestamptz at time zone 'US/Central'  as lastfilldatetime,
       statuscode,
       timeinforcecode,
       openclose,
       systemid,   -- no data
       orderidint, -- no data
       rootcode,
       prevfillquantity::int,
       stockprevfillquantity::int,
       optionprevfillquantity::int,
       public.clordid_to_guid(legorderid)                       as legorderid,
       IsComboLeg,
       IsFlex,
       _order_id::bigint,
       _chain_id,
       _db_create_time::timestamptz at time zone 'US/Central'   as _db_create_time,
       orderid                                                  as cl_ord_id,
       order_trade_date_id
FROM blaze7.tlegs_edw as x
where order_trade_date_id between  20250708 and public.get_dateid(public.get_business_date( 20250708::text::date, 1))
  AND GREATEST(x._db_create_time,
               (SELECT max(rep.db_create_time)
                FROM blaze7.order_report rep
                WHERE rep.order_id = x._order_id
                  AND rep.chain_id = x._chain_id))::timestamp >
      '2025-01-01 00:00:00'::timestamp at time zone 'US/Central' - interval '1 second'
  and orderid = '3_2m250708'
      limit 5;