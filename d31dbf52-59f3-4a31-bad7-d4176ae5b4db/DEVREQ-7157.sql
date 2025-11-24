-- DROP FUNCTION dash360.report_surveillance_socgen_parent_order_count(int4, int4, varchar);
select * from trash.report_surveillance_socgen_parent_order_count(20251001, 20251031);

select * from trash.report_surveillance_socgen_parent_order_count(20251120, 20251120, in_account_ids := '{56592,59790}');
drop function trash.report_surveillance_socgen_parent_order_count;

CREATE or replace FUNCTION trash.report_surveillance_socgen_parent_order_count(in_start_date_id integer DEFAULT get_dateid((date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))::date),
                                                                               in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                                               in_instrument_type character varying DEFAULT NULL::character varying,
                                                                               in_account_ids int4[] default '{}'::int4[])
    RETURNS TABLE
            (
                "row" text
            )
    LANGUAGE plpgsql
AS
$function$

declare
    row_cnt       int4;
    l_load_id     int;
    l_step_id     int;
    l_account_ids int4[];
    l_leg_count   int4 := 8;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen01_parent_order_count for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;
    select array_agg(account_id)
    into l_account_ids
    from dwh.d_account ac
    where true
      and case
              when in_account_ids = '{}' then trading_firm_id in ('socgenpsc', 'socgeneqd')
              else ac.account_id = any (in_account_ids) end;

    /*
    drop table if exists t_legs_exceed;
    create temp table t_legs_exceed as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           count(*)                            as count_legs
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between in_start_date_id and in_end_date_id
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (l_account_ids)
      and hods."MultilegReportingType" = '2'
    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name, hods."ClOrdID"
    having count(distinct hods."DisplayInstrumentID") > l_leg_count;

    drop table if exists t_ordinary;
    create temp table t_ordinary as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           sum(coalesce(hods."CumQty", 0))     as cum_qty,
           count(distinct hods."ClOrdID")      as cnt
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between in_start_date_id and in_end_date_id
      and case when in_instrument_type is null then true else hods."InstrumentType" = in_instrument_type end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any (l_account_ids)
    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name;

    return query
        select 'Period,Account,Capacity,Qty,Parent Order Count';

    return query
        select array_to_string(ARRAY [
                                   tor.status_date,
                                   tor.account_name,
                                   tor.customer_or_firm_name,
                                   tor.cum_qty::text,
                                   (tor.cnt + coalesce(tex.count_legs, 0))::text
                                   ], ',', '')
        from t_ordinary tor
                 left join lateral (select sum(count_legs - 1) as count_legs
                                    from t_legs_exceed tex
                                    where tex.status_date = tor.status_date
                                      and tex.account_name = tor.account_name
                                      and tex.customer_or_firm_name = tor.customer_or_firm_name
                                    group by tex.status_date, tex.account_name, tex.customer_or_firm_name
                                    limit 1) tex on true;
    */

    return query
        select 'Period,Account,Capacity,Qty,Parent Order Count';

    return query
    with cte as (select to_char("StatusDate", 'YYYY-MM-DD')             as status_date,
                        a.account_name,
                        hods."ClOrdID"                                  as client_order_id,
                        cf.customer_or_firm_name,
                        sum(coalesce(hods."CumQty", 0))                 as cum_qty,
                        1::int                                          as cnt,
                        count(distinct hods."DisplayInstrumentID")::int as cnt_leg
                 from dwh.historic_order_details_storage hods
                          join dwh.d_account a on a.account_id = hods."AccountID"
                          left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
                 where hods."Status_Date_id" between in_start_date_id and in_end_date_id
                   and case
                           when in_instrument_type is null then true
                           else hods."InstrumentType" = in_instrument_type end
                   and hods."CustomerOrderID" is null
                   and hods."AccountID" = any (l_account_ids)
                 group by status_date, account_name, client_order_id, customer_or_firm_name)
    select array_to_string(ARRAY [
                               c.status_date,
                               c.account_name,
                               c.customer_or_firm_name,
                               sum(c.cum_qty)::text,
                               (sum(case
                                        when c.cnt_leg > l_leg_count then c.cnt_leg
                                        else c.cnt
                                   end))::text
                               ], ',', '')
    from cte c
    group by c.status_date, c.account_name, c.customer_or_firm_name;
    get diagnostics row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen01_parent_order_count for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' FINISHED===',
                           row_cnt, 'O')
    into l_step_id;

end;
$function$
;

select * from t_legs_exceed;


with cte as (
	select
		to_char("StatusDate", 'YYYY-MM-DD') as status_date,
		a.account_name,
		hods."ClOrdID" as client_order_id,
		cf.customer_or_firm_name,
		sum(coalesce(hods."CumQty", 0))     as cum_qty,
		1::int as cnt,
		count(distinct hods."DisplayInstrumentID")::int as cnt_leg
	from dwh.historic_order_details_storage hods
	join dwh.d_account a on a.account_id = hods."AccountID"
	left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
	where hods."Status_Date_id" between 20251120 and 20251120
		and hods."CustomerOrderID" is null
		and a.account_name in ('IMC_BP', 'IMCCONTRA_BP')
	    and a.account_name = 'IMC_BP'
	group by status_date, account_name, client_order_id, customer_or_firm_name
)
select
	c.status_date,
	c.account_name,
	c.customer_or_firm_name,
	sum(c.cum_qty) as cum_qty,
	--sum(c.cnt) as cnt,
	--sum(c.cnt_leg) as cnt_leg,
	sum(case
			when c.cnt_leg > 8 then c.cnt_leg
			else c.cnt
	end) as expected_cnt
from cte c
group by c.status_date, c.account_name, c.customer_or_firm_name;

select array_agg(account_id)
           from dwh.d_account a
               where true
and a.account_name in ('IMC_BP', 'IMCCONTRA_BP') -- {56592,59790}


 drop table if exists t_legs_exceed;
    create temp table t_legs_exceed as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           count(*)                        as count_legs_minus
--     select a.account_name, *
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between 20251120 and 20251120
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any ('{56592,59790}')
      and hods."MultilegReportingType" = '2'

    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name, hods."ClOrdID"
    having count(distinct hods."DisplayInstrumentID") > 8;

select * from t_legs_exceed;
select * from t_ordinary

    drop table if exists t_ordinary;
    create temp table t_ordinary as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           sum(coalesce(hods."CumQty", 0))     as cum_qty,
           count(distinct hods."ClOrdID")      as cnt
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between 20251120 and 20251120
--       and case when in_instrument_type is null then true else hods."InstrumentType" = in_instrument_type end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any ('{56592,59790}')
    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name;


 drop table if exists t_legs_exceed;
    create temp table t_legs_exceed as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           count(*)                            as count_legs
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between 20251120 and 20251120
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any ('{56592,59790}')
      and hods."MultilegReportingType" = '2'
    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name, hods."ClOrdID"
    having count(distinct hods."DisplayInstrumentID") > 8;

    drop table if exists t_ordinary;
    create temp table t_ordinary as
    select to_char("StatusDate", 'YYYY-MM-DD') as status_date,
           a.account_name,
           cf.customer_or_firm_name,
           sum(coalesce(hods."CumQty", 0))     as cum_qty,
           count(distinct hods."ClOrdID")      as cnt
    from dwh.historic_order_details_storage hods
             join dwh.d_account a on a.account_id = hods."AccountID"
             left join dwh.d_customer_or_firm cf on (cf.customer_or_firm_id = hods."CustomerOrFirm")
    where hods."Status_Date_id" between 20251120 and 20251120
--       and case when in_instrument_type is null then true else hods."InstrumentType" = in_instrument_type end
      and hods."CustomerOrderID" is null
      and hods."AccountID" = any ('{56592,59790}')
    group by to_char("StatusDate", 'YYYY-MM-DD'), a.account_name, cf.customer_or_firm_name;

    return query
        select 'Period,Account,Capacity,Qty,Parent Order Count';

    return query
        select --array_to_string(ARRAY [
                                   tor.status_date,
                                   tor.account_name,
                                   tor.customer_or_firm_name,
                                   tor.cum_qty::text,
                                   (tor.cnt + coalesce(tex.count_legs, 0))::text
                                --   ], ',', '')
        from t_ordinary tor
                 left join lateral (select sum(count_legs -1) as count_legs
                                    from t_legs_exceed tex
                                    where tex.status_date = tor.status_date
                                      and tex.account_name = tor.account_name
                                      and tex.customer_or_firm_name = tor.customer_or_firm_name
                                    group by tex.status_date, tex.account_name, tex.customer_or_firm_name
                                    limit 1) tex on true;