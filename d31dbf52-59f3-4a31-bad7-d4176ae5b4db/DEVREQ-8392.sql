-- https://dashfinancial.atlassian.net/browse/DEVREQ-8392
select
    to_char(cl.create_time, 'dd-mm-yy') as date,
to_char(cl.create_time, 'yyyy-mm-dd"D"hh24:mi:ss.us'),
    *
 from dwh.client_order cl
             inner join dwh.d_account ac on ac.account_id = cl.account_id
             inner join dwh.d_instrument i on i.instrument_id = cl.instrument_id and i.is_active
             left join lateral (select po.sub_strategy_desc
                                from dwh.client_order po
                                where po.order_id = cl.parent_order_id
                                  and po.create_date_id <= cl.create_date_id
                                limit 1) po on true
             left join dwh.d_option_contract oc on oc.instrument_id = i.instrument_id and oc.is_active
             left join dwh.d_option_series os on os.option_series_id = oc.option_series_id and os.is_active
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id
             left join dwh.d_time_in_force tif on tif.tif_id = cl.time_in_force_id
             left join lateral (select *
                                from dwh.d_exchange exc
                                where exc.exchange_id = cl.exchange_id
                                  and exc.is_active
                                limit 1) exc on true
    where true
--       and case when l_account_ids = '{}' then true else cl.account_id = any (l_account_ids) end
      and cl.create_date_id between :in_start_date_id and :in_end_date_id
      and cl.trans_type <> 'F'
      and case when l_is_multileg then cl.parent_order_id is null else true end
      and case
              when l_is_multileg then cl.multileg_reporting_type in ('2', '3')
              else cl.multileg_reporting_type = '1' end
      and case when in_exclude_blaze then coalesce(cl.ex_destination, '') not ilike 'blaze' else true end
      and case when in_exclude_blaze then coalesce(cl.exchange_id, '') not ilike 'blaze' else true end;