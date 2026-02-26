-- GTC date_id
select coalesce(min(gtc.create_date_id), :l_date_begin_id)
--     into l_retention_date_id
from dwh.gtc_order_status gtc
where true
  and (gtc.close_date_id is null
    or gtc.close_date_id >= :l_date_end_id)
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else gtc.account_id = any (:in_account_ids) end
  and case
          when coalesce(:in_client_order_ids, '{}') = '{}' then true
          else gtc.client_order_id = any (:in_client_order_ids) end;

-- obo routes
create temp table t_route as
select *
from (values ('D', 'New Order', 1),
             ('D', 'Order Route', 2),
             ('G', 'Order Modify', 1),
             ('G', 'Order Modify Route', 2))
         as t(trans_type, order_type_value, rn)
where true
  and case when :in_include_routes = 'Y' then true else rn = 1 end;


-- parent orders
drop table if exists t_base;
create temp table t_base as
select cl.*
from dwh.client_order cl
         join dwh.d_account ac on ac.account_id = cl.account_id and ac.is_active
         join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
         left join dwh.d_fix_connection fc
                   on fc.fix_connection_id = cl.fix_connection_id and fc.is_active = true
where cl.parent_order_id is null
  and cl.create_date_id between :l_date_begin_id and :l_date_end_id
  and case
          when coalesce(:in_account_ids, '{}') = '{}' then true
          else cl.account_id = any (:in_account_ids) end
  and case
          when coalesce(:in_parent_order_ids, '{}') = '{}' then true
          else cl.order_id = any (:in_parent_order_ids) end
  and case when :in_instrument_type is null then true else di.instrument_type_id = :in_instrument_type end
  and case when :in_exclude_eos = 'N' then true else fc.is_high_frequency_trader = 'N' end
  and case when :in_fix_comp_ids = '{}' then true else coalesce(fc.fix_comp_id, '') = any (:in_fix_comp_ids) end
  and cl.trans_type <> 'F'
  and cl.trans_type in ('D', 'G')
  and cl.multileg_reporting_type in ('1', '2')
;
analyze t_base;

-- street orders
insert into t_base
select cl.*
from dwh.client_order cl
         join t_base par on cl.parent_order_id = cl.order_id
    and cl.create_date_id between :l_date_begin_id and :l_date_end_id
    and case
            when coalesce(:in_account_ids, '{}') = '{}' then true
            else cl.account_id = any (:in_account_ids) end
    and cl.parent_order_id is not null
    and cl.trans_type in ('D', 'G')
    and cl.multileg_reporting_type in ('1', '2');

-- parent cancels



-- strett cancels

