CREATE TABLE trash.account_to_delete (
	"Trading Firm ID" varchar(50) NULL,
	"Trading Firm" varchar(50) NULL,
	"Account Name" varchar(50) NULL,
	"Create Date" varchar(50) NULL,
	"First Trade Date" varchar(50) NULL,
	"Last Trade Date" varchar(50) NULL
);

select * from trash.account_to_delete --12752;

select account_id, account_name, trading_firm_id
-- into trash.account_to_delete_ora
from dwh.d_account ac
         join trash.account_to_delete ad
              on ad."Account Name" = ac.account_name and ad."Trading Firm ID" = ac.trading_firm_id
                  and ac.is_active


select * from trash.account_to_delete_ora