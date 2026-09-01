-- https://dashfinancial.atlassian.net/browse/DS-11872
drop foreign table staging.v_lifecycle_order;

IMPORT FOREIGN SCHEMA blaze7 LIMIT TO (v_lifecycle_order)
FROM SERVER blaze7_uat
into staging

drop table if exists genesis2.blaze_lifecycle_order;
create table if not exists genesis2.blaze_lifecycle_order
(
    parent_order_id          int8        not null
        constraint blaze_lifecycle_order_pk primary key,
    lifecycle_orderid        int8        null,
    lifecycle_orderid_status char(1)     not null,
    last_exec_id             varchar(30) not null,
    db_create_time           timestamp default clock_timestamp(),
    db_update_time           timestamp
);
create index blaze_lifecycle_order_last_exec_id_idx on genesis2.blaze_lifecycle_order (last_exec_id);

create or replace function genesis2.load_blaze_lifecycle_order(in_last_exec_id varchar(30) default null)
    returns int4
    language plpgsql
as
$fn$
    -- 20260806 SO https://dashfinancial.atlassian.net/browse/DS-11870
declare
    l_last_exec_id varchar(30);
    l_row_cnt      int4;
begin
    select coalesce(in_last_exec_id, max(last_exec_id), '')
    into l_last_exec_id
    from genesis2.blaze_lifecycle_order;

    insert into genesis2.blaze_lifecycle_order (parent_order_id, lifecycle_orderid, lifecycle_orderid_status,
                                                last_exec_id)
    select order_id, lifecycle_orderid, lifecycle_orderid_status, exec_id
    from staging.v_lifecycle_order vl
    where exec_id > l_last_exec_id
    on conflict (parent_order_id)
        do update set lifecycle_orderid        = excluded.lifecycle_orderid,
                      lifecycle_orderid_status = excluded.lifecycle_orderid_status,
                      last_exec_id             = excluded.last_exec_id,
                      db_update_time           = clock_timestamp()
    where blaze_lifecycle_order.lifecycle_orderid is distinct from excluded.lifecycle_orderid
       or blaze_lifecycle_order.lifecycle_orderid_status != excluded.lifecycle_orderid_status
       or blaze_lifecycle_order.last_exec_id != excluded.last_exec_id;
    get diagnostics l_row_cnt = row_count;
    return l_row_cnt;
end;
$fn$;


CREATE OR REPLACE FUNCTION dash360.report_sg_middle_offic_ooc_alloc_report(in_start_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                                           in_end_date_id integer DEFAULT (to_char((CURRENT_DATE)::timestamp with time zone, 'YYYYMMDD'::text))::integer,
                                                                           in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                                           in_account_ids integer[] DEFAULT '{}'::integer[])
    RETURNS TABLE
            (
                "ITEM"          bigint,
                "BUY/SELL"      text,
                "CONTRACTS"     integer,
                "SYMBOL"        character varying,
                "MONTH"         text,
                "STRIKE"        numeric,
                "PUT/CALL"      character,
                "AVG. PRICE"    numeric,
                "CONTRA PARTY"  character varying,
                "CUSTOMER"      character varying,
                "MARKET MAKER"  text,
                "TRAILER CODE"  text,
                "FROM (C/F/M)"  character,
                "TO (C/F/M)"    character,
                "FROM CLR NO"   text,
                "BUY/SELL FROM" text,
                date_id         integer
            )
    LANGUAGE plpgsql
AS
$function$
-- SO 20260827 https://dashfinancial.atlassian.net/browse/DS-11922
declare
    l_load_id     int;
    l_step_id     int;
    l_row_cnt     int4;
    l_msg_text    text;
    l_account_ids int8[];
begin
    l_msg_text := format('report_sg_middle_offic_ooc_alloc_report for %s-%s', in_start_date_id, in_end_date_id);

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' STARTED ====', 0, 'O')
    into l_step_id;

    select array_agg(account_id)
    into l_account_ids
    from genesis2.account
    where true
      and case
              when coalesce(in_trading_firm_ids, '{}') = '{}'::varchar[] and
                   coalesce(in_account_ids, '{}') = '{}'::integer[] then false
              when coalesce(in_trading_firm_ids, '{}') <> '{}'::varchar[]
                  then trading_firm_id = ANY (in_trading_firm_ids)
              else true end
      and case
              when coalesce(in_account_ids, '{}') <> '{}'::integer[] then account_id = ANY (in_account_ids)
              else true end;

    drop table if exists tmp_report;
    create temp table if not exists tmp_report as
    select --aie.allocation_instruction_entry_id         as "ITEM",
           concat_ws(' ', case when ai.side = '1' then 'BUY' when ai.side = any ('{"2", "5", "6"}') then 'SELL' end,
                     case when ai.open_close = 'O' then 'OPEN' when ai.open_close = 'C' then 'CLOSE' end)
                                                       as "BUY/SELL",
           aie.alloc_qty                               as "CONTRACTS",
           gi.symbol                                   as "SYMBOL",
           concat_ws('', to_char(OC.MATURITY_YEAR, 'FM0000'), to_char(OC.MATURITY_MONTH, 'FM00'),
                     to_char(OC.MATURITY_DAY, 'FM00')) as "MONTH",
           oc.strike_price                             as "STRIKE",
           oc.put_call                                 as "PUT/CALL",
           ai.avg_px                                   as "AVG. PRICE",
           ca.cmta                                     as "CONTRA PARTY",
           aie.occ_actionable_id                       as "CUSTOMER",
           --tr.sub_account as "MARKET MAKER"
           null                                        as "MARKET MAKER",
           'OC'                                        as "TRAILER CODE",
           tr.opt_customer_firm                        as "FROM (C/F/M)",
           tr.opt_customer_firm                        as "TO (C/F/M)",
           '286'                                       as "FROM CLR NO",
           concat_ws(' ', case when ai.side = '1' then 'SELL' when ai.side = any ('{"2", "5", "6"}') then 'BUY' end,
                     case when ai.open_close = 'C' then 'OPEN' when ai.open_close = 'O' then 'CLOSE' end)
                                                       as "BUY/SELL FROM",
           tr.date_id
    from genesis2.allocation_instruction ai
             join genesis2.allocation_instruction_entry aie using (alloc_instr_id, date_id)
             join genesis2.instrument gi on gi.instrument_id = ai.instrument_id
             join genesis2.option_contract oc on oc.instrument_id = ai.instrument_id
             join genesis2.clearing_account ca
                  on (aie.clearing_account_id = ca.clearing_account_id and ca.is_deleted = 'N')

             join lateral (select tr.*
                           from genesis2.alloc_instr2trade_record aitr
                                    join genesis2.trade_record tr
                                         on (tr.date_id = aitr.date_id
                                             and tr.trade_record_id = aitr.trade_record_id)
                           where aitr.alloc_instr_id = ai.alloc_instr_id
                             and aitr.date_id = ai.date_id
                           order by trade_record_time
                           limit 1) tr on true
    where ai.date_id between in_start_date_id and in_end_date_id
      and ai.account_id = any (l_account_ids)
      and ai.is_deleted = 'N';
    get diagnostics l_row_cnt = row_count;

    return query
        select row_number() over () as "ITEM", * from tmp_report;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' COMPLETED ====', l_row_cnt, 'C')
    into l_step_id;
end;
$function$
;

select * from genesis2.load_blaze_lifecycle_order('');
select * from genesis2.load_blaze_lifecycle_order();


select * from genesis2.blaze_lifecycle_order
WHERE parent_order_id = 647855791876882432 AND lifecycle_orderid = 647855791876882432


select order_id, lifecycle_orderid, lifecycle_orderid_status, exec_id
from staging.v_lifecycle_order vl;