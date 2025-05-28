Select o.ID as orderID,
       r.ID as reportid,
       r.ExchangeTransactionID tag17,
--        feedcode as secondary_exch_exec_id,
      *
From LiquidPoint_EDW..TReports_EDW r
         inner join LiquidPoint_EDW..TOrder_EDW o
                    on r.ORderID = o.ORdeRID
         inner join LiquidPoint_EDW..TOrderMisc1_EDW om
                    on o.ORdeRID = om.ORdeRID and om.SystemID = o.SystemID
         left outer join EDW_Billing.dbo.DASH_TRADE_Record dtr
                         on dtr.client_order_id = om.CATID
                             and dtr.secondary_exch_exec_id = r.feedcode
                             and dtr.date_id = 20250325
Where r.ORderID in (Select ORDERID
                    from LiquidPoint_EDW..TORDERMisc1_EDW
                    Where [CATID] = '20250325VSIND28939')
  and r.Status in (151, 156)
  and r.ID in (1407944140, 1407944308)
order by r.ExchangeTransactionID;

l25akrts0002
l25akrts0000

Select *
from LiquidPoint_EDW..TORDERMisc1_EDW
Where [CATID] = '20250325VSIND28939'


select r.ID as reportid, r.ExchangeTransactionID as tag17, * From LiquidPoint_EDW..TReports_EDW r
    where r.OrderID in ('00000000-0001-0000-0000-0006A323D1D5','00000000-000F-0000-0000-00036313D1D5')
  and r.Status in (151, 156)


1_2j250325,
F_16250325
select Blaze7.dbo.Guid_To_ClOrdId('00000000-000F-0000-0000-00036313D1D5')
00000000-000F-0000-0000-00036313D1D5

select * from EDW_Billing.dbo.Dash_Trade_Record
where client_order_id ='20250325VSIND28939'
and date_id between 20250325 and 20250326

select replace(ltrim(replace(left(replace(:inp_guid, '-', ''), 12), '0', ' ')), ' ', '0');
select replace(left(replace(:inp_guid, '-', ''), 12), '0', ' ')


'l25aks0c0000',
'l25aks080000',
'l25akrv00000',
'l25aks0g0000',
'l25akrvc0000',
'l25akrvo0002',
'l25aks040000',
'l25akrug0000',
'l25akruc0000',
'l25akrvs0002',
'l25akrvk0000',
'l25akrts0000',
'l25akrv40000',
'l25akruo0000',
'l25akrvk0004',
'l25aks000002',
'l25akru40000',
'l25akrvg0000'


Select o.ID as orderID, r.ID as reportid, r.ExchangeTransactionID tag17, feedcode as secondary_exch_exec_id,*
From LiquidPoint_EDW..TReports_EDW r
inner join LiquidPoint_EDW..TOrder_EDW o
on r.ORderID = o.ORdeRID
inner join LiquidPoint_EDW..TOrderMisc1_EDW om
on o.ORdeRID = om.ORdeRID and om.SystemID = o.SystemID
left outer join EDW_Billing.dbo.DASH_TRADE_Record dtr
on dtr.client_order_id = om.CATID
and dtr.secondary_exch_exec_id = r.feedcode
-- and dtr.date_id = 20250320
Where r.ORderID in (
Select ORDERID
from LiquidPoint_EDW..TORDERMisc1_EDW
Where [CATID] = '20250320VSIND26556'-- '20250325VSIND28939'
) and r.Status in (151,156)
and r.ID in (1407944140,1407944308)
order by r.ExchangeTransactionID