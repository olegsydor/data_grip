select symbol from staging.trade_record_blaze7;
alter table staging.trade_record_blaze7 add column if not exists symbol_sfx text;


select
	distinct instrument_type_id as instrumentTypeId,
	symbol as symbol,
	symbol_sfx as symbolSfx,
	null as cusip,
	maturity_year as maturityYear,
	maturity_month as maturityMonth,
	maturity_day as maturityDay,
	strike_price as strikePrice,
	put_or_call as putCall
from
	staging.trade_record_missed_lp
where
	symbol_sfx is not null


select symbol_sfx from staging.trade_record_blaze7