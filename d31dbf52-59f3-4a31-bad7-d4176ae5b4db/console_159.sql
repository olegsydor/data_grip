-- DROP FUNCTION dash360.get_active_child_gtc_orders(_int4, int4, int4, _varchar);

CREATE OR REPLACE FUNCTION trash.get_active_child_gtc_orders(in_account_ids integer[] DEFAULT NULL::integer[],
                                                             in_start_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                             in_end_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                             in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                account_name     character varying,
                creation_date    timestamp without time zone,
                ord_status       character varying,
                sec_type         character,
                side             character,
                symbol           character varying,
                exchange_id      character varying,
                ex_dest          character varying,
                is_bdma          text,
                ord_qty          integer,
                ex_qty           numeric,
                ord_type         character,
                price            numeric,
                avg_px           numeric,
                lvs_qty          bigint,
                is_mleg          text,
                leg_id           character varying,
                open_close       character,
                dash_id          character varying,
                cl_ord_id        character varying,
                orig_cl_ord_id   character varying,
                parent_cl_ord_id character varying,
                occ_data         text,
                osi_symbol       character varying,
                client_id        character varying,
                subsystem        character varying,
                strike_px        numeric,
                put_call         character,
                exp_year         smallint,
                exp_month        smallint,
                exp_day          smallint,
                order_id         bigint,
                sender_comp_id   character varying
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2023-07-07 SO: https://dashfinancial.atlassian.net/browse/DS-6948 and https://dashfinancial.atlassian.net/browse/DS-6866
-- 2023-10-05 SO: https://dashfinancial.atlassian.net/browse/DS-7359 change client_id and ex_dest into human readable format
-- 2024-01-17 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-3910 added start_date_id and end_date_id
-- 2024-03-05 MB: https://dashfinancial.atlassian.net/browse/DS-7709 commented useless left join to d_client, we already use client_id_text from cl
-- 2024-05-09 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-4264 added in_trading_firm_ids
-- 2024-05-28 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-4264 added coalesce(trading_firm\account, '{})
-- 2026-01-29 SO: performance improvement

declare
    l_row_cnt         int4;
    l_load_id         int;
    l_step_id         int;
    l_is_current_date bool := false;
    l_account_ids     int4[];
    l_min_gtc_date_id int4;
begin
    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    if coalesce(in_account_ids, '{}') = '{}' and coalesce(in_trading_firm_ids, '{}') = '{}' then
        l_account_ids := '{}';
    else
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where true
          and case
                  when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                      then trading_firm_id = ANY (in_trading_firm_ids)
                  else true end
          and case
                  when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
                  else true end;
    end if;

    drop table if exists t_base;
    create temp table if not exists t_base as
    select ac.account_name,
           cl.create_time,
           ors.order_status_description,
           di.instrument_type_id,
           cl.side,
           di.symbol,
           exch.exchange_id,
           exch.exchange_name,
           exch.is_bdma,
           cl.order_qty,
           cl.order_type_id,
           cl.price,
           ex.avg_px,
           ex.leaves_qty,
           cl.multileg_reporting_type,
           cl.open_close,
           cl.dash_client_order_id,
           cl.client_order_id,
           par.client_order_id as par_client_order_id,
           cl.client_id_text,
           cl.order_id,
           gtc.create_date_id,
           cl.instrument_id,
           par.sub_system_unq_id,
           cl.fix_connection_id,
           cl.orig_order_id,
           cl.fix_message_id
    from dwh.gtc_order_status gtc
             join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id and
                                         cl.parent_order_id is not null
             join dwh.d_account ac on gtc.account_id = ac.account_id
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id and di.is_active
             inner join dwh.client_order par
                        on (cl.parent_order_id = par.order_id and par.create_date_id <= gtc.create_date_id)
             join lateral (select ex.exec_id as exec_id
                           from dwh.execution ex
                           where gtc.order_id = ex.order_id
                             and ex.order_status <> '3'
                             and ex.exec_date_id >= gtc.create_date_id
                           order by ex.exec_id desc
                           limit 1) gtex on true
             inner join lateral (select ex.avg_px, ex.last_px, ex.leaves_qty, ex.order_status
                                 from dwh.execution ex
                                 where ex.exec_id = gtex.exec_id
                                   and ex.exec_date_id >= gtc.create_date_id
                                 limit 1) ex on true
             join dwh.d_order_status ors on ors.order_status = ex.order_status
             inner join lateral (select exch.exchange_id,
                                        exch.exchange_name,
                                        case when exch.exchange_id like '%ML' then 'Y' else 'N' end as is_bdma
                                 from dwh.d_exchange exch
                                 where exch.exchange_id = cl.exchange_id
                                   and exch.is_active
                                 limit 1) exch on true
    where true
      and cl.parent_order_id is not null
      and gtc.create_date_id <= in_start_date_id
      and (gtc.close_date_id is null
        -- the code below has been added to provide the same performance in the case we use the report for CURRENT date
        or (case
                when l_is_current_date then false
                else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
      -- end of
      and cl.trans_type in ('D', 'G')
      and cl.time_in_force_id in ('1', '6')
      and cl.multileg_reporting_type in ('1', '2')
      and case when l_account_ids = '{}' then true else gtc.account_id = any (l_account_ids) end;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' the base table is calculated',
                           l_row_cnt, 'O')
    into l_step_id;


    select min(create_date_id)
    into l_min_gtc_date_id
    from t_base;

    drop table if exists t_final;
    create temp table t_final as
    select t_base.account_name             as account_name,
           t_base.create_time              as creation_date,
           t_base.order_status_description as ord_status,
           t_base.instrument_type_id       as sec_type,
           t_base.side                     as side,
           t_base.symbol                   as symbol,
           t_base.exchange_id              as exchange_id,
           t_base.exchange_name            as ex_dest,
           t_base.is_bdma                  as is_bdma,
           t_base.order_qty                as ord_qty,
           exl.ex_qty                      as ex_qty,
           t_base.order_type_id            as ord_type,
           t_base.price                    as price,
           t_base.avg_px                   as avg_px,
           t_base.leaves_qty               as lvs_qty,
           case
               when t_base.multileg_reporting_type = '1' then 'N'
               when t_base.multileg_reporting_type = '2'
                   then 'Y' end            as is_mleg,
           leg.client_leg_ref_id           as leg_id,
           t_base.open_close               as open_close,
           t_base.dash_client_order_id     as dash_id,
           t_base.client_order_id          as cl_ord_id,
           orig.client_order_id            as orig_cl_ord_id,
           t_base.par_client_order_id      as parent_cl_ord_id,
           fmj.t10441                      as occ_data,
           oc.opra_symbol                  as osi_symbol,
           t_base.client_id_text           as client_id,
           dss.sub_system_id               as subsystem,
           oc.strike_price                 as strike_px,
           oc.put_call                     as put_call,
           oc.maturity_year                as exp_year,
           oc.maturity_month               as exp_month,
           oc.maturity_day                 as exp_day,
           t_base.order_id                 as order_id,
           fc.fix_comp_id                  as sender_comp_id
    from t_base
             left join dwh.client_order orig
                       on (orig.order_id = t_base.orig_order_id and orig.create_date_id <= t_base.create_date_id)
             left join lateral (select sum(ex.last_qty) as ex_qty
                                from dwh.execution ex
                                where ex.exec_date_id >= t_base.create_date_id
                                  and ex.order_id = t_base.order_id
                                  and ex.exec_type in ('F', 'G')
                                  and ex.is_busted = 'N'
                                  and ex.exec_date_id >= l_min_gtc_date_id
                                limit 1) exl on true
             left join dwh.client_order_leg leg on (leg.order_id = t_base.order_id)
             left join lateral (select fix_message ->> '10441' as t10441
                                from fix_capture.fix_message_json fmj
                                where fmj.fix_message_id = t_base.fix_message_id
                                  and fmj.date_id = t_base.create_date_id
                                  and fmj.date_id >= l_min_gtc_date_id
                                limit 1) fmj on true
             left join dwh.d_option_contract oc on (oc.instrument_id = t_base.instrument_id and oc.is_active)
             left join dwh.d_sub_system dss on dss.sub_system_unq_id = t_base.sub_system_unq_id and dss.is_active
             left join dwh.d_fix_connection fc on (t_base.fix_connection_id = fc.fix_connection_id)
    --left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
    where true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' the final base table is calculated',
                           l_row_cnt, 'O')
    into l_step_id;
    create index on t_final (order_id);

    return query
        select *
        from t_final
        order by order_id;

    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;
drop table t_os;
create table t_os as
select 'new' as inst, * from trash.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129, in_trading_firm_ids := '{abnnv,aostb01,bmonblt}');

insert into t_os
select 'old', * from dash360.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129, in_trading_firm_ids := '{abnnv,aostb01,bmonblt}')



select *
from trash.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129,
                                       in_trading_firm_ids := '{hudson02,ingalls01,lightsp01}')
except
select *
from dash360.get_active_child_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129,
                                         in_trading_firm_ids :=  '{hudson02,ingalls01,lightsp01}')


select * from t_os
where order_id = 100000020091614011

select * from dwh.d_account where d_account.account_name = '5CG06139';

select trading_firm_id, count(*)
from dwh.gtc_order_status gtc
join dwh.d_account ac on ac.account_id = gtc.account_id
where close_date_id is null
group by trading_firm_id            ;

select account_name, creation_date, ord_status, sec_type, side, symbol, exchange_id, ex_dest, is_bdma, ord_qty,
 ex_qty, ord_type, price, avg_px, lvs_qty, is_mleg, leg_id, open_close, dash_id, cl_ord_id, orig_cl_ord_id,
 parent_cl_ord_id, occ_data, osi_symbol, client_id, subsystem, strike_px, put_call, exp_year, exp_month, exp_day,
 order_id, sender_comp_id
from t_os
where inst = 'old'
except
select account_name, creation_date, ord_status, sec_type, side, symbol, exchange_id, ex_dest, is_bdma, ord_qty,
 ex_qty, ord_type, price, avg_px, lvs_qty, is_mleg, leg_id, open_close, dash_id, cl_ord_id, orig_cl_ord_id,
 parent_cl_ord_id, occ_data, osi_symbol, client_id, subsystem, strike_px, put_call, exp_year, exp_month, exp_day,
 order_id, sender_comp_id
from t_os
where inst = 'new'

select * from dash360.get_active_parent_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129, in_trading_firm_ids := '{bnparibas,bnplon,caceisb01,cicmarch,clearprim}')
select * from dash360.get_active_parent_gtc_orders(in_start_date_id := 20260128, in_end_date_id := 20260129)

