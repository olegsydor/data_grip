    create temp table report_tmp on commit drop as
    select 'DET' as REC_TYPE,
           2     as out_ord_flag,
           'DET' || '|' || --[1]
           case cl.multileg_reporting_type when '1' then 'SIMPLE' when '2' then 'COMPLEX' else '' end || '|' ||--[2]
           'Dash' || '|' ||--[3]
           case i.instrument_type_id when 'O' then 'OP' when 'E' then 'EQ' else '' end || '|' ||--[4]
           case i.instrument_type_id when 'O' then os.root_symbol when 'E' then i.symbol else '' end || '|' ||--[5]
           case i.instrument_type_id when 'O' then replace(oc.opra_symbol, ' ', '-') else '' end || '|' || --[6]
           case cl.multileg_reporting_type when '1' then '0' when '2' then cl.co_client_leg_ref_id else '' end ||
           '|' || --[7]
           case cl.side
               when '1' then 'Buy'
               when '2' then 'Sell'
               when '5' then 'Short Sell'
               when '6' then 'Short Sell'
               else '' end || '|' ||--[8]
           case oc.put_call when '0' then 'Put' when '1' then 'Call' else '' end || '|' || --[9]
           case cl.open_close when 'O' then 'Open' when 'C' then 'Close' else '' end || '|' || --[10]
           coalesce(ot.order_type_short_name, '') || '|' ||--Order Type --[11]
           --cl.ORDER_QTY||'|'||
--            (cl.order_qty - coalesce((select sum(EX.LAST_QTY)
--                                      from dwh.execution ex
--                                      where ex.order_id = cl.order_id
--                                        and ex.exec_type = 'F'
--                                        and ex.exec_time >= cl.create_time), 0)) || '|' || --[12]
           coalesce(to_char(cl.price, 'FM99990D0000'), '') || '|' ||
           coalesce(to_char(oc.strike_price, 'FM99990D0000'), '') || '|' ||
           coalesce(to_char(cl.stop_price, 'FM99990D0000'), '') || '|' ||
           case
               when i.instrument_type_id = 'O' and cl.order_type_id in ('2', '4') then to_char(cl.PRICE, 'FM99990D0000')
               else '' end || '|' ||--[16]
           '' || '|' ||
           to_char(cl.create_time, 'YYYYMMDD') || '|' ||
           coalesce(to_char(i.last_trade_date, 'YYYYMMDD'), '') || '|' ||
           '' || '|' ||
           '' || '|' ||
           '' || '|' ||
               --
           cl.order_id || '|' || --23
           --
           '' || '|' ||
           cl.client_order_id || '|' || --25
           '' || '|' || --26
           --
           '' || '|' || --Covererd/Uncovered
           '' || '|' ||
           '' || '|' ||
           '' || '|' ||
           '' || '|' || --Record type
           case fc.fix_comp_id when 'ETRADEOFP1' then 'ETRS' when 'ETRADEDEANOFP' then 'DEAN' else '' end
                 as REC
-- select gtc.*
    from dwh.gtc_order_status gtc
             inner join lateral (select multileg_reporting_type,
                                        co_client_leg_ref_id,
                                        side,
                                        open_close,
                                        order_qty,
                                        price,
                                        instrument_id,
                                        order_type_id,
                                        account_id,
                                        stop_price,
                                        order_id,
                                        create_time,
                                        client_order_id,
                                        fix_connection_id
                                 from client_order cl
                                 where order_id = gtc.order_id
                                   and create_date_id = gtc.create_date_id
                                   and parent_order_id is null
                                   and multileg_reporting_type <> '3'
--                                         and case when p_report_date = current_date then true else gtc.create_date_id <= p_report_date end
                                 limit 1) cl on true
             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
        ---------------------------------------------------------------------------------------------------------
             left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
             left join d_option_series os on (oc.option_series_id = os.option_series_id)
             inner join dwh.d_order_type ot on (cl.order_type_id = ot.order_type_id)
             inner join dwh.d_account ac on ac.account_id = cl.account_id and ac.trading_firm_id = 'OFP0016'
             left join dwh.d_fix_connection fc on cl.fix_connection_id = fc.fix_connection_id and fc.is_active
    where gtc.exec_time is null
      and gtc.time_in_force_id = '1'
      and coalesce(gtc.last_trade_date::date, :p_report_date::date + interval '1 day') > :p_report_date::date;
