EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select *
FROM blaze7.torder_edw AS x
WHERE true
  and x.order_trade_date_id between 20250616 and public.get_dateid(public.get_business_date(20250616::text::date, 1))
