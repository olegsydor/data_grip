-- DROP FUNCTION dash360.orders_historical_orders_dmp_count(int4, int4, varchar, timestamp, timestamp, int4);

CREATE FUNCTION dash360.orders_historical_orders_dmp_count(in_status_date_id_from integer,
                                                           in_status_date_id_to integer,
                                                           in_user_filters character varying,
                                                           in_status_time_from timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                           in_status_time_to timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                           in_limit integer DEFAULT 100)
    RETURNS int4
    LANGUAGE plpgsql
AS
$function$

declare
    l_select_stmt     text;
    l_sql_params      text;
    l_algo_filter     text;
    l_row_count       int4;
    l_hods_algo_param text[] := ARRAY ['"OrderID"', '"AggressionLevel"', '"FeeSensitivity"','"HiddenFlag"', '"PreOpenBehavior"','"SweepStyle"','"DiscretionOffset"','"MaxVegaPerStrike"','"PerStrikeVegaExposure"','"VegaBehavior"','"DeltaBehavior"','"HedgeParamUnits"','"MinDelta"','"StepUpPrice"'];
begin


    FOR i IN 1 .. array_length(l_hods_algo_param, 1)
        LOOP
            in_user_filters := replace(in_user_filters, l_hods_algo_param[i], 'hods.' || l_hods_algo_param[i]);
        END LOOP;

    select ' '
               || case when in_user_filters is not null then in_user_filters else '' end
    into l_sql_params;

    l_select_stmt = '
		create temp table t_cnt on commit drop as
	              select null
        from
			dwh.historic_order_details_storage hods
			inner join dwh.d_account acc on hods."AccountID" = acc.account_id
			left join dwh.d_instrument i on i.instrument_id = hods."InstrumentID"
            left join dwh.historic_order_algo_parameters hoap on hods."OrderID"= hoap."OrderID" and hods."Status_Date_id"= hoap."Status_Date_id"
		where hods."Status_Date_id" between $1 and $2
				and case when num_nulls($3, $4) > 0 then true else "TransactTime" between $3 and $4 end
				and acc.is_active
		' || l_sql_params || '
		limit $5 ';

    execute l_select_stmt using in_status_date_id_from, in_status_date_id_to, in_status_time_from, in_status_time_to, in_limit;
    get diagnostics l_row_count = row_count;

    return l_row_count;

end;
$function$
;


select *
from dash360.orders_historical_orders_dmp_count(in_status_date_id_from := 20250504, in_status_date_id_to := 20250516,
                                                in_user_filters := 'and "OrderStatus" in (''2'',''4'',''C'',''8'',''3'') and "InstrumentType" = ''O'' and "PutCall" = ''0'' and "Side" = ''1'' and "OrderQty" >= 1 and "TimeInForce" in (''0'',''1'',''6'') and "MultilegReportingType" in (''1'',''2'')',
                                                in_limit := 50000);

select *
from dash360.orders_historical_orders_dmp_count(in_status_date_id_from := 20250516, in_status_date_id_to := 20250516,
                                                in_user_filters := 'and "OrderStatus" in (''2'',''4'',''C'',''8'',''3'') and "InstrumentType" = ''O'' and "PutCall" = ''0'' and "Side" = ''1'' and "OrderQty" >= 1 and "TimeInForce" in (''0'',''1'',''6'') and "MultilegReportingType" in (''1'',''2'')',
                                                in_limit := 5000000)


Parameters: "@in_status_date_id_from=20250504; @in_status_date_id_to=20250516; @in_user_filters= and \"OrderStatus\" in ('2','4','C','8','3') and \"InstrumentType\" = 'O' and \"PutCall\" = '0' and \"Side\" = '1' and \"OrderQty\" >= 1 and \"TimeInForce\" in ('0','1','6') and \"MultilegReportingType\" in ('1','2'); @in_limit=5001; "
             EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
select case when exists (select null from (
select row_number() over () as cnt
-- from dwh.historic_order_details_storage hods
                      from partitions.historic_order_details_storage_202505 hods
                               inner join dwh.d_account acc on hods."AccountID" = acc.account_id
                               left join dwh.d_instrument i on i.instrument_id = hods."InstrumentID"
                               left join dwh.historic_order_algo_parameters hoap
                                         on hods."OrderID" = hoap."OrderID" and
                                            hods."Status_Date_id" = hoap."Status_Date_id"
                      where hods."Status_Date_id" between :in_status_date_id_from and :in_status_date_id_to
                        and case
                                when num_nulls(:in_status_time_from, :in_status_time_to) > 0 then true
                                else "TransactTime" between :in_status_time_to and :in_status_time_to end
--   and acc.is_active
                        and "OrderStatus" in ('2', '4', 'C', '8', '3')
                        and "InstrumentType" = 'O'
                        and "PutCall" = '0'
                        and "Side" = '1'
                        and "OrderQty" >= 1
                        and "TimeInForce" in ('0', '1', '6')
                        and "MultilegReportingType" in ('1', '2')
--                       group by 1
                      limit 100000) x
where x.cnt = 100000) then true else false end;

