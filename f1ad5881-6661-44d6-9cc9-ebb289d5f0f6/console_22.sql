SELECT *
--       tordermisc1.pg_order_id                 AS pg_ord_id,
--       round(tordermisc1.acctcomm::NUMERIC, 8) AS acctcomm
into trash.tordermisc_edw
FROM staging.edw_blaze7_tordermisc1 AS tordermisc1
WHERE COALESCE(order_trade_date_id, 0) between :p_date_id and public.get_dateid(public.get_business_date(:p_date_id::text::date, 1))
  and upper(tordermisc1.pg_entity) = 'UAT'
