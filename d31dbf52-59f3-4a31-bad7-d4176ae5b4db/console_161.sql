CREATE or replace FUNCTION dash360.report_gtc_impacted_active(in_start_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                              in_end_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer)
    RETURNS TABLE
            (
                "Account"        varchar(30),
                "Creation Date"  date,
                "Sec Type"       text,
                "Side"           text,
                "Ord Qty"        int4,
                "Symbol"         varchar(10),
                "Strike Px"      numeric(12, 4),
                "Put Call"       text,
                "Exp Date"       text,
                "Ex Dest"        varchar(256),
                "Ord Type"       varchar(255),
                "Price"          numeric(12, 4),
                "Ex Qty"         numeric,
                "Avg Px"         numeric,
                "Lvs Qty"        int8,
                "Is Mleg"        text,
                "Leg ID"         varchar(30),
                "Open/Close"     bpchar(1),
                "OSI Symbol"     varchar(30),
                "Cl Ord ID"      varchar(256),
                "Client ID"      varchar(255),
                "Sender Comp ID" varchar(30)
            )
    LANGUAGE plpgsql
AS
$function$
    -- 2026-02-06 SO: https://dashfinancial.atlassian.net/browse/DS-11064
declare
    row_cnt           int4;
    l_load_id         int;
    l_step_id         int;
    l_is_current_date bool := false;
    l_account_ids     int4[];
begin

    if in_start_date_id = in_end_date_id and in_start_date_id = to_char(current_date, 'YYYYMMDD')::int4 then
        l_is_current_date = true;
    end if;

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_gtc_impacted_active for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    drop table if exists t_gtc;
    create temp table if not exists t_gtc as
    select cl.order_id,
           ac.account_name                                                                  as "Account",
           cl.create_time::date                                                             as "Creation Date",
           case di.instrument_type_id when 'E' then 'Equity' when 'O' then 'Option' end     as "Sec Type",
           case cl.side
               when '1' then 'Buy'
               when '2' then 'Sell'
               when '5' then 'Sell Short'
               when '6' then 'Sell Short' end                                               as "Side",
           cl.order_qty                                                                     as "Ord Qty",
           di.symbol                                                                        as "Symbol",
           oc.strike_price                                                                  as "Strike Px",
           case oc.put_call when '1' then 'C' when '2' then 'P' end                         as "Put Call",
           to_char(to_date(lpad(oc.maturity_year::text, 4, '0') || lpad(oc.maturity_month::text, 2, '0') ||
                           lpad(oc.maturity_day::text, 2, '0'), 'YYYYMMDD'), 'DD Mon YYYY') as "Exp Date",
           dex.ex_destination_code_name                                                     as "Ex Dest",
           ot.order_type_name                                                               as "Ord Type",
           cl.price                                                                         as "Price",
           exl.ex_qty                                                                       as "Ex Qty",
           ex.avg_px                                                                        as "Avg Px",
           ex.leaves_qty                                                                    as "Lvs Qty",
           case
               when cl.multileg_reporting_type = '1' then 'N'
               when cl.multileg_reporting_type = '2'
                   then 'Y' end                                                             as "Is Mleg",
           cl.co_client_leg_ref_id                                                          as "Leg ID",
           cl.open_close                                                                    as "Open/Close",
           oc.opra_symbol                                                                   as "OSI Symbol",
           cl.client_order_id                                                               as "Cl Ord ID",
           cl.client_id_text                                                                as "Client ID",
           fc.fix_comp_id                                                                   as "Sender Comp ID"
    from dwh.gtc_order_status gtc
             join dwh.client_order cl on cl.order_id = gtc.order_id and cl.create_date_id = gtc.create_date_id
             join dwh.d_instrument di on di.instrument_id = cl.instrument_id
             inner join dwh.d_account ac on (cl.account_id = ac.account_id)
             join lateral (select ex.exec_id as exec_id,
                                  ex.avg_px,
                                  ex.leaves_qty,
                                  ex.order_status
                           from dwh.execution ex
                           where gtc.order_id = ex.order_id
                             and ex.order_status <> '3'
                             and ex.exec_date_id >= gtc.create_date_id
                             and ex.exec_date_id <= in_end_date_id
                           order by ex.exec_time desc
                           limit 1) ex on true
             inner join dwh.d_order_status ors on ors.order_status = ex.order_status
             left join lateral (select sum(ex.last_qty) as ex_qty
                                from dwh.execution ex
                                where ex.exec_date_id >= gtc.create_date_id
                                  and ex.exec_date_id <= in_end_date_id
                                  and ex.order_id = cl.order_id
                                  and ex.exec_type in ('F', 'G')
                                  and ex.is_busted = 'N'
                                limit 1) exl on true
             left join dwh.d_option_contract oc on oc.instrument_id = cl.instrument_id
             left join dwh.d_fix_connection fc on fc.fix_connection_id = cl.fix_connection_id
             left join dwh.d_ex_destination_code dex on dex.ex_destination_code = cl.ex_destination and dex.is_active
             left join dwh.d_order_type ot on ot.order_type_id = cl.order_type_id

    where cl.parent_order_id is null
      and gtc.create_date_id <= in_start_date_id
      and (gtc.close_date_id is null
        or (case
                when l_is_current_date then false
                else gtc.close_date_id is not null and close_date_id > in_end_date_id end))
      and cl.trans_type in ('D', 'G')
      and cl.time_in_force_id in ('1', '6')
      and cl.multileg_reporting_type in ('1', '2');

    select public.load_log(l_load_id, l_step_id,
                           'report_gtc_impacted_active for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' calculated',
                           row_cnt, 'O')
    into l_step_id;
    create index on t_gtc (order_id);

    select public.load_log(l_load_id, l_step_id,
                           'report_gtc_impacted_active for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' indexed',
                           row_cnt, 'O')
    into l_step_id;
    return query
        SELECT t_gtc."Account",
               t_gtc."Creation Date",
               t_gtc."Sec Type",
               t_gtc."Side",
               t_gtc."Ord Qty",
               t_gtc."Symbol",
               t_gtc."Strike Px",
               t_gtc."Put Call",
               t_gtc."Exp Date",
               t_gtc."Ex Dest",
               t_gtc."Ord Type",
               t_gtc."Price",
               t_gtc."Ex Qty",
               t_gtc."Avg Px",
               t_gtc."Lvs Qty",
               t_gtc."Is Mleg",
               t_gtc."Leg ID",
               t_gtc."Open/Close",
               t_gtc."OSI Symbol",
               t_gtc."Cl Ord ID",
               t_gtc."Client ID",
               t_gtc."Sender Comp ID"
        FROM t_gtc
        order by order_id;

    select public.load_log(l_load_id, l_step_id,
                           'report_gtc_impacted_active for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' COMPLETED ===== ',
                           row_cnt, 'O')
    into l_step_id;


end;
$function$
;

drop table t_os;
create table t_os as select * from dash360.report_gtc_impacted_active();

select string_agg(order_id::text, ',')
from (select order_id
      from t_gtc
      order by order_id
      offset 50000 limit 100) a;



select * from t_gtc
    where order_id in (100000025246467247,100000025246471898,100000025246476613)