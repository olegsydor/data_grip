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


select replace(ltrim(replace(left(replace(:inp_guid, '-', ''), 12), '0', ' ')), ' ', '0');
select replace(left(replace(:inp_guid, '-', ''), 12), '0', ' ')