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
                                     and ex.exec_date_id >= 20240523

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
                                 and ex.exec_date_id >= 20240523)
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
	  from trash.matched_cross_trades_pg
except
select *
	  from dash_reporting.matched_cross_trades_pg;



create temp table t_os as
SELECT ex_o.exec_id AS orig_exec_id,
exi.exec_id::int8 AS contra_exec_id
, cl_o.order_id
,cl_o.create_date_id
 ,cro.cross_order_id
,cro.date_id

--                 ,
--                 exi.exec_id  AS contra_exec_id
FROM dwh.client_order cl_o
         INNER JOIN dwh.d_instrument i ON i.instrument_id = cl_o.instrument_id
         INNER JOIN dwh.d_fix_connection fc ON fc.fix_connection_id = cl_o.fix_connection_id
         INNER JOIN dwh.execution ex_o
                    ON ex_o.order_id = cl_o.order_id
                        AND ex_o.exec_date_id >= :in_date_id
         INNER JOIN dwh.cross_order cro ON cro.cross_order_id = cl_o.cross_order_id
         INNER JOIN dwh.d_account ac ON ac.account_id = cl_o.account_id
         INNER JOIN dwh.d_trading_firm tf ON tf.trading_firm_id = ac.trading_firm_id

         inner join lateral (select exi.exec_id
                             from dwh.client_order cli
                                      join dwh.execution exi on exi.order_id = cli.order_id
                             where cli.cross_order_id = cl_o.cross_order_id
                               AND cli.instrument_id = cl_o.instrument_id
                               AND cli.is_originator = 'C'
                               and exi.exec_type = 'F'
                               AND exi.last_qty = ex_o.last_qty
                               AND exi.last_px = ex_o.last_px
                             and cli.create_date_id = cro.date_id
                             and exi.exec_date_id >= cli.create_date_id
                             order by exi.exec_id desc
                             limit 1
    ) exi on true
WHERE cl_o.create_date_id = :in_date_id
  AND cl_o.multileg_reporting_type IN ('1', '2')
  AND cl_o.parent_order_id IS NOT NULL
  AND ex_o.is_busted = 'N'
  AND ex_o.exec_type = 'F'
  AND cl_o.trans_type <> 'F'
  AND tf.is_eligible4consolidator = 'Y'
  AND cl_o.internal_component_type = 'A'
  AND fc.fix_comp_id <> 'IMCCONS'
  AND cl_o.is_originator = 'O';

select  orig_exec_id, contra_exec_id from t_os
;
create temp drop table t_new as
select * from (select orig_exec_id,
                      contra_exec_id,
                      row_number() over (partition by orig_exec_id order by orig_exec_id desc)     as orig_rn,
                      row_number() over (partition by contra_exec_id order by contra_exec_id desc) as contra_rn
               from t_os
               ) x
--          where orig_exec_id = 100000076165891196
where x.orig_rn = 1 or x.contra_rn = 1;
------------
create temp table t_orig as
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
    order by CL.CROSS_ORDER_ID, CL.ORDER_ID, EX.EXEC_ID;

    create temp table t_cross as
    select t_orig.*, ex.exec_id as contra_exec_id
    from t_orig
             join dwh.client_order cl on cl.cross_order_Id = t_orig.cross_order_id
        and cl.instrument_id = t_orig.instrument_id
        and cl.is_originator = 'C'
             join dwh.execution ex on ex.order_id = cl.order_id
    where true
      and t_orig.last_qty = ex.last_qty
      and t_orig.last_px = ex.last_px
      and ex.exec_type = 'F'
--       and cl.create_date_id = :in_date_id
      and ex.exec_date_id = :in_date_id;

select --orig_exec_id,
       contra_exec_id
from trash.matched_cross_trades_pg
except
select --orig_exec_id,
       contra_exec_id
from t_os
except
select  orig_exec_id, contra_exec_id
from trash.matched_cross_trades_pg
where contra_exec_id = 100000076192461578

select * from t_new
where orig_exec_id = 100000076165891196;;

INSERT INTO dash_reporting.matched_cross_trades_pg (orig_exec_id, contra_exec_id)
SELECT DISTINCT
       ex_o.exec_id AS orig_exec_id,
       ex_c.exec_id AS contra_exec_id
FROM dwh.client_order cl_o
         INNER JOIN dwh.d_instrument i ON i.instrument_id = cl_o.instrument_id
         INNER JOIN dwh.d_fix_connection fc ON fc.fix_connection_id = cl_o.fix_connection_id
         INNER JOIN dwh.execution ex_o
                    ON ex_o.order_id = cl_o.order_id
                        AND ex_o.exec_date_id >= :in_date_id
         INNER JOIN dwh.cross_order cro ON cro.cross_order_id = cl_o.cross_order_id
         INNER JOIN dwh.d_account ac ON ac.account_id = cl_o.account_id
         INNER JOIN dwh.d_trading_firm tf ON tf.trading_firm_id = ac.trading_firm_id
         -- З’єднання з контр-трейдами (is_originator = 'C')
         INNER JOIN dwh.client_order cl_c
                    ON cl_c.cross_order_id = cl_o.cross_order_id
                        AND cl_c.instrument_id = cl_o.instrument_id
                        AND cl_c.is_originator = 'C'
         INNER JOIN dwh.execution ex_c
                    ON ex_c.order_id = cl_c.order_id
                        AND ex_c.exec_type = 'F'
                        AND ex_c.last_qty = ex_o.last_qty
                        AND ex_c.last_px = ex_o.last_px
                        AND ex_c.exec_date_id >= :in_date_id
WHERE cl_o.create_date_id = :in_date_id
  AND cl_o.multileg_reporting_type IN ('1', '2')
  AND cl_o.parent_order_id IS NOT NULL
  AND ex_o.is_busted = 'N'
  AND ex_o.exec_type = 'F'
  AND cl_o.trans_type <> 'F'
  AND tf.is_eligible4consolidator = 'Y'
  AND cl_o.internal_component_type = 'A'
  AND fc.fix_comp_id <> 'IMCCONS'
  AND cl_o.is_originator = 'O'
  -- уникаємо дублікатів, які вже є в цільовій таблиці
  AND NOT EXISTS (
      SELECT 1
      FROM dash_reporting.matched_cross_trades_pg mct
      WHERE mct.orig_exec_id = ex_o.exec_id
         OR mct.contra_exec_id = ex_c.exec_id
  );
