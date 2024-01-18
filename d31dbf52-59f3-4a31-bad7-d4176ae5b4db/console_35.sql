-- DROP FUNCTION dash360.get_active_child_gtc_orders(_int4);
drop function dash360.get_active_child_gtc_orders;
create or replace function dash360.get_active_child_gtc_orders(in_account_ids integer[] default null::integer[],
                                                               in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                               in_end_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4)
    returns table
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
    language plpgsql
as
$function$
-- 2023-07-07 SO: https://dashfinancial.atlassian.net/browse/DS-6948 and https://dashfinancial.atlassian.net/browse/DS-6866
-- 2023-10-05 SO: https://dashfinancial.atlassian.net/browse/DS-7359 change client_id and ex_dest into human readable format
-- 2024-01-17 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-3910 added start_date_id and end_date_id
declare
    row_cnt           int4;
    l_load_id         int;
    l_step_id         int;
    l_is_current_date bool := false;
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

    return query
        select ac.account_name              as account_name,
               cl.create_time               as creation_date,
               ors.order_status_description as ord_status,
               di.instrument_type_id        as sec_type,
               cl.side                      as side,
               di.symbol                    as symbol,
               exch.exchange_id             as exchange_id,
               exch.exchange_name           as ex_dest,
               exch.is_bdma                 as is_bdma,
               cl.order_qty                 as ord_qty,
               exl.ex_qty                   as ex_qty,
               cl.order_type_id             as ord_type,
               cl.price                     as price,
               ex.avg_px                    as avg_px,
               ex.leaves_qty                as lvs_qty,
               case
                   when cl.multileg_reporting_type = '1' then 'N'
                   when cl.multileg_reporting_type = '2'
                       then 'Y' end         as is_mleg,
               leg.client_leg_ref_id        as leg_id,
               cl.open_close                as open_close,
               cl.dash_client_order_id      as dash_id,
               cl.client_order_id           as cl_ord_id,
               orig.client_order_id         as orig_cl_ord_id,
               par.client_order_id          as parent_cl_ord_id,
               fmj.t10441                   as occ_data,
               oc.opra_symbol               as osi_symbol,
               cl.client_id_text            as client_id,
               dss.sub_system_id            as subsystem,
               oc.strike_price              as strike_px,
               oc.put_call                  as put_call,
               oc.maturity_year             as exp_year,
               oc.maturity_month            as exp_month,
               oc.maturity_day              as exp_day,
               cl.order_id                  as order_id,
               fc.fix_comp_id               as sender_comp_id
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
                 left join dwh.client_order orig
                           on (orig.order_id = cl.orig_order_id and orig.create_date_id <= cl.create_date_id)
                 left join lateral (select sum(ex.last_qty) as ex_qty
                                    from dwh.execution ex
                                    where ex.exec_date_id >= gtc.create_date_id
                                      and ex.order_id = cl.order_id
                                      and ex.exec_type in ('F', 'G')
                                      and ex.is_busted = 'N'
                                    limit 1) exl on true
                 left join dwh.client_order_leg leg on (leg.order_id = gtc.order_id)
                 left join lateral (select fix_message ->> '10441' as t10441
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = cl.fix_message_id
                                      and fmj.date_id = cl.create_date_id
                                    limit 1) fmj on true
                 left join dwh.d_option_contract oc on (oc.instrument_id = cl.instrument_id and oc.is_active)
                 left join dwh.d_sub_system dss on dss.sub_system_unq_id = par.sub_system_unq_id and dss.is_active
                 left join dwh.d_fix_connection fc on (cl.fix_connection_id = fc.fix_connection_id)
                 left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
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
          and case when coalesce(in_account_ids, '{}') = '{}' then true else gtc.account_id = any (in_account_ids) end
        order by gtc.order_id;

    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_child_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           row_cnt, 'O')
    into l_step_id;
end;
$function$
;
select *
from dash360.get_active_child_gtc_orders('{26586}', 20240102, 20240102);
select *
from dash360.get_active_child_gtc_orders('{26586}');



-- DROP FUNCTION dash360.get_active_parent_gtc_orders(_int4);

CREATE OR REPLACE FUNCTION dash360.get_active_parent_gtc_orders(in_account_ids integer[] DEFAULT NULL::integer[],
                                                                in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                                in_end_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4)
    RETURNS TABLE
            (
                account_name   character varying,
                creation_date  timestamp without time zone,
                ord_status     character varying,
                sec_type       character,
                side           character,
                symbol         character varying,
                ex_dest        character varying,
                ord_qty        integer,
                ex_qty         numeric,
                ord_type       character,
                price          numeric,
                avg_px         numeric,
                lvs_qty        bigint,
                is_mleg        text,
                leg_id         character varying,
                open_close     character,
                dash_id        character varying,
                cl_ord_id      character varying,
                orig_cl_ord_id character varying,
                occ_data       text,
                osi_symbol     character varying,
                client_id      character varying,
                subsystem      character varying,
                strike_px      numeric,
                put_call       character,
                exp_year       smallint,
                exp_month      smallint,
                exp_day        smallint,
                order_id       bigint,
                sender_comp_id character varying
            )
    LANGUAGE plpgsql
AS
$function$
-- 2023-07-07 SO: https://dashfinancial.atlassian.net/browse/DS-6948 and https://dashfinancial.atlassian.net/browse/DS-6866
-- 2023-10-05 SO: https://dashfinancial.atlassian.net/browse/DS-7359 change client_id and ex_dest into human readable format
-- 2024-01-17 SO: https://dashfinancial.atlassian.net/browse/DEVREQ-3910 added start_date_id and end_date_id
declare
    row_cnt       int4;
    l_load_id     int;
    l_step_id     int;
    l_is_current_date bool := false;
begin

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'get_active_parent_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    return query
        select ac.account_name              as account_name,
               cl.create_time               as creation_date,
               ors.order_status_description as ord_status,
               di.instrument_type_id        as sec_type,
               cl.side                      as side,
               di.symbol                    as symbol,
--                cl.ex_destination            as ex_dest,
               dex.ex_destination_code_name as ex_dest,
               cl.order_qty                 as ord_qty,
               exl.ex_qty,
               cl.order_type_id             as ord_type,
               cl.price                     as price,
               ex.avg_px                    as avg_px,
               ex.leaves_qty                as lvs_qty,
               case
                   when cl.multileg_reporting_type = '1' then 'N'
                   when cl.multileg_reporting_type = '2'
                       then 'Y' end         as is_mleg,
               leg.client_leg_ref_id        as leg_id,
               cl.open_close                as open_close,
               cl.dash_client_order_id      as dash_id,
               cl.client_order_id           as cl_ord_id,
               orig.client_order_id         as orig_cl_ord_id,
               fmj.t10441                   as occ_data,
               oc.opra_symbol               as osi_symbol,
--                dcl.client_id                as client_id,
               cl.client_id_text            as client_id,
               ss.sub_system_id             as subsystem,
               oc.strike_price              as strike_px,
               oc.put_call                  as put_call,
               oc.maturity_year             as exp_year,
               oc.maturity_month            as exp_month,
               oc.maturity_day              as exp_day,
               cl.order_id                  as order_id,
               fc.fix_comp_id               as sender_comp_id
        from dwh.gtc_order_status gtc
                 join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
                 join dwh.d_instrument di on di.instrument_id = cl.instrument_id
                 inner join dwh.d_account ac on (cl.account_id = ac.account_id)
                 left join dwh.client_order orig on (orig.order_id = cl.orig_order_id)
                 join lateral (select ex.exec_id as exec_id,
                                      ex.avg_px,
                                      ex.leaves_qty,
                                      ex.order_status
                               from dwh.execution ex
                               where gtc.order_id = ex.order_id
                                 and ex.order_status <> '3'
                                 and ex.exec_date_id >= gtc.create_date_id
                               order by ex.exec_time desc
                               limit 1) ex on true
                 inner join dwh.d_order_status ors on ors.order_status = ex.order_status
                 left join lateral (select sum(ex.last_qty) as ex_qty
                                    from dwh.execution ex
                                    where ex.exec_date_id >= gtc.create_date_id
                                      and ex.order_id = cl.order_id
                                      and ex.exec_type in ('F', 'G')
                                      and ex.is_busted = 'N'
                                    limit 1) exl on true
                 left join lateral (select fix_message ->> '10441' as t10441
                                    from fix_capture.fix_message_json fmj
                                    where fmj.fix_message_id = cl.fix_message_id
                                      and fmj.date_id = cl.create_date_id
                                    limit 1) fmj on true
                 left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
                 left join dwh.client_order_leg leg on leg.order_id = cl.order_id
                 left join dwh.d_sub_system ss on ss.sub_system_unq_id = cl.sub_system_unq_id
                 left join dwh.d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id
                 left join dwh.d_ex_destination_code dex on dex.ex_destination_code = cl.ex_destination and dex.is_acitive
                 left join dwh.d_client dcl on dcl.client_unq_id = cl.client_id
        where cl.parent_order_id is null
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
          and case when coalesce(in_account_ids, '{}') = '{}' then true else gtc.account_id = any (in_account_ids) end
    order by gtc.order_id;
    get diagnostics row_cnt = row_count;


    select public.load_log(l_load_id, l_step_id,
                           'get_active_parent_gtc_orders for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           row_cnt, 'O')
    into l_step_id;

   end;
$function$
;
select *
from dash360.get_active_parent_gtc_orders('{26586}', 20240102, 20240102);
select *
from dash360.get_active_parent_gtc_orders('{26586}');