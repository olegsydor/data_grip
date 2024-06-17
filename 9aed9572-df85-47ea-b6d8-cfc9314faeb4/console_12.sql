/*
FROM [LiquidPoint_EDW].[dbo].[TReports_EDW_daily] tr with (nolock)
inner join  [LiquidPoint_EDW].[dbo].[TOrder_EDW_daily] tor with (nolock)   on tor.[OrderID]=tr.[OrderID]
inner join [LiquidPoint_EDW].[dbo].[TOrderMisc1_EDW_daily] torm with (nolock) on tor.[OrderID]=torm.[OrderID] and tor.[SystemID]=torm.[SystemID]
left join [LiquidPoint_EDW].[dbo].[TLegs_EDW_daily] tl with (nolock) on tl.[OrderID]=tr.[OrderID] and tl.[LegNumber]=tr.[LegNumber]
  */

create function staging.get_status(in_exec_type bpchar,
                                   in_child_exec_ref_id text,
                                   in_originated_by text)
    returns bpchar
    language sql
as
$$

select case
           when in_exec_type in ('e', 'd') then
               (select case
                           when rp.exec_type = '4' and (rp.payload ->> 'OriginatedBy') = 'E' then 'F'
                           else rp.exec_type
                           end as exec_type
                from blaze7.order_report rp
                where rp.exec_id::text = in_child_exec_ref_id)
           when in_exec_type = '4'::bpchar and in_originated_by = 'e'
               then 'F'::bpchar
           else in_exec_type
           end
$$;


select rep.payload ->> 'TransactTime' AS transactiondatetime,
       to_char((rep.payload ->> 'TransactTime')::timestamp, 'YYYYMMDD')::int4 AS transactiondatetime,
       staging.get_status(rep.exec_type, rep.payload ->> 'ChildExecRefId', rep.payload ->> 'originatedby'),
--        case when exists (select null from blaze7.order_report r
--                                      join blaze7.order_report r2 on (r2.payload ->> 'BustExecRefId')::varchar(30) = r.exec_id and r.order_id = r2.order_id
--                                                                         and staging.get_status(r2.exec_type, r2.payload ->> 'ChildExecRefId', r2.payload ->> 'originatedby' ) )
       'LPEDW' as subsystem_id,
       
       *
from blaze7.order_report rep
         join lateral (select * from blaze7.client_order co where co.order_id = rep.order_id AND co.chain_id = rep.chain_id limit 1) co on true
         LEFT JOIN blaze7.client_order_leg leg ON leg.order_id = co.order_id AND leg.chain_id = co.chain_id and leg.leg_ref_id = rep.leg_ref_id
left join
where rep.db_create_time::date = '2024-06-17'
