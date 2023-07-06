create function dash360.get_mtm_exposure_report(in_trading_firm_id character varying)
    returns table
            (
                account_id        integer,
                side              character,
                symbol            character varying,
                orders_count      bigint,
                open_orders_count bigint,
                leaves_qty        numeric,
                exec_qty          numeric,
                exec_principal    numeric,
                leaves_principal  numeric
            )
    language plpgsql
as $function$
declare
    l_date_id int4;
begin
    l_date_id = public.get_business_date_gth(current_date);
    return query
        select ba.account_id,
               ba.side,
               ba.symbol,
               count(1)                 as orders_count,
               sum(ba.is_open)          as open_orders_count,
               sum(ba.leaves_qty)       as leaves_qty,
               sum(ba.exec_qty)         as exec_qty,
               sum(ba.exec_principal)   as exec_principal,
               sum(ba.leaves_principal) as leaves_principal
        from (select cl.order_id,
                  cl.account_id,
                     case when dfe.last_exec_id is null then 1 else 0 end                                       as is_open,
                     cl.order_qty,
                     cl.side,
                     i.symbol                                                                                      symbol,
                     coalesce(tr.exec_qty, 0)                                                                      exec_qty,
                     coalesce(tr.exec_qty, 0) * coalesce(cl.price, 0.0)                                            exec_principal,
                     case
                         when dfe.last_exec_id is null then cl.order_qty - coalesce(tr.exec_qty, 0)
                         else 0 end                                                                             as leaves_qty,
                     case
                         when dfe.last_exec_id is null then cl.order_qty - coalesce(tr.exec_qty, 0)
                         else 0 * coalesce(cl.price, 0.0) end                                                   as leaves_principal
              from dwh.client_order cl
                       left join lateral (select ex.exec_id as last_exec_id
                                          from dwh.execution ex
                                          where ex.order_id = cl.order_id
                                            and ex.exec_date_id >= cl.create_date_id
                                          order by ex.exec_id desc
                                          limit 1) dfe on true
                       inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id
                       inner join dwh.d_account ac on ac.account_id = cl.account_id
                      join lateral
                  (select sum(last_qty) as exec_qty,
                          max(exec_time) as last_trade_time
                   from execution ex
                   where ex.order_id = cl.order_id
                     and ex.exec_type = 'F'
                     and ex.is_busted = 'N'
                     and ex.exec_date_id = :l_date_id
                   limit 1) tr on true
              left join lateral (select * from dwh.flat_trade_record ftr where ftr.order_id = cl.order_id)
              where true
                and cl.parent_order_id is null
                and cl.create_date_id = :l_date_id
                and cl.trans_type in ('D', 'G')
                and cl.multileg_reporting_type in ('1', '2')
                and i.instrument_type_id = 'E'
                and ac.trading_firm_id = 'dftdesk02'--p_tf_id
             ) ba
        group by ba.account_id
               , ba.side
               , ba.symbol;
end;

$function$
;

select max(last_qty), max(exec_time)
from dwh.execution ex
where ex.order_id in (12436961296
    )
  and ex.exec_type = 'F'
  and ex.is_busted = 'N'

select * from dwh.flat_trade_record
where order_id in (12436961296)