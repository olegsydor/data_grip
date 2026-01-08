-- DROP FUNCTION trash.so_equity_non_marketable_data(int4, int4, _int4);
select * from dwh.d_liquidity_indicator--.liquidity_indicator_type_id
where is_active
and liquidity_indicator_type_id = 2
CREATE OR REPLACE FUNCTION trash.so_equity_non_marketable_data_print(in_start_date_id integer, in_end_date_id integer, in_account_ids integer[],
in_row_type text default null, -- 'Parent', 'Child', or NULL
in_sub_strategy_id int4 default null,
in_exchange_id varchar(6)[] default '{}',
in_liq_ind_type_id int4 default null--: see d_liquidity_indicator.liquidity_indicator_type_id
)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    drop table if exists t_yc;

    create temp table t_yc as
    select *
    from data_marts.f_yield_capture yc

    where yc.status_date_id between in_start_date_id and in_end_date_id
      and yc.account_id = any (in_account_ids)
      and yc.multileg_reporting_type in ('1', '2')
      and yc.is_marketable = 'N'
      and yc.order_price >= 1
      and yc.parent_order_id is null
      and yc.instrument_type_id = 'E'
    and case when in_sub_strategy_id is null then true else yc.sub_strategy_id = in_sub_strategy_id end
    and case when in_exchange_id = '{}' then true else yc.exchange_id = any(in_exchange_id) end

    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' parent completed', l_row_cnt, 'O')
    into l_step_id;

    insert into t_yc
    select str.*
    from t_yc as par
             join data_marts.f_yield_capture str on (str.parent_order_id = par.order_id)
            inner join lateral (SELECT --e.exec_date_id, E.CUM_QTY, e.exec_time, e.order_status,
                                       e.trade_liquidity_indicator
                                 , row_number () over (partition by order_id order by exec_type = 'F' desc, exec_time desc, exec_id desc) as rn
                   			FROM EXECUTION E
                  			WHERE     E.ORDER_ID = str.ORDER_ID
                        		--  AND e.exec_date_id = str.create_date_id
                  			      and  e.exec_date_id = str.status_date_id -- SY: 20211216
                          		  AND E.ORDER_STATUS <> '3') ex on (ex.rn=1)
    --
     join dwh.d_exchange exc on exc.exchange_id = str.exchange_id and exc.is_active = true
       join dwh.d_liquidity_indicator lin on (lin.exchange_id = exc.real_exchange_id and lin.trade_liquidity_indicator = ex.trade_liquidity_indicator)
    join 
    where str.status_date_id between in_start_date_id and in_end_date_id
      and str.account_id = any (in_account_ids)
      and str.parent_order_id is not null
    and case when in_liq_ind_type_id is null then true else lin.tr;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' street completed', l_row_cnt, 'O')
    into l_step_id;

    create index on t_yc (status_date_id);

    drop table if exists trash.so_equity_non_marketable;
    create table trash.so_equity_non_marketable as
    select case when yc.parent_order_id is null then 'Parent' else 'Child' end as "Row Type",
           to_char(co.create_time, 'MM/DD/YYYY')                               as "Create Date",
           to_char(co.create_time, 'HH24:MI:SS.US')                            as "Create Time",
           to_char(yc.routed_time, 'HH24:MI:SS.US')                            as "Routed Time",
           to_char(yc.routed_time, 'MM/DD/YYYY')                               as "Event Date",
           to_char(yc.exec_time, 'HH24:MI:SS.US')                              as "Event Time",
           yc.parent_order_id                                                  as "Parent Order ID",
           yc.order_id                                                         as "Order ID",
           lst_ex.order_status_description                                     as "Order Status",
           case
               when hsd.instrument_type_id = 'E' then 'Equity'
               when hsd.instrument_type_id = 'O' then 'Option'
               end                                                             as "Sec Type",
           case
               when yc.side = '1' then 'Buy'
               when yc.side in ('2', '5', '6') then 'Sell'
               else ''
               end                                                             as "Side",
           hsd.display_instrument_id                                           as "Symbol",
           yc.order_qty                                                        as "Order Qty",
           yc.order_price                                                      as "Price",
           yc.day_cum_qty                                                      as "Ex Qty",
           round(yc.avg_px, 6)                                                 as "Avg Px",
           yc.day_leaves_qty                                                   as "Lvs Qty",
           ex.exchange_name                                                    as "Exchange Name",
           yc.nbbo_bid_price                                                   as "NBBO Bid Px",
           yc.nbbo_bid_quantity                                                as "NBBO Bid Qty",
           yc.nbbo_ask_price                                                   as "NBBO Ask Px",
           yc.nbbo_ask_quantity                                                as "NBBO Ask Qty"
    from t_yc as yc
             join dwh.client_order co
                  on (co.create_date_id between in_start_date_id and in_end_date_id and
                      co.create_date_id = yc.status_date_id and
                      co.order_id = yc.order_id)
             join dwh.historic_security_definition_all hsd
                  on (hsd.instrument_id = yc.instrument_id)
             left join dwh.d_exchange ex on (ex.exchange_unq_id = yc.exchange_unq_id)
             left join lateral
        (
        select os.order_status_description
        from dwh.execution ex
                 left join dwh.d_order_status os on (os.order_status = ex.order_status and os.is_active)
                 left join dwh.d_exec_type et on (et.exec_type = ex.exec_type)
        where ex.order_id = yc.order_id
          and ex.exec_date_id between in_start_date_id and in_end_date_id
          and ex.exec_date_id = yc.status_date_id
          and ex.order_status <> '3'
        order by ex.exec_id desc
        limit 1
        ) lst_ex on true
    where true;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'so_equity_non_marketable_data for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' report COMPLETED =======', l_row_cnt, 'O')
    into l_step_id;
    create index on trash.so_equity_non_marketable ("Order ID");
    return l_row_cnt;
end;
$function$
;
