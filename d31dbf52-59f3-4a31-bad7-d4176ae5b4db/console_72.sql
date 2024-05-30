alter table data_marts.f_parent_order add column check_sum text NULL;

-- DROP FUNCTION data_marts.load_parent_order_inc(_int8, int4, _int8);

CREATE OR REPLACE FUNCTION data_marts.load_parent_order_inc(in_parent_order_ids bigint[] DEFAULT NULL::bigint[], in_date_id integer DEFAULT NULL::integer, in_dataset_ids bigint[] DEFAULT NULL::bigint[])
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
    -- SO: 20240307 https://dashfinancial.atlassian.net/browse/DS-8065
    -- SO: 20240424 removed leaves_qty
    -- SO: 20240513 replaced get_dateid with get_gth_date_id_by_instrument_type
declare
    l_row_cnt int4;
    l_load_id int8;
    l_step_id int4;
    l_date_id int4 := coalesce(in_date_id, to_char(current_date, 'YYYYMMDD')::int4);

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' STARTED ===', 0, 'O')
    into l_step_id;

    -- the list of orders with permanent attributes
    drop table if exists t_base;
    create temp table t_base as
    select cl.parent_order_id,
           min(exec_id)                      as min_exec_id,
           max(exec_id)                      as max_exec_id,
           min(cl.parent_order_process_time) as parent_order_process_time,
           min(ex.order_create_date_id)      as order_create_date_id
    from dwh.execution ex
             join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
    where exec_date_id = l_date_id
      and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
      and case when in_parent_order_ids is null then true else cl.parent_order_id = any (in_parent_order_ids) end
      and not is_parent_level
--      and ex.is_busted <> 'Y'
      and ex.exec_type in ('F', '0', 'W')
      and cl.parent_order_id is not null
    group by cl.parent_order_id;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_base - %', l_row_cnt;

    analyze t_base;

    drop table if exists t_base_ext;
    create temp table t_base_ext as
    select base.parent_order_id,
           base.order_create_date_id,
           par.create_date_id      as create_date_id,
           base.min_exec_id        as min_exec_id,
           base.max_exec_id        as max_exec_id,
           par.time_in_force_id    as time_in_force_id,
           par.account_id          as account_id,
           par.instrument_id       as instrument_id,
           par.instrument_type_id  as instrument_type_id,
           par.trading_firm_unq_id as trading_firm_unq_id,
           par.order_qty           as parent_order_qty,
           par.side                as side
    --           ex.leaves_qty           as leaves_qty /* SY: we do not track cancels rejects etc. So we are not able to track leaves_qty correctly. Let's skip that field */
--            0                       as leaves_qty /* SO: aggree and confirmed with O.Semenchenko */
    from t_base base
             join lateral (select par.parent_order_id,
                                  par.create_date_id,
                                  par.time_in_force_id,
                                  par.account_id,
                                  par.instrument_id,
                                  di.instrument_type_id,
                                  par.trading_firm_unq_id,
                                  par.order_qty,
                                  par.side
                           from dwh.client_order par
                                    join dwh.d_instrument di on di.instrument_id = par.instrument_id and di.is_active
                           where par.order_id = base.parent_order_id
                             and par.parent_order_id is null
--                             and par.create_date_id = get_dateid(base.parent_order_process_time)
                             and par.create_date_id =
                                 public.get_gth_date_id_by_instrument_type(base.parent_order_process_time,
                                                                           di.instrument_type_id)
                           limit 1) par on true

    where true
      and par.parent_order_id is null;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_base_extended - %', l_row_cnt;
    analyze t_base_ext;

    -- new groupped by parent_order
    drop table if exists t_parent_orders;
    create temp table t_parent_orders as
    select bs.*,
           val.*,
           true as need_update
    from t_base_ext bs
             join lateral (select true as need_update limit 1) nup on true
             join lateral (select street_count, trade_count, last_qty, amount, street_order_qty
                           from data_marts.get_exec_for_parent_order(in_parent_order_id := bs.parent_order_id,
                                                                     in_date_id := l_date_id,
                                                                     in_min_exec_id := 0, --case when nup.need_update then 0 else bs.min_exec_id end,
                                                                     in_max_exec_id := bs.max_exec_id,
                                                                     in_order_create_date_id := bs.create_date_id
                                )
                           limit 1) val on true;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_street_orders create - %', l_row_cnt;
    create index on t_parent_orders (parent_order_id);

    insert into data_marts.f_parent_order (parent_order_id, last_exec_id, create_date_id, status_date_id,
                                           street_count, trade_count, last_qty, amount, street_order_qty,
                                           pg_db_create_time,
                                           order_qty,
                                           time_in_force_id, account_id, trading_firm_unq_id, instrument_id,
                                           instrument_type_id, side, check_sum)
    select tp.parent_order_id,
           tp.max_exec_id,
           tp.create_date_id,
           l_date_id,
           case when tp.need_update then tp.street_count else tp.street_count + coalesce(fp.street_count, 0) end,
           case when tp.need_update then tp.trade_count else tp.trade_count + coalesce(fp.trade_count, 0) end,
           case when tp.need_update then tp.last_qty else tp.last_qty + coalesce(fp.last_qty, 0) end,
           case when tp.need_update then tp.amount else tp.amount + coalesce(fp.amount, 0) end,
           case when tp.need_update then tp.street_order_qty else tp.amount + coalesce(fp.street_order_qty, 0) end,
           clock_timestamp(),
           --
           tp.parent_order_qty,
           tp.time_in_force_id,
           tp.account_id,
           tp.trading_firm_unq_id,
           tp.instrument_id,
           tp.instrument_type_id,
           tp.side,
           md5(row (l_date_id, tp.max_exec_id, tp.street_count, tp.create_date_id, tp.trade_count, tp.last_qty, tp.amount, tp.street_order_qty, tp.parent_order_qty, tp.instrument_id)::text) as check_sum
    from t_parent_orders tp
             left join data_marts.f_parent_order fp
                       on fp.parent_order_id = tp.parent_order_id and fp.status_date_id = l_date_id
    on conflict (status_date_id, parent_order_id)
    do update
        set last_exec_id      = excluded.last_exec_id,
            street_count      = excluded.street_count,
            trade_count       = excluded.trade_count,
            last_qty          = excluded.last_qty,
            amount            = excluded.amount,
            street_order_qty  = excluded.street_order_qty,
            pg_db_update_time = clock_timestamp(),
            instrument_id     = excluded.instrument_id,
            check_sum         = excluded.check_sum
        where data_marts.f_parent_order.check_sum is distinct from excluded.check_sum;

    get diagnostics l_row_cnt = row_count;
--     raise notice 't_parent_orders insert - %', l_row_cnt;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'load_parent_order_inc for ' || l_date_id::text || ' FINISHED ===', l_row_cnt, 'E')
    into l_step_id;

    return l_row_cnt;
end;
$function$
;



DROP FUNCTION dash360.risk_management_get_requests(timestamp, timestamp, text, int8, text, int8, text, int4, int4);

CREATE OR REPLACE FUNCTION dash360.risk_management_get_requests(in_from timestamp without time zone,
                                                                in_to timestamp without time zone,
                                                                in_scope text DEFAULT NULL::text,
                                                                in_acc_id bigint DEFAULT NULL::bigint,
                                                                in_tf_id text DEFAULT NULL::text,
                                                                in_tr_id bigint DEFAULT NULL::bigint,
                                                                in_status text DEFAULT NULL::text,
                                                                in_risk_acc_group_id bigint DEFAULT NULL::bigint,
                                                                in_risk_tf_group_id bigint DEFAULT NULL::bigint)
    RETURNS TABLE
            (
                req_id              bigint,
                status              character,
                scope               character,
                account_id          bigint,
                trading_firm_id     character varying,
                trader_id           bigint,
                change_type         character,
                change_reason       character,
                created_date        timestamp without time zone,
                created_by_user_id  bigint,
                rejected_date       timestamp without time zone,
                rejected_by_user_id bigint,
                approved_date       timestamp without time zone,
                approved_by_user_id bigint,
                created_by_user     character varying,
                approved_by_user    character varying,
                rejected_by_user    character varying,
                prm_id              bigint,
                prm_code            character varying,
                prm_value           character varying,
                prm_current_value   character varying,
                prm_type            character,
                risk_acc_group_id   bigint,
                risk_tf_group_id    bigint
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    # variable_conflict use_column
begin
    RETURN QUERY
        SELECT r.req_id,
               r.status,
               r."scope",
               r.account_id,
               r.trading_firm_id,
               r.trader_id,
               r.change_type,
               r.change_reason,
               r.created_date,
               r.created_by_user_id,
               r.rejected_date,
               r.rejected_by_user_id,
               r.approved_date,
               r.approved_by_user_id,
               cu.user_name created_by_user,
               au.user_name approved_by_user,
               ru.user_name rejected_by_user,
               re.prm_id,
               re.prm_code,
               re.prm_value,
               re.prm_current_value,
               re.prm_type,
               r.risk_account_group_id,
               r.risk_tf_group_id
        FROM dash360.risk_management_modification_requests r
                 join dash360.risk_management_modification_requests_entry re on re.req_id = r.req_id
                 join genesis2.user_identifier cu on r.created_by_user_id = cu.user_id
                 left join genesis2.user_identifier au on r.approved_by_user_id = au.user_id
                 left join genesis2.user_identifier ru on r.rejected_by_user_id = ru.user_id
        where (r.created_date between in_from and in_to)
          and (in_scope is null or r."scope" = in_scope::bpchar)
          and (in_acc_id is null or r.account_id = in_acc_id)
          and (in_tr_id is null or r.trader_id = in_tr_id)
          and (in_tf_id is null or r.trading_firm_id = in_tf_id::varchar)
          and (in_status is null or r.status = in_status::bpchar)
          and (in_risk_tf_group_id is null or r.risk_tf_group_id = in_risk_tf_group_id)
          and (in_risk_acc_group_id is null or r.risk_account_group_id = in_risk_acc_group_id);
end;
$function$
;