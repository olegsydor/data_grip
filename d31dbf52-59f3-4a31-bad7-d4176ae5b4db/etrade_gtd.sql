select * from report_tmp

create temp table report_tmp as
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
           (cl.order_qty - cum_qty)::text || '|' || --[12]
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
           AC.BROKER_DEALER_MPID --MPID
                 as REC
-- select gtc.*
   		from dwh.gtc_order_status gtc
   		    join dwh.CLIENT_ORDER CL using (create_date_id, order_id)
        inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
		---------------------------------------------------------------------------------------------------------
                   inner join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id)
                   inner join dwh.d_option_series os on (oc.option_series_id = os.option_series_id)
		inner join dwh.d_ORDER_TYPE OT on (CL.ORDER_TYPE_id = OT.ORDER_TYPE_ID)
		inner join dwh.mv_ACTIVE_ACCOUNT_SNAPSHOT AC on (CL.ACCOUNT_ID = AC.ACCOUNT_ID )

   		left join lateral
            (
              select
                sum(case when exc.exec_type = 'F' then exc.last_qty else 0 end) as cum_qty
              from dwh.execution exc
              where exc.exec_date_id >= gtc.create_date_id
                and exc.order_id = gtc.order_id
                and exc.is_busted = 'N'
              group by exc.order_id
              limit 1
            ) ex on true


		where true
		and AC.TRADING_FIRM_ID in ('OFP0016')
	    --and trunc(CL.CREATE_TIME) = trunc(sysdate-1)
		and CL.PARENT_ORDER_ID is NULL
		and CL.TRANS_TYPE <> 'F'
        and coalesce(gtc.LAST_TRADE_DATE, '2023-12-12'::date + '1 day'::interval) > '2023-12-12'::date
        and CL.TIME_IN_FORCE_id = '1'
        and CL.MULTILEG_REPORTING_TYPE <> '3'
        and not exists (select null from dwh.EXECUTION exc where exc.order_id = gtc.order_id and exc.exec_date_id >= gtc.create_date_id and exc.ORDER_STATUS in ('2','4','8'))
		and gtc.close_date_id is null



select 'DET' as REC_TYPE,
           2     as OUT_ORD_FLAG,
           array_to_string(ARRAY [
                               'DET', --||'|'|| --[1]
                               case CL.MULTILEG_REPORTING_TYPE
                                   when '1' then 'SIMPLE'
                                   when '2' then 'COMPLEX' end, --||'|'||--[2]
                               'Dash', --||'|'||--[3]
                               case I.INSTRUMENT_TYPE_ID when 'O' then 'OP' when 'E' then 'EQ' end, --||'|'||--[4]
                               case I.INSTRUMENT_TYPE_ID
                                   when 'O' then os.ROOT_SYMBOL
                                   when 'E' then I.SYMBOL end, --||'|'||--[5]
                               case I.INSTRUMENT_TYPE_ID
                                   when 'O' then replace(oc.OPRA_SYMBOL, ' ', '-') end, --||'|'|| --[6]
                               case CL.MULTILEG_REPORTING_TYPE
                                   when '1' then '0'
                                   when '2' then CL.CO_CLIENT_LEG_REF_ID end, --||'|'|| --[7]
                               case CL.SIDE
                                   when '1' then 'Buy'
                                   when '2' then 'Sell'
                                   when '5' then 'Short Sell'
                                   when '6' then 'Short Sell' end, --||'|'||--[8]
                               case oc.PUT_CALL when '0' then 'Put' when '1' then 'Call' end, --||'|'|| --[9]
                               case CL.OPEN_CLOSE when 'O' then 'Open' when 'C' then 'Close' end, --||'|'|| --[10]
                               OT.ORDER_TYPE_SHORT_NAME, --||'|'||--Order Type --[11]
               --CL.ORDER_QTY||'|'||
                               (cl.order_qty - coalesce(ex.sum_last_qty, 0::int)), --||'|'|| --[12]
                               to_char(CL.PRICE, 'FM99990D0000'), --||'|'||
                               to_char(oc.STRIKE_PRICE, 'FM99990D0000'), --||'|'||
                               to_char(CL.STOP_PRICE, 'FM99990D0000'), --||'|'||
                               case
                                   when I.INSTRUMENT_TYPE_ID = 'O' and CL.ORDER_TYPE_id in ('2', '4')
                                       then to_char(CL.PRICE, 'FM99990D0000')
                                   end, --||'|'||--[16]
                               '', --||'|'||
                               to_char(CL.CREATE_TIME, 'YYYYMMDD'), --||'|'||
                               to_char(I.LAST_TRADE_DATE, 'YYYYMMDD'), --||'|'||
                               '', --||'|'||
                               '', --||'|'||
                               '', --||'|'||
               --
                               CL.ORDER_ID, --||'|'|| --23
               --
                               '', --||'|'||
                               CL.CLIENT_ORDER_ID, --||'|'|| --25
                               '', --||'|'|| --26
               --
                               '', --||'|'|| --Covererd/Uncovered
                               '', --||'|'||
                               '', --||'|'||
                               '', --||'|'||
                               '', --||'|'|| --Record type
                               ac.broker_dealer_mpid -- --mpid
                               ], '|', '')
    from dwh.gtc_order_status gtc
             join dwh.client_order cl using (create_date_id, order_id)
             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
        ---------------------------------------------------------------------------------------------------------
             left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
             left join dwh.d_option_series os on oc.option_series_id = os.option_series_id
             inner join dwh.d_order_type ot on (cl.order_type_id = ot.order_type_id)
             inner join dwh.mv_active_account_snapshot ac on (cl.account_id = ac.account_id)
             left join lateral (select sum(ex.last_qty)::bigint as sum_last_qty
                                from dwh.execution ex
                                where ex.order_id = cl.order_id
                                  and ex.exec_type = 'F'
                                  and exec_date_id >= cl.create_date_id
                                limit 1) ex on true
    where true
      and gtc.account_id in
          (select account_id from dwh.mv_active_account_snapshot ac where ac.trading_firm_id = 'OFP0016')
      and cl.parent_order_id is null
      and cl.trans_type <> 'F'

      and coalesce(gtc.last_trade_date, '2023-12-09') > '2023-12-08'
      and gtc.time_in_force_id = '1'
      and cl.multileg_reporting_type <> '3'

      and gtc.close_date_id is null
      and not exists(select null
                     from dwh.execution ex
                     where ex.order_id = cl.order_id
                       and ex.exec_date_id >= cl.create_date_id
                       and ORDER_STATUS in ('2', '4', '8'));