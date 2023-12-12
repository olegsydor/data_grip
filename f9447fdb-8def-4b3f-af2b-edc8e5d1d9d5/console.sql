select * from genesis2.alert_param_value;

select * from genesis2.alert;


CREATE OR REPLACE FUNCTION staging.blob2text() RETURNS void AS $$
Declare
    ref record;
    i integer;
Begin
    FOR ref IN SELECT id, blob_field FROM table LOOP

          --  find 0x00 and replace with space
      i := position(E'\\000'::bytea in ref.blob_field);
      WHILE i > 0 LOOP
        ref.bob_field := set_byte(ref.blob_field, i-1, 20);
        i := position(E'\\000'::bytea in ref.blobl_field);
      END LOOP

    UPDATE table SET field = encode(ref.blob_field, 'escape') WHERE id = ref.id;
    END LOOP;

End; $$ LANGUAGE plpgsql;

insert into genesis2.alert (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
SELECT al."ALERT_ID",
       al."SUB_SYSTEM_ID",
       al."SEVERITY",
       al."ALERT_TEXT",
       al."ALERT_STATUS",
       al."CREATE_TIME",
       al."SEND_MAIL_RESULT",
       case
           when exists(select null
                       from staging.alert_param_value av
                       where av."ALERT_ID" = al."ALERT_ID"
                         and "GENERIC_PARAM_KEY" = 'RISK_ALERT'
                         and "GENERIC_PARAM_VALUE" = 'Y') then 'Y'
           else 'N' end as is_risk
select count(*)
FROM staging.ALERT al
;


insert into genesis2.alert_param_value (alert_id, generic_param_key, generic_param_value)
select "ALERT_ID", "GENERIC_PARAM_KEY", "GENERIC_PARAM_VALUE"
from staging.ALERT_PARAM_VALUE;


CREATE OR REPLACE FUNCTION genesis2.rt_perform_fill_allocation_trade_record()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
    -- 20221109 OS https://dashfinancial.atlassian.net/browse/DS-5453
    -- 20230926 OS https://dashfinancial.atlassian.net/browse/DS-7320 fixing of issue related to conflict manual and auto allocation
declare
    l_min_alloc_instr_id int8;
    l_max_alloc_instr_id int8;
    l_date_id             int4;
    l_load_id             int4;
    l_step_id             int4;
    l_max_time            timestamp;
    l_row_cnt             int4;
begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, 'perform_fill_allocation_trade_record started', 0, 'B')
    into l_step_id;

    select coalesce(min(alloc_instr_id), 0)
    into l_min_alloc_instr_id
    from genesis2.rt_allocation_trade_record;

    select clock_timestamp() - interval '1 minute' into l_max_time;

    select coalesce(min(alloc_instr_id), 0)
    into l_max_alloc_instr_id
    from genesis2.allocation_instruction tr
    where tr.alloc_instr_id < l_min_alloc_instr_id
      and tr.create_time < l_max_time;

    select to_char(current_date, 'YYYYMMDD')::int4 into l_date_id;

    raise notice 'l_min_alloc_instr_id - %, l_max_alloc_instr_id - %, l_max_time - %', l_min_alloc_instr_id, l_max_alloc_instr_id, l_max_time;
    insert into genesis2.rt_allocation_trade_record
    (trade_record_id, trade_record_time, date_id, exch_exec_id, client_order_id, exchange_id, last_mkt,
     secondary_exch_exec_id, clearing_account_number, cusip, symbol, symbol_suffix, account_name, nscc_mpid,
     eq_commission_type, eq_commission, eq_order_capacity, trading_firm_id, oats_account_type_code, alloc_instr_id,
     clearing_account_id, alloc_qty, side, create_time, avg_px, misc_fee_rate, eq_mpid, eq_report_to_mpid, eq_reporting_avgpx_precision)

    select ftr.trade_record_id,
           ai.create_time,
           ftr.date_id,
           ftr.exch_exec_id,
           null::varchar(256) as client_order_id,
           null::varchar(6) as exchange_id,
           ftr.last_mkt,
           ftr.secondary_exch_exec_id,
           ca.clearing_account_number,
           lcl.cusip,
           gi.symbol,
           gi.symbol_suffix,
           ac.account_name,
           ac.nscc_mpid,
           ac.eq_commission_type,
           ac.eq_commission,
           ac.eq_order_capacity,
           ac.trading_firm_id,
           ac.oats_account_type_code,
           ae.alloc_instr_id,
           ae.clearing_account_id,
           ae.alloc_qty,
           ai.side,
           ai.create_time,
           ai.avg_px,
           mf.misc_fee_rate,
           exch.eq_mpid,
           ac.eq_report_to_mpid,
           ac.eq_reporting_avgpx_precision
    from genesis2.allocation_instruction_entry ae
             join lateral (select atr.alloc_instr_id,
                                  ftr.trade_record_id,
                                  ftr.trade_record_time,
                                  ftr.date_id,
                                  ftr.exch_exec_id,
                                  ftr.client_order_id,
                                  ftr.exchange_id,
                                  ftr.last_mkt,
                                  ftr.secondary_exch_exec_id,
                                  ftr.account_id,
                                  ftr.instrument_id
                           from genesis2.alloc_instr2trade_record atr
                                    join genesis2.trade_record ftr
                                         on ftr.trade_record_id = atr.trade_record_id and ftr.date_id = atr.date_id
                           where atr.alloc_instr_id = ae.alloc_instr_id
                             and ftr.is_busted = 'N'
                           limit 1) ftr on true
             join genesis2.mv_active_account_snapshot ac on ac.account_id = ftr.account_id
                      and coalesce(eq_rt_allocation_enabled, 'N') = 'Y'
             join genesis2.allocation_instruction ai
                  on (ai.alloc_instr_id = ftr.alloc_instr_id and ai.is_deleted <> 'Y' and ai.date_id = ftr.date_id)
             join genesis2.instrument gi on (ftr.instrument_id = gi.instrument_id)
             join genesis2.clearing_account ca
                  on (ae.clearing_account_id = ca.clearing_account_id and ca.market_type = 'E' and
                      ca.is_deleted::text <> 'Y')

             left join staging.cusip_list_import lcl on (lcl.symbol::text = gi.symbol::text and
                                                         coalesce(lcl.symbol_suffix, 'none') =
                                                         coalesce(gi.symbol_suffix, 'none'))
             left join genesis2.misc_fee_mv mf on (mf.account_id = ac.account_id and
                                                   coalesce(to_char(mf.end_date, 'YYYYMMDD'::text)::integer,
                                                            ftr.date_id + 1) > ftr.date_id)
             left join genesis2.exchange exch on (ftr.exchange_id = exch.exchange_id and exch.is_deleted = 'N')
    where true
--       and ftr.is_busted = 'N'
      and ae.alloc_qty > 0
      and gi.instrument_type_id = 'E'
--      and ae.alloc_instr_id = 571782
--       and ftr.trade_record_id > l_min_trade_record_id
--       and ftr.trade_record_id <= l_max_trade_record_id
     and ae.alloc_instr_id < l_min_alloc_instr_id
     and ae.alloc_instr_id >= l_max_alloc_instr_id
--      and ftr.date_id = l_date_id
    ;

    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id, 'perform_fill_allocation_trade_record finished', l_row_cnt,
                           'E')
    into l_step_id;
    return l_row_cnt;
end;
$function$
;
select * from genesis2.ALERT2;

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32052984, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAF853520230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43435=849=BLITZ7256=RCS34=12890557=DFIN52=20230901-21:00:01.62311=B072AAAF85352023090176=1917=REJ-B072AAAF85352023090120=0150=839=8103=0167=MLEG38=12040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-21:00:01.52458=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001M5049=EXCHLBEN5050=20230901-21:00:01.5251105056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=236'JMSXGroupID:
'ba6041b6-97bf-4da7-a13c-5aafd4a10575'$full_text$, 'D', '2023-09-01 17:00:01.663'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32052988, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAF853720230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43335=849=BLITZ7256=RCS34=12890857=DFIN52=20230901-21:00:01.62411=B072AAAF85372023090176=1917=REJ-B072AAAF85372023090120=0150=839=8103=0167=MLEG38=5040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-21:00:01.52958=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001K5049=EXCHLBEN5050=20230901-21:00:01.5301375056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=205'JMSXGroupID:
'fb2e9198-c85d-41c0-8921-3a1166962a40'$full_text$, 'D', '2023-09-01 17:00:01.672'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32049664, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAB285320230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43335=849=BLITZ7256=RCS34=2689657=DFIN52=20230901-18:04:17.42611=B072AAAB28532023090176=1917=REJ-B072AAAB28532023090120=0150=839=8103=0167=MLEG38=12040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-18:04:17.40858=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001N5049=EXCHLBEN5050=20230901-18:04:17.4093345056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=242'JMSXGroupID:
'f9b3b9cd-35c5-447a-a57d-1def4813d4e2'$full_text$, 'D', '2023-09-01 14:04:17.532'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32049717, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAB287420230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43335=849=BLITZ7256=RCS34=2693257=DFIN52=20230901-18:04:17.94011=B072AAAB28742023090176=1917=REJ-B072AAAB28742023090120=0150=839=8103=0167=MLEG38=12040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-18:04:17.56358=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001N5049=EXCHLBEN5050=20230901-18:04:17.5643575056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=249'JMSXGroupID:
'f9b3b9cd-35c5-447a-a57d-1def4813d4e2'$full_text$, 'D', '2023-09-01 14:04:18.050'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32049148, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAB168920230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43235=849=BLITZ7256=RCS34=2454357=DFIN52=20230901-17:51:07.59011=B072AAAB16892023090176=1917=REJ-B072AAAB16892023090120=0150=839=8103=0167=MLEG38=5040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-17:51:07.49558=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001J5049=EXCHLBEN5050=20230901-17:51:07.4975285056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=210'JMSXGroupID:
'88c8f84b-afe3-4fb7-80cd-d7a9fa1616ae'$full_text$, 'D', '2023-09-01 13:51:07.639'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32049652, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAB284620230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43335=849=BLITZ7256=RCS34=2688457=DFIN52=20230901-18:04:17.42211=B072AAAB28462023090176=1917=REJ-B072AAAB28462023090120=0150=839=8103=0167=MLEG38=12040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-18:04:17.35658=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001N5049=EXCHLBEN5050=20230901-18:04:17.3574415056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=242'JMSXGroupID:
'f9b3b9cd-35c5-447a-a57d-1def4813d4e2'$full_text$, 'D', '2023-09-01 14:04:17.488'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32049689, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAB286020230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43335=849=BLITZ7256=RCS34=2690857=DFIN52=20230901-18:04:17.93111=B072AAAB28602023090176=1917=REJ-B072AAAB28602023090120=0150=839=8103=0167=MLEG38=12040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-18:04:17.46058=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001N5049=EXCHLBEN5050=20230901-18:04:17.4610895056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=236'JMSXGroupID:
'f9b3b9cd-35c5-447a-a57d-1def4813d4e2'$full_text$, 'D', '2023-09-01 14:04:17.959'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (32049705, 'SEG8_FIXDBS2', 'E', $full_text$Failed create entity from FIX message with error:
com.genesis.fixdbs.entity.exception.MapperException: class com.genesis.fixdbs.scripts.execution.ExecutionOrderMapper Unable to find order clientOrderId=B072AAAB286720230901, fixConnectionId=653, isHistoric=false for execution
Original FIX message:
'8=FIX.4.29=43335=849=BLITZ7256=RCS34=2692057=DFIN52=20230901-18:04:17.93611=B072AAAB28672023090176=1917=REJ-B072AAAB28672023090120=0150=839=8103=0167=MLEG38=12040=244=-2.550059=032=031=0.0151=014=06=0.060=20230901-18:04:17.51158=INVALID FIRM439=551442=3204=010100=MCRY10442=AN-BLITZC-001N5049=EXCHLBEN5050=20230901-18:04:17.5123505056=BLITZ725060=ANTEST9076=10001=ANVAR_TEST10012=MCRYF10030=MCRY10099=93510=234'JMSXGroupID:
'f9b3b9cd-35c5-447a-a57d-1def4813d4e2'$full_text$, 'D', '2023-09-01 14:04:18.004'::timestamp, 'There are no recipients for SubSystemId=SEG8_FIXDBS2, severity=E', 'N')

insert into genesis2.alert2 (alert_id, sub_system_id, severity, alert_text, alert_status, create_time, send_mail_result,
                            is_risk_alert)
values (1, 'a', 'b', 'text', case when :a = 'None' then null else :a end, clock_timestamp(), 'r', 'N')



insert into genesis2.alert (alert_id, sub_system_id, severity, alert_subject, alert_text, alert_status, create_time,
                            send_mail_result, is_risk_alert)
select alert_id,
       sub_system_id,
       severity,
       alert_subject,
       alert_text,
       alert_status,
       create_time,
       send_mail_result,
       is_risk_alert
from genesis2.alert2
where sub_system_id in ('SEG6_DBS1', 'SEG6_DBS3', 'SEG8_DBS3')
where sub_system_id not in (select distinct sub_system_id
                            from genesis2.alert2
                            where sub_system_id not in (select sub_system_id from genesis2.sub_system))


select distinct sub_system_id
from genesis2.alert2
where sub_system_id not in (select sub_system_id from genesis2.sub_system)

insert into genesis2.alert_param_value(alert_id, generic_param_key, generic_param_value)
select "ALERT_ID", "GENERIC_PARAM_KEY", "GENERIC_PARAM_VALUE"
from staging.alert_param_value
where "ALERT_ID" in (select alert_id from genesis2.alert where sub_system_id in ('SEG6_DBS1', 'SEG6_DBS3', 'SEG8_DBS3'))


create foreign table staging.alert_param_value
    (
        "ALERT_ID" numeric(13),
        "GENERIC_PARAM_KEY" varchar(10),
        "GENERIC_PARAM_VALUE" varchar(3999)
        )
    server oracle_prod
    options (schema 'GENESIS2_QA_20100601', table 'ALERT_PARAM_VALUE');


select count(1) from genesis2.alert_param_value
