select CAST('2023-07-18 14:00:11.123456' AS datetime2)

ALTER TABLE Blaze7_dev.dbo.TOrderMisc1_EDW ALTER COLUMN BoxQOOAnnouncedTime datetime2(3) NULL;
ALTER TABLE Blaze7_dev.dbo.TOrderMisc1_EDW ALTER COLUMN BoxQOOAnnouncedTime datetime2 NULL;
ALTER TABLE Blaze7_dev.dbo.TOrderMisc1_EDW ALTER COLUMN BoxQOOAnnouncedTime datetime2 NULL;



use Blaze7_dev
select * from TPrices_EDW
where pg_order_id = 535802370555133952

SELECT SYSDATETIME(), SYSUTCDATETIME()