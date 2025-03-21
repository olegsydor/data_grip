select max(creation_time),
       max(deleted_time),
       coalesce(case when max(creation_time) < max(deleted_time) then max(creation_time) else max(deleted_time) end, '2025-01-01 00:00:00')
from [dbo].[TEntityMarketDataEntitlement_EDW]
where db_create_time = 20250320--(select max(date_id) from dbo.TOrder_EDW)



SELECT
    CASE
        WHEN DATEPART(WEEKDAY, CAST(GETDATE() AS DATE)) = 2 THEN DATEADD(DAY, -3, CAST(GETDATE() AS DATE))
        WHEN DATEPART(WEEKDAY, CAST(GETDATE() AS DATE)) = 1 THEN DATEADD(DAY, -2, CAST(GETDATE() AS DATE))
        ELSE DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
    END AS LastWorkday;


select * from dbo.TOrder_EDW


select top(1) 'max_processed_id' as [key],
id as [value]
from dbo.TOrder_EDW
where db_create_time >= CONVERT(datetime, convert(varchar(10), '20250321'))


select CONVERT(datetime, convert(varchar(10), '20250321'))