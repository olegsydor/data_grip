create temp table t_os2 as
        select ca.auction_id --, count(1) as cnt
          , max(ca.create_date_id) as auction_date_id
          --, min(ca.create_date_id) as min_order_create_date_id
--          , (select min(au.create_date_id) from dwh.client_order2auction au where ca.auction_id = au.auction_id) as min_order_create_date_id
          , (select au.create_date_id from dwh.client_order2auction au where ca.auction_id = au.auction_id order by 1 limit 1) as min_order_create_date_id
 create temp table t_os as
        select ca.auction_id,
        max(ca.create_date_id) over (partition by ca.auction_id),
        min(ca.create_date_id) over (partition by ca.auction_id)
        from dwh.client_order2auction ca
          join dwh.client_order co
            on ca.order_id = co.order_id
            and co.create_date_id = :l_cur_date_id
        where ca.create_date_id = :l_cur_date_id -- date for recalculation. It is not including old GTC orders for the current auction_date_id which is problem.
          and coalesce(co.trans_type, '-1') <> 'F' -- Cancel requests are generating new auction_date_id for old auctions.Suppressing.
          and (:l_is_current_recalc = true
              or coalesce(co.time_in_force_id, '-1') not in ('1','6')) -- exclude GTC,GTD from recalculations based on create_date_id of orders
         group by ca.auction_id

 create temp table t_os as
        select ca.auction_id,
        max(ca.create_date_id) over (partition by ca.auction_id),
        min(ca.create_date_id) over (partition by ca.auction_id)
        from dwh.client_order2auction ca
          join dwh.client_order co
            on ca.order_id = co.order_id
            and co.create_date_id = :l_cur_date_id
        where ca.create_date_id = :l_cur_date_id -- date for recalculation. It is not including old GTC orders for the current auction_date_id which is problem.
          and coalesce(co.trans_type, '-1') <> 'F' -- Cancel requests are generating new auction_date_id for old auctions.Suppressing.
          and (:l_is_current_recalc = true
              or coalesce(co.time_in_force_id, '-1') not in ('1','6')) -- exclude GTC,GTD from recalculations based on create_date_id of orders

create index on t_os (auction_id)Lj
select distinct on (t_os.auction_id) * from t_os
except

select * from t_os2
except
select distinct on (t_os.auction_id) * from t_os