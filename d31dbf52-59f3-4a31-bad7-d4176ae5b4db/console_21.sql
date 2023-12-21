ac.trading_firm_id in ('baml')
cl.sub_strategy = 'DMA' then '0x04'

select * from dwh.d_account ac
where row_to_json(ac.*)::text ilike '%ARCA%'