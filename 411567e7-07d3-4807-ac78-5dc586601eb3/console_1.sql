create function dwh.get_cum_qty_from_orig_orders_interval(in_order_id bigint, in_date_id integer, in_max_date_id integer)
    returns bigint
    language plpgsql
    immutable
as
$function$
-- 20230628
declare
    l_cum_qty bigint;

begin
    with recursive orig as (select order_id
                                 , orig_order_id
                                 , 1 as level
                                 , create_date_id
                            from client_order
                            where order_id = in_order_id
                              and create_date_id = in_date_id

                            union all

                            select e.order_id
                                 , e.orig_order_id
                                 , r.level + 1
                                 , e.create_date_id
                            from orig r
                                     join client_order e on e.order_id = r.orig_order_id)
    select sum(coalesce(tr.last_qty, 0))::bigint as cum_qty
    into l_cum_qty
    from orig r
             left join lateral
        (
        select tr.order_id, sum(tr.last_qty) as last_qty
        from dwh.flat_trade_record tr
        where tr.order_id = r.order_id
          and tr.date_id >= r.create_date_id
          and tr.date_id <= in_max_date_id
          and tr.is_busted = 'N'
        group by tr.order_id
        ) tr on true
    where tr.last_qty is not null;

    return l_cum_qty;

end;
$function$
;
