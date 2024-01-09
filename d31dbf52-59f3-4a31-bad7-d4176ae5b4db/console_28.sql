  select to_char(co.create_time, 'DD/MM/YYYY HH:MI:SS AM') as create_date
        , co.client_order_id as cl_ord_id
--        , fmj.leg_rfr_id
        , co_client_leg_ref_id as leg_rfr_id
        , case
            when co.side in ('1','3') then 'BUY'
            when co.side = '5' then 'SELLSHORT'
            else 'SELL'
          end as buy_sell
        , case
	        when i.symbol like 'BRK%' and i.instrument_type_id = 'E' then 'BRK.B'
	        else i.symbol end as symbol
        , (co.order_qty - coalesce(dwh.get_cum_qty_from_orig_orders(in_order_id => co.order_id, in_date_id => co.create_date_id), 0))::varchar as open_quantity
--        , coalesce(co.price, co.stop_price)::varchar as price
        , co.price as price
--        , coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), to_char(co.expire_time, 'YYYYMMDD')) as expiration_date
        , to_char(i.last_trade_date, 'YYYYMMDD') as expiration_date        -- looking at the data, I can see that equity leg has an expiration date value. I can imagine that is the Option Expiry? If so, could you also as an enhancement remove it for the equity legs of MLEG”
        , case
            when oc.put_call = '0' then 'P'
            when oc.put_call = '1' then 'C'
          end as type_code
        , oc.strike_price::varchar as strike
        , gos.order_status,
        fmj.t99 as stop_px,
        co.order_qty,
        case
	        when co_client_leg_ref_id is not null then 'MLEG'
	        when i.instrument_type_id = 'O' then 'OPT'
	        when i.instrument_type_id = 'E' then 'EQ'
--	        when i.instrument_type_id = 'M' then 'MLEG'
	        else i.instrument_type_id end as product_type
      from dwh.gtc_order_status gos
      join dwh.client_order co on gos.order_id = co.order_id and gos.create_date_id = co.create_date_id
      join dwh.d_instrument i on co.instrument_id = i.instrument_id
      left join dwh.d_option_contract oc on i.instrument_id = oc.instrument_id
      left join lateral (select fix_message->>'99' as t99 from fix_capture.fix_message_json fmj where fmj.date_id = co.create_date_id and fmj.fix_message_id = co.fix_message_id limit 1) fmj on true
      where true--co.create_date_id >= :l_gtc_date_id --
        and co.parent_order_id is null -- parent level
/*
        and case when coalesce(p_trading_firm_ids, '{}') = '{}' then true
        else gos.account_id = any(array (select ac.account_id from dwh.d_account ac where ac.trading_firm_id = any (p_trading_firm_ids))) -- in ('OFP0013','LPTF258')) -- GTC orders not found in the 2020
        end
        and case when coalesce(p_account_ids, '{}') = '{}' then true else gos.account_id = any(p_account_ids) end
--        and i.instrument_type_id = l_instrument_type --need Options orders
        and case when l_instrument_type is null then true else i.instrument_type_id = l_instrument_type end--need Options orders
--        and co.trans_type <> 'F' -- don't need cancell requests. hardcode. --(здесь был канселл реквест)
*/        and gos.close_date_id is null
        and co.multileg_reporting_type <> '3'
        and case when co.time_in_force_id = '6' then co.expire_time::date > co.create_time::date else true end
  and co.client_order_id = 'JZ/6232/X42/799840/24005HAEZH '