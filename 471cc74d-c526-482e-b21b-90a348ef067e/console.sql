select CAST('2023-07-18 14:00:11.123456' AS datetime2)

ALTER TABLE Blaze7_dev.dbo.TOrderMisc1_EDW ALTER COLUMN BoxQOOAnnouncedTime datetime2(3) NULL;
ALTER TABLE Blaze7_dev.dbo.TOrderMisc1_EDW ALTER COLUMN BoxQOOAnnouncedTime datetime2 NULL;
ALTER TABLE Blaze7_dev.dbo.TOrderMisc1_EDW ALTER COLUMN BoxQOOAnnouncedTime datetime2 NULL;



use Blaze7_dev;
select * from TPrices_EDW
where date_id = 20230718
    and pg_order_id = 535822291003523072

SELECT SYSDATETIME(), SYSUTCDATETIME()

use Blaze7_dev;
select *
--delete
from TOrderMisc1_EDW
where date_id = 20230718
    and pg_order_id = 535793635686367234



select 'max_processed_time_leg' as [key],
coalesce(max(pg_db_create_time), '2020-01-01 00:00:00') as [value]
from [dbo].[tlegs_edw]
where date_id = '"+context.p_date_id+"'
and pg_entity = '"+context.pg_entity+"'


use blaze7_dev;
select * from [TEST_DT_EDW]