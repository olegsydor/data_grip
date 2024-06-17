/*
FROM [LiquidPoint_EDW].[dbo].[TReports_EDW_daily] tr with (nolock)
inner join  [LiquidPoint_EDW].[dbo].[TOrder_EDW_daily] tor with (nolock)   on tor.[OrderID]=tr.[OrderID]
inner join [LiquidPoint_EDW].[dbo].[TOrderMisc1_EDW_daily] torm with (nolock) on tor.[OrderID]=torm.[OrderID] and tor.[SystemID]=torm.[SystemID]
left join [LiquidPoint_EDW].[dbo].[TLegs_EDW_daily] tl with (nolock) on tl.[OrderID]=tr.[OrderID] and tl.[LegNumber]=tr.[LegNumber]
  */
select *
from blaze7.order_report rep
         join lateral (select * from blaze7.client_order co where co.order_id = rep.order_id AND co.chain_id = rep.chain_id limit 1) co on true
         LEFT JOIN blaze7.client_order_leg leg ON leg.order_id = co.order_id AND leg.chain_id = co.chain_id and leg.leg_ref_id = rep.leg_ref_id
where rep.db_create_time::date = '2024-06-17'
      -- in treport
     CASE
            WHEN x.leg_ref_id IS NOT NULL THEN ( SELECT leg.payload ->> 'LegSeqNumber'::text
               FROM blaze7.client_order_leg leg
              WHERE leg.order_id = x.order_id AND leg.chain_id = x.chain_id AND leg.leg_ref_id::text = x.leg_ref_id::text)
            ELSE '1'::text
END AS legnumber,
-- in tlegs
    COALESCE(co.payload ->> 'NoLegs'::text, '1'::text) AS legcount,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'LegSeqNumber'::text
            ELSE '1'::text
END AS legnumber,