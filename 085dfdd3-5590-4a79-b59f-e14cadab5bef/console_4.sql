use Blaze7;

CREATE function [f_get_is_trade_SOR_routed_exec_id_test_so](@reportID bigint)
    RETURNS integer

BEGIN
    declare @l_return bigint;

    WITH cte (ORdeRID, ParentORdeRID, ExDestination, n, ReportID_INT, ReportID, ChildReportID, ExchangeTransactionID,
              LegNumber, Generation, ChildORders)
             AS (Select r.ORdeRID,
                        o.ParentORdeRID,
                        o.ExDestination,
                        0,
                        r.ID,
                        r.ReportID,
                        convert(nvarchar(38), ISNULL(r.ChildReportID, r.ReportID)),
                        r.ExchangeTransactionID,
                        r.LegNumber,
                        o.Generation,
                        o.ChildORders
                 From LiquidPoint_EDW.dbo.TReports_EDW r with (nolock)
                          Inner join LiquidPoint_EDW.dbo.TOrder_EDW o with (nolock)
                                     on r.ORdeRID = o.OrderID
                 Where r.ID = 1396947131

                 UNION ALL

                 Select r.ORdeRID,
                        o.ParentORdeRID,
                        o.ExDestination,
                        n + 1,
                        r.ID,
                        r.ReportID,
                        convert(nvarchar(38), ISNULL(r.ChildReportID, r.ReportID)),
                        r.ExchangeTransactionID,
                        r.LegNumber,
                        o.Generation,
                        o.ChildORders

                 From LiquidPoint_EDW.dbo.TReports_EDW r with (nolock)
                          Inner join LiquidPoint_EDW.dbo.TOrder_EDW o with (nolock)
                                     on r.ORdeRID = o.OrderID
                          Inner join cte
                                     on o.ParentORdeRID = cte.ORdeRID and (cte.ChildReportID = r.ReportID or
                                                                           cte.ExchangeTransactionID =
                                                                           r.ExchangeTransactionID) and
                                        r.LegNumber = cte.LEgNumber
                 )
    select *--@l_return = sum(case when r.ExDestination is not null then 1 else 1 end) --as routed_to_sor
    --into @l_return
    FROM cte
             --left join AORS.Flexconfig.dbo.TRoute r with(nolock) on  ((CatDestinationID = 'DFIN' or r.ExDestination like '%PAR') and r.ExDestination =cte.ExDestination)  ;
             left join Flexconfig.dbo.TRoute r with (nolock)
                       on ((CatDestinationID = 'DFIN' or r.ExDestination like '%PAR') and
                           r.ExDestination = cte.ExDestination);


    RETURN @l_return

end


select Blaze7.dbo.f_get_is_trade_SOR_routed_exec_id_test_so(1396947162)

1396947162