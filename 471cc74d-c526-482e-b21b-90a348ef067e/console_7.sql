select max(creation_time),
       max(deleted_time),
       coalesce(case when max(creation_time) < max(deleted_time) then max(creation_time) else max(deleted_time) end, '2025-01-01 00:00:00')
from [dbo].[TEntityMarketDataEntitlement_EDW]
where db_create_time = 20250320--(select max(date_id) from dbo.TOrder_EDW)