with c as (select bust.ID as bust_id, tr.*
           FROM [LiquidPoint_EDW].[dbo].[TReports_EDW_daily] tr with (nolock)
                    left join (select r.ID
                               From [LiquidPoint_EDW].dbo.TReports_EDW_Daily r with (nolock)
                                        inner join [LiquidPoint_EDW].dbo.TReports_EDW_Daily r2 with (nolock)
                                                   on convert(varchar(255), r2.TradeCancelledReportID) = r.ReportID
                                                       and
                                                      ((r.OrderID = r2.OrderID and r2.status in (149, 194, 152)))) bust
                              on bust.ID = tr.ID)
select top(10) * from c
where bust_id is not null;


select r.OrderID, r.ReportID, r2.TradeCancelledReportID, r2.status, 8
From [LiquidPoint_EDW].dbo.TReports_EDW_Daily r with (nolock)
         inner join [LiquidPoint_EDW].dbo.TReports_EDW_Daily r2 with (nolock)
                    on convert(varchar(255), r2.TradeCancelledReportID) = r.ReportID
                        and r.OrderID = r2.OrderID and r2.status in (149, 194, 152)
where r.id = 1392189600;

select * from [LiquidPoint_EDW].dbo.TReports_EDW_Daily r
where exists (select 1 from [LiquidPoint_EDW].dbo.TReports_EDW_Daily r2 where r2.TradeCancelledReportID = r.ReportID and r.OrderID = r2.OrderID and r2.status in (149, 194, 152))
and r.id in ( 1392189600,1392189469,1392189498,1392189628,1392189499,1392189536,1392191921,1392191299,1392191333,1392191955)


select OrderID, TradeCancelledReportID, ReportID, status, * from [LiquidPoint_EDW].dbo.TReports_EDW_Daily
where id = 1392189600;

00000000-001B-0000-0000-000686B3ABE2
00000000-0001-0000-0000-000686B3ABE2
00000000-0001-0000-0000-000686B3ABE2
00000000-001B-0000-0000-000686B3ABE2
00000000-001B-0000-0000-000686B3ABE2
;

    select * from Blaze7.dbo.TReports_EDW
where OrderID in ('00000000-0001-0000-0000-000686B3ABE2','00000000-0001-0000-0000-00076713ABE2','00000000-001B-0000-0000-00076713ABE2','00000000-001B-0000-0000-00076713ABE2','00000000-0001-0000-0000-00076713ABE2')
