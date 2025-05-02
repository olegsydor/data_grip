select to_char(tr.trade_record_time, 'YYYY-MM-DD') as "Date",
           coalesce(tr.client_order_id, '')            as "OrderID",
           coalesce(tr.secondary_order_id, '')         as "ExchOrderID",
           tr.account_id,
             coalesce(tr.secondary_exch_exec_id, '')     as "ReportID",
           coalesce(tr.exch_exec_id, '')               as "Tag17",
           tr.order_id,
           *
    from dwh.flat_trade_record tr
             left join lateral (select jo.fix_message ->> '143'  as t_143
                                from fix_capture.fix_message_json jo
                                where tr.order_fix_message_id = jo.fix_message_id
                                  and jo.date_id = to_char(tr.order_process_time, 'YYYYMMDD')::integer
                                limit 1) jo on true

             left join dwh.d_exchange dex on dex.exchange_id = tr.exchange_id and dex.is_active
    where true
       and tr.secondary_exch_exec_id in ('l25akrts0002', 'l25akrts0000')
--       and tr.client_order_id = '20250325VSIND28939'
      and tr.date_id between :l_start_date_id and :p_end_date_id
      and tr.account_id = any (:l_account_ids)
      and tr.is_busted = 'N'
--         and tr.order_id in (100000019696533965, 100000019696533916)
--   and not (tr.ex_destination = 'BRKPT' and coalesce(jo.fix_message ->> '143', '-1') is distinct from 'DASH-CBOE')
      and case
              when tr.ex_destination = 'BRKPT' and coalesce(jo.t_143, '-1') is distinct from 'DASH-CBOE'
                  then false
              else true end;


select * from dwh.execution
where exec_date_id = 20250325
and order_id in (100000019696533965, 100000019696533916)
and secondary_exch_exec_id in ('l25akrts0002', 'l25akrts0000')

select * from dwh.d_account
where 	true
  and trading_firm_id in ('xfa', 'xfachi')
		and account_name <> 'XFADESKTCM'


select * from client_order
where parent_order_id = 100000019696533916;
---
select cl.trading_firm_id, fxm.*, ex.*, cl.* --ex.*, order_qty
from client_order cl
		inner join d_account ac on ac.account_id = cl.account_id and ac.is_active = true
-- 		inner join d_trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_active = true
--
-- 		inner join d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
-- 		inner join d_option_contract oc on oc.instrument_id = cl.instrument_id
-- 		inner join d_option_series os on os.option_series_id  = oc.option_series_id
-- 		left join d_time_in_force tif on tif.tif_id = cl.time_in_force_id
        left join lateral
	        (select j.fix_message,j.fix_message->>'143' as tag_143, j.fix_message->>'423' as tag_423,
			        j.fix_message->>'9281' as tag_9281,j.fix_message->>'22017' as tag_22017,
	        		j.fix_message->>'115' as tag_115, j.fix_message->>'109' as tag_109--, j.fix_message->>'5059' as tag_5059, j.fix_message->>'134' as tag_134, j.fix_message->>'135' as tag_135
	         from fix_capture.fix_message_json j
	         where j.fix_message_id  = cl.fix_message_id
	         and j.date_id = :in_date_id
	         limit 1
	        ) fxm on true
        left join lateral (select exch_exec_id
                      from dwh.execution ex
                      where ex.order_id = cl.order_id
                        and ex.exec_type = 'F'
                      ) ex on true

where cl.create_date_id = :in_date_id

/*		and cl.trans_type = 'D'
		and (cl.multileg_reporting_type = '1' or (cl.sub_strategy_desc = 'VEGA' and cl.multileg_reporting_type = '2'))
		and fc.is_high_frequency_trader = 'N'
		and coalesce(tf.cat_imid,'NONE') not in ('NONE','DFIN')
		and fc.fix_comp_id not in ('IRCHNY2EQPT1INT','IRCHNY2EQPT2INT','IRCHNY2EQPT3INT','IRCHNY2OPTPT1INT')
		and (ac.trading_firm_id not in ('BMO','dynamex01','Guggen','nbcanf','daiwa','mirae','miradelta') or fc.fix_comp_id not in ('BOOKP','BOOKP2'))
		--IMC
		and (ac.trading_firm_id not in ('imc01','cutler') or fc.fix_comp_id <> 'IMCCONS')
		--
		and coalesce(tf.cat_suppress,'N') <> 'Y'
		and coalesce(ac.cat_suppress,'N') <> 'Y'
		and cl.ex_destination not in ('RPTR','SQHT','WEEDN','JSEB','TRAFX','FBMS','CTDH','DASH','OUTCR','SLXX','WEX','WEXE','PRIME','UBSPP','WEXX')
		--
		and (cl.ex_destination not in ('BRKPT','BLAZE') or ac.account_name in ('TASTYSPX','TDSPX_BP','TDSWIM_BP','CPRFA_BP','TDA_RFA_BP','ETRADE_RFAC_BP','SCHWABTDA_RFA_BP','FIDOFP_RFA_BP','TICKRS_BP','VSIN_BP'
			))
		and cl.order_id not in (select order_id from compliance.rejected_parent_order where not street_is_generated)
		--and (cl.order_id not in (select ex.order_id from execution ex where ex.exec_date_id = in_date_id and ex.is_parent_level = true and ex.exec_type = '8') or cl.sub_strategy_desc = 'DMA')
		--and not exists (select 1 from execution ex where ex.exec_date_id = in_date_id and ex.order_id  = cl.order_Id and ex.is_parent_level = true and ex.exec_type = '8' limit 1)
		and os.root_symbol not in (select symbol from compliance.test_symbols)
--         and cl.order_id in (100000019696533965, 100000019696533916)
--         and ex.exch_exec_id in ('l25akrts0002', 'l25akrts0000')

 */
  and case
          when cl.parent_order_id is null then true
          when cl.parent_order_id is not null and order_qty >= 250 and cl.trading_firm_id in ('xfa', 'xfachi') and  ac.account_name <> 'XFADESKTCM' then true
          when cl.parent_order_id is not null and order_qty >= 250 and fxm.tag_143 = 'RFAC' then true
          else false end
  and ac.account_id = 73660

select * from dwh.execution ex
    where true
      and ex.exec_date_id > 20250301
      and ex.exec_date_id < 20250401
and ex.exch_exec_id in ('l25akrts0002', 'l25akrts0000')
limit 2
