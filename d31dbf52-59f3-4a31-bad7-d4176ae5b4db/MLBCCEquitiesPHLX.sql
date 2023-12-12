select * from dash360.report_rps_ml_bct221xd(20231110, 20231110)
create or replace function trash.report_get_mlbcc_equities_phlx(in_start_date_id int4, in_end_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$$
declare
    l_load_id int;
    l_step_id int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_get_mlbcc_equities_phlx for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' started====', 0, 'O')
    into l_step_id;

    create temp table t_tmp on commit drop as
    select ex.secondary_order_id                                   as str_order_id,
           ex.exec_id,
           ac.account_name,
           ac.eq_order_capacity,
           ac.trading_firm_id,
           cl.side,
           ex.exec_time                                            as exec_time,
           cl.create_time::date                                    as trade_date,
           ex.last_qty                                             as day_cum_qty,
           ex.last_px                                              as day_avg_px,
           coalesce(i.symbol, '') || coalesce(i.symbol_suffix, '') as symbol_name,
           i.symbol_suffix,
           fmj.t9076                                               as t9076,
           ac.client_dtc_number
    from (select order_id, create_date_id
          from dwh.client_order
          where create_date_id between in_start_date_id and in_end_date_id
          union all
          select order_id, create_date_id
          from dwh.gtc_order_status
          where create_date_id < in_start_date_id
            and close_date_id is null
          union all
          select order_id, create_date_id
          from dwh.gtc_order_status
          where create_date_id < in_start_date_id
            and close_date_id is not null
            and close_date_id > in_start_date_id) cl_transf
             join dwh.client_order cl
                  on cl.order_id = cl_transf.order_id and cl.create_date_id = cl_transf.create_date_id
             inner join dwh.mv_active_account_snapshot ac on (ac.account_id = cl.account_id)
             inner join dwh.execution ex
                        on (ex.order_id = cl.order_id and ex.exec_type in ('F', 'G') and
                            exec_date_id between in_start_date_id and in_end_date_id)
             inner join dwh.d_instrument i on (i.instrument_id = cl.instrument_id and
                                               i.symbol not in (select test_symbol from fintech_dwh.test_symbol_tb))
             left join lateral (select fix_message ->> '9076' as t9076
                                from fix_capture.fix_message_json fmj
                                where fmj.date_id = cl.create_date_id
                                  and fmj.fix_message_id = cl.fix_message_id
                                limit 1) fmj on true
    where cl.parent_order_id is null
      and ex.is_busted = 'N'
      and coalesce(ac.eq_report_to_mpid, 'NONE') = 'NONE'
      and coalesce(ac.eq_real_time_report_to_mpid, 'NONE') = 'NONE'
      and ac.trading_firm_id <> 'baml'
      and i.instrument_type_id = 'E'
      and ex.exchange_id = 'PHLX';

    select public.load_log(l_load_id, l_step_id,
                           'report_get_mlbcc_equities_phlx. Temp table created ', 0, 'O')
    into l_step_id;

    create temp table t_out on commit drop as
    select 1     as ORD_FLAG_1,
           'A0'  as ORD_FLAG_2,
           'HDR' as REC_TYPE,
           'BCT221XD' ||--1-8
           '  ' ||--9-10
           'ENTRY DATE: ' ||--11-22
           to_char(clock_timestamp(), 'YYYYMMDD') ||--23-30
           ' ' ||--31-31
           to_char(clock_timestamp(), 'HH24MI') ||--32-35
           rpad(' ', 14) ||--36-49
           'E' ||--50 File type
           '  1'--File seq nbr 51-53
                 as REC;

    insert into t_out (ORD_FLAG_1, ORD_FLAG_2, REC_TYPE, REC)
    select 5     as ORD_FLAG_1,
           'Z0'  as ORD_FLAG_2,
           'TRL' as REC_TYPE,
           '99999999' ||--1-8
           ' ' ||
           'RECORD COUNT: '--10-23
                 as REC;

    insert into t_out (ord_flag_1, ord_flag_2, rec_type, rec)
    select 2                      as ord_flag_1,
           'A' || t.exec_id::text as ord_flag_2,
           'TRADE'                as rec_type,
           --#1
           '3Q800797' ||--Avg Px

           'S' ||--SEC_ID_TYPE -9
           rpad(coalesce(t.symbol_name, ''), 22, ' ') ||--10-31
           '  ' ||--32-33
           '4' ||--34 Price code type
           to_char(round(t.day_avg_px, 6), 'FM09999V999999') ||--35-45

           lpad(t.day_cum_qty::text, 9, '0') ||--46-54 Qty
           case
               when t.symbol_suffix = 'WI' then '00000000'
               else to_char(public.get_business_date(t.trade_date, 2), 'YYYYMMDD')
               end ||--55-62 Settle Date
           to_char(t.trade_date, 'YYYYMMDD') ||--63-70 Trade Date
           case
               when t.side = '1' then '1'
               when t.side in ('2', '5', '6') then '2'
               else '1'
               end ||
           case
               when t.SIDE in ('5', '6') then '1'
               else ' '
               end ||--SHORT IND -72
           rpad(' ', 5) ||--73-77
           '68' ||--78-79
           rpad(' ', 10) ||--filler 80-89
           '0' ||--Trade Action --90
           '2' ||--Commission Type 91
           '000000000' ||--Commission Amount 92-100
           '0520PHLY' ||--Opposing Account 101-108
           '0' ||--109: no data in pos 214-333
           '   ' ||--110, 111, 112
           '2' ||--113
           rpad(' ', 17) ||--114-122;123-126;127-130;
           case
               when t.symbol_suffix = 'WI' then '1'
               else ' '
               end ||--131;
           '   ' ||--132;133-134 (exch 1)
           '   ' ||--135;136-137 (exch 2)
           '   ' ||--138;139-140 (exch 3)
           ' ' ||--141
           rpad(' ', 6) ||--142-147 alt sec num
           t.eq_order_capacity ||--148
           'A' ||--149
           rpad(' ', 189) ||--150-338
           '   ' ||--339-341 CC<1..4>
           ' ' || --342
           case
               when t.account_name in ('dashtest', 'dasherror') then 'C'
               else 'A'
               end ||--343
           rpad(' ', 9) ||--344;345-352;
           to_char(t.exec_time, 'HH24MISS') ||--353-358
           rpad(' ', 161) ||--359-519
           ' ' ||--SECT-31-FEE 520
           'Y' ||--521 TBD
           rpad(' ', 197) ||--522-718
           ' ' ||--719
           rpad(' ', 20) ||--720-739
           rpad(' ', 66) ||--740-805
           lpad('A' || t.exec_id::text, 20, '0') --806-825
                                  as REC
    from t_tmp t;

    insert into t_out (ord_flag_1, ord_flag_2, rec_type, rec)
    select 3                      as ord_flag_1,
           'b' || t.exec_id::text as ord_flag_2,
           'TRADE'                as rec_type,
           --#1
           '3Q800806' ||--Clearing Acc

           'S' ||--SEC_ID_TYPE -9
           rpad(coalesce(t.symbol_name, ''), 22, ' ') ||--10-31
           '  ' ||--32-33
           '4' ||--34 Price code type
           to_char(round(t.day_avg_px, 6), 'FM09999V999999') ||--35-45

           lpad(t.day_cum_qty::text, 9, '0') ||--46-54 Qty
           case
               when t.symbol_suffix = 'WI' then '00000000'
               else to_char(public.get_business_date(t.trade_date, 2), 'YYYYMMDD')
               end ||--55-62 Settle Date
           to_char(t.trade_date, 'YYYYMMDD') ||--63-70 Trade Date
           case
               when t.side = '1' then '1'
               when t.side in ('2', '5', '6') then '2'
               else '1'
               end ||
           case
               when t.side in ('5', '6') then '1'
               else ' '
               end ||--SHORT IND -72
           rpad(' ', 5) ||--73-77
           '88' ||--78-79
           rpad(' ', 10) ||--filler 80-89
           '0' ||--Trade Action --90
           '2' ||--Commission Type 91
           '000000000' ||--Commission Amount 92-100
           '3Q800797' ||--Opposing Account 101-108
           '0' ||--109: no data in pos 214-333
           '   ' ||--110, 111, 112
           '2' ||--113
           rpad(' ', 17) ||--114-122;123-126;127-130;
           case
               when t.symbol_suffix = 'WI' then '1'
               else ' '
               end ||--131;
           '100' ||--132;133-134 (exch 1)
           '   ' ||--135;136-137 (exch 2)
           '   ' ||--138;139-140 (exch 3)
           ' ' ||--141
           rpad(' ', 6) ||--142-147 alt sec num
           coalesce(t.eq_order_capacity, '') ||--148
           'A' ||--149
           rpad(' ', 189) ||--150-338
           '   ' ||--339-341 CC<1..4>
           ' ' || --342
           case
               when t.account_name in ('dashtest', 'dasherror') then 'C'
               else 'A'
               end ||--343
           rpad(' ', 9) ||--344;345-352;
           to_char(t.exec_time, 'HH24MISS') ||--353-358
           rpad(' ', 161) ||--359-519
           ' ' ||--SECT-31-FEE 520
           'Y' ||--521 TBD
           rpad(' ', 197) ||--522-718
           ' ' ||--719
           rpad(' ', 20) ||--720-739
           rpad(' ', 66) ||--740-805
           lpad('B' || t.exec_id::text, 20, '0') --806-825
                                  as rec
    from t_tmp t;


    --M8, drop
    insert into t_out (ord_flag_1, ord_flag_2, rec_type, rec)
    select 4                      as ord_flag_1,
           'c' || t.exec_id::text as ord_flag_2,
           'TRADE'                as rec_type,
           --#1
           '3Q800806' ||--Avg Px

           'S' ||--SEC_ID_TYPE -9
           rpad(coalesce(t.symbol_name, ''), 22, ' ') ||--10-31
           '  ' ||--32-33
           '4' ||--34 Price code type
           to_char(round(t.day_avg_px, 6), 'FM09999V999999') ||--35-45

           lpad(coalesce(t.day_cum_qty::text, ''), 9, '0') ||--46-54 Qty
           case
               when T.SYMBOL_SUFFIX = 'WI' then '00000000'
               else to_char(public.get_business_date(t.trade_date, 2), 'YYYYMMDD')
               end ||--55-62 Settle Date
           to_char(t.trade_date, 'YYYYMMDD') ||--63-70 Trade Date
           case
               when t.side = '1' then '2'
               when t.side in ('2', '5', '6') then '1'
               else '2'
               end ||
           ' ' ||--SHORT IND -72
           rpad(' ', 5) ||--73-77
           case t.trading_firm_id when 'cornerstn' then '98' else 'M8' end ||--78-79
           rpad(' ', 10) ||--filler 80-89
           '0' ||--Trade Action --90
           '2' ||--Commission Type 91
           '000000000' ||--Commission Amount 92-100
           coalesce(t.client_dtc_number, '0000') || coalesce(t.t9076, 'NONE') ||--Opposing Account 101-108
           '0' ||--109: no data in pos 214-333
           '   ' ||--110, 111, 112
           '2' ||--113
           rpad(' ', 17) ||--114-122;123-126;127-130;
           case
               when t.symbol_suffix = 'WI' then '1'
               else ' '
               end ||--131;
           '   ' ||--132;133-134 (exch 1)
           '   ' ||--135;136-137 (exch 2)
           '   ' ||--138;139-140 (exch 3)
           ' ' ||--141
           rpad(' ', 6) ||--142-147 alt sec num
           coalesce(t.eq_order_capacity, '') ||--148
           'A' ||--149
           rpad(' ', 189) ||--150-338
           '   ' ||--339-341 CC<1..4>
           ' ' || --342
           'A' ||--343
           rpad(' ', 9) ||--344;345-352;
           to_char(t.exec_time, 'HH24MISS') ||--353-358
           rpad(' ', 161) ||--359-519
           ' ' ||--SECT-31-FEE 520
           'Y' ||--521 TBD
           rpad(' ', 197) ||--522-718
           ' ' ||--719
           rpad(' ', 20) ||--720-739
           rpad(' ', 66) ||--740-805
           lpad('c' || t.exec_id::text, 20, '0') --806-825

                                  as rec
    from t_tmp t;


    return query
        select rpad(
                       case
                           when rec_type = 'TRL' then rec || lpad((select count(*) - 2 from t_out)::text, 10, '0')
                           else rec
                           end, 1000, ' ')
        from (select row_number() over () as rec_num, rec, rec_type
              from t_out
              order by ord_flag_1, ord_flag_2) x;

    select public.load_log(l_load_id, l_step_id,
                           'report_get_mlbcc_equities_phlx for ' || in_start_date_id::text || '-' ||
                           in_end_date_id::text || ' finished====', 0, 'O')
    into l_step_id;
end;
$$;

select to_char(round(123.45678,6), 'FM09999V999999')