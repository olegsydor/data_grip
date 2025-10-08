    truncate table dash_reporting.matched_cross_trades_pg;

    for orig_trade in (
    create temp table t_orig_trade as
    select CL.CROSS_ORDER_ID,
                              CL.ORDER_ID,
                              CL.IS_ORIGINATOR,
                              CL.INSTRUMENT_ID,
                              EX.EXEC_ID,
                              EX.ORDER_STATUS,
                              EX.LAST_QTY,
                              EX.LAST_PX
                       from dwh.CLIENT_ORDER CL
                                inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                                inner join dwh.d_FIX_CONNECTION FC on (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
                                inner join dwh.EXECUTION EX
                                           on CL.ORDER_ID = EX.ORDER_ID and ex.exec_date_id >= :in_date_id
                                inner join dwh.CROSS_ORDER CRO on CRO.CROSS_ORDER_ID = CL.CROSS_ORDER_ID
                                inner join dwh.d_ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
                                inner join dwh.d_TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
                       where cl.create_date_id = :in_date_id
                         and CL.MULTILEG_REPORTING_TYPE in ('1', '2')
                         and CL.PARENT_ORDER_ID is not null
                         and EX.IS_BUSTED = 'N'
                         and EX.EXEC_TYPE = 'F'
                         and CL.TRANS_TYPE <> 'F'
                         and TF.IS_ELIGIBLE4CONSOLIDATOR = 'Y'
                         and CL.INTERNAL_COMPONENT_TYPE = 'A'
                         and FC.FIX_COMP_ID <> 'IMCCONS'
                       order by CL.CROSS_ORDER_ID, CL.ORDER_ID, EX.EXEC_ID
    )

    select * from t_orig_trade
--14107
select ex.exec_id
                                 from dwh.execution ex
                                          inner join dwh.client_order cl on ex.order_id = cl.order_id
                                 join t_orig_trade orig_trade on
                                 cl.cross_order_Id = orig_trade.cross_order_id
                                   and cl.instrument_id = orig_trade.instrument_id
                                   and cl.is_originator = 'C'
                                   and orig_trade.last_qty = ex.last_qty
                                   and orig_trade.last_px = ex.last_px
                                   and ex.exec_type = 'F'
                                     and ex.exec_date_id >= :in_date_id2

        loop


            v_orig_exec_id := orig_trade.exec_id;
            --v_contra_exec_id := 0;
            for contra_trade in (select ex.exec_id
                                 from dwh.execution ex
                                          inner join dwh.client_order cl on ex.order_id = cl.order_id
                                 where cl.cross_order_Id = orig_trade.cross_order_id
                                   and cl.instrument_id = orig_trade.instrument_id
                                   and cl.is_originator = 'C'
                                   and orig_trade.last_qty = ex.last_qty
                                   and orig_trade.last_px = ex.last_px
                                   and ex.exec_type = 'F')
                loop
                    merge into dash_reporting.matched_cross_trades_pg as mct
                    using (select v_orig_exec_id as orig_exec_id, contra_trade.exec_id as contra_exec_id) mt
                    on (mct.orig_exec_id = mt.orig_exec_id or mct.contra_exec_id = mt.contra_exec_id)
                    when not matched then
                        insert (orig_exec_id, contra_exec_id)                        values (v_orig_exec_id, mt.contra_exec_id);
                end loop;
        end loop;


-- DROP PROCEDURE dash_reporting.match_cross_trades_pg(int4);

CREATE OR REPLACE PROCEDURE trash.so_match_cross_trades_pg(IN in_date_id integer)
 LANGUAGE plpgsql
AS $procedure$
declare
    orig_trade     record;
    contra_trade   record;
    v_orig_exec_id int8;
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, '>>>>>>> trash match_cross_trades_pg for ' || in_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    -- Matching orders

    truncate table trash.matched_cross_trades_pg;

    for orig_trade in (select CL.CROSS_ORDER_ID,
                              CL.ORDER_ID,
                              CL.IS_ORIGINATOR,
                              CL.INSTRUMENT_ID,
                              EX.EXEC_ID,
                              EX.ORDER_STATUS,
                              EX.LAST_QTY,
                              EX.LAST_PX
                       from dwh.CLIENT_ORDER CL
                                inner join dwh.d_INSTRUMENT I on I.INSTRUMENT_ID = CL.INSTRUMENT_ID
                                inner join dwh.d_FIX_CONNECTION FC on (FC.FIX_CONNECTION_ID = CL.FIX_CONNECTION_ID)
                                inner join dwh.EXECUTION EX
                                           on CL.ORDER_ID = EX.ORDER_ID and ex.exec_date_id >= in_date_id
                                inner join dwh.CROSS_ORDER CRO on CRO.CROSS_ORDER_ID = CL.CROSS_ORDER_ID
                                inner join dwh.d_ACCOUNT AC on AC.ACCOUNT_ID = CL.ACCOUNT_ID
                                inner join dwh.d_TRADING_FIRM TF on TF.TRADING_FIRM_ID = AC.TRADING_FIRM_ID
                       where cl.create_date_id = in_date_id
                         and CL.MULTILEG_REPORTING_TYPE in ('1', '2')
                         and CL.PARENT_ORDER_ID is not null
                         and EX.IS_BUSTED = 'N'
                         and EX.EXEC_TYPE = 'F'
                         and CL.TRANS_TYPE <> 'F'
                         and TF.IS_ELIGIBLE4CONSOLIDATOR = 'Y'
                         and CL.INTERNAL_COMPONENT_TYPE = 'A'
                         and FC.FIX_COMP_ID <> 'IMCCONS'
                       order by CL.CROSS_ORDER_ID, CL.ORDER_ID, EX.EXEC_ID)

        loop


            v_orig_exec_id := orig_trade.exec_id;
            --v_contra_exec_id := 0;
            for contra_trade in (select ex.exec_id
                                 from dwh.execution ex
                                          inner join dwh.client_order cl on ex.order_id = cl.order_id
                                 where cl.cross_order_Id = orig_trade.cross_order_id
                                   and cl.instrument_id = orig_trade.instrument_id
                                   and cl.is_originator = 'C'
                                   and orig_trade.last_qty = ex.last_qty
                                   and orig_trade.last_px = ex.last_px
                                   and ex.exec_type = 'F'
                                 and ex.exec_date_id = in_date_id)
                loop
                    merge into trash.matched_cross_trades_pg as mct
                    using (select v_orig_exec_id as orig_exec_id, contra_trade.exec_id as contra_exec_id) mt
                    on (mct.orig_exec_id = mt.orig_exec_id or mct.contra_exec_id = mt.contra_exec_id)
                    when not matched then
                        insert (orig_exec_id, contra_exec_id)
                        values (v_orig_exec_id, mt.contra_exec_id);
                end loop;
        end loop;
      select count(*) into l_row_cnt
	  from trash.matched_cross_trades_pg;

    select public.load_log(l_load_id, l_step_id, '>>>>>>> trash match_cross_trades_pg for ' || in_date_id::text || ' COMPLETED===',
                           l_row_cnt, 'O')
    into l_step_id;
end;
$procedure$
;

call trash.so_match_cross_trades_pg(in_date_id := 20251007)


select *
	  from trash.matched_cross_trades_pg;