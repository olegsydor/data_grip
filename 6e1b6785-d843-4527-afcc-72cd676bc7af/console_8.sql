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

 create temp table t_os3 as
        select distinct on (ca.auction_id) ca.auction_id,
        max(ca.create_date_id) over (partition by ca.auction_id),
        min(ca.create_date_id) over (partition by ca.auction_id)
        from dwh.client_order2auction ca
          join dwh.client_order co
            on ca.order_id = co.order_id
            and co.create_date_id = :l_cur_date_id
        where ca.create_date_id = :l_cur_date_id -- date for recalculation. It is not including old GTC orders for the current auction_date_id which is problem.
          and coalesce(co.trans_type, '-1') <> 'F' -- Cancel requests are generating new auction_date_id for old auctions.Suppressing.
          and (:l_is_current_recalc = true
              or coalesce(co.time_in_force_id, '-1') not in ('1','6')); -- exclude GTC,GTD from recalculations based on create_date_id of orders

create index on t_os (auction_id)Lj
select distinct on (t_os.auction_id) * from t_os
except

select * from t_os2
except
select distinct on (t_os.auction_id) * from t_os;





        select ca.auction_id --, count(1) as cnt
          , max(ca.create_date_id) as auction_date_id
          --, min(ca.create_date_id) as min_order_create_date_id
-- OS 20250310         , (select min(au.create_date_id) from dwh.client_order2auction au where ca.auction_id = au.auction_id) as min_order_create_date_id
          , (select au.create_date_id from dwh.client_order2auction au where ca.auction_id = au.auction_id order by 1 limit 1) as min_order_create_date_id
        from dwh.client_order2auction ca
          join dwh.client_order co
            on ca.order_id = co.order_id
            and co.create_date_id = l_cur_date_id
        where ca.create_date_id = l_cur_date_id -- date for recalculation. It is not including old GTC orders for the current auction_date_id which is problem.
          and coalesce(co.trans_type, '-1') <> 'F' -- Cancel requests are generating new auction_date_id for old auctions.Suppressing.
          and (l_is_current_recalc = true
              or coalesce(co.time_in_force_id, '-1') not in ('1','6')) -- exclude GTC,GTD from recalculations based on create_date_id of orders
        group by ca.auction_id
        union all

        select rd.auction_id
          , max(rd.auction_date_id) as auction_date_id
-- OS 20250310          , (select min(au.create_date_id) from dwh.client_order2auction au where rd.auction_id = au.auction_id) as min_order_create_date_id
           ,(select au.create_date_id from dwh.client_order2auction au where rd.auction_id = au.auction_id order by 1 limit 1) as min_order_create_date_id
        from
          (
            select rd.auction_id, auction_date_id -- hope one auction is present in one auction date
            from data_marts.f_rfq_details rd
            where rd.auction_date_id = :l_cur_date_id
            group by auction_date_id, rd.auction_id
          ) rd
          join dwh.client_order2auction ca
            on rd.auction_id = ca.auction_id
            and rd.auction_date_id > ca.create_date_id -- GTC, GTD, GTX filter: orders which were created prior auction date
        group by rd.auction_id