-- DROP FUNCTION staging.zabbix_monitor_ptm_missed_r(int4);

CREATE OR REPLACE FUNCTION staging.zabbix_monitor_ptm_missed_r(in_date_id integer DEFAULT get_dateid(CURRENT_DATE))
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
declare
l_cnt int4;
begin
    select count(*)
    into l_cnt
    from (select tr.is_billed, tr.trade_record_id, tr.orig_trade_record_id, tr.exec_id
                            from genesis2.trade_record tr
                                     join lateral (select null
                                                   from genesis2.trade_record tri
                                                   where tri.date_id = in_date_id
                                                     and tri.exec_id = tr.exec_id
                                                     and tri.is_billed = 'R'
                                                     and tri.trade_record_id < tr.trade_record_id
                                                   limit 1) tri on true
                            where tr.date_id = in_date_id
                              and tr.is_billed = 'N'
                              and tr.orig_trade_record_id is not null) x;
    if l_cnt > 0 then
        perform staging.fix_ptm_missed_r(in_date_id);
    end if;
    return l_cnt;
end;
$function$
;

COMMENT ON FUNCTION staging.zabbix_monitor_ptm_missed_r(int4) IS 'The script returns 1 if trade_records exist with missed status R, and zero otherwise';
select * from staging.zabbix_monitor_ptm_missed_r();


select * from dash360.get_user_login_stats_by_range