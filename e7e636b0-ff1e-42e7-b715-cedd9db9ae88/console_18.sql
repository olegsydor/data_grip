
select client_order_id, count(*)
	from staging.trade_record_missed_lp
		where date_id = 20241014
group by client_order_id
having count(*) > 1

select *
	from trash.so_missed_lp
		where date_id = 20241014
and client_order_id = '1_153241014'