-- accounts
select distinct tr.account_id, ac.trading_firm_id
from genesis2.trade_record tr
         join genesis2.instrument di on di.instrument_id = tr.instrument_id
         join genesis2.account ac on tr.account_id = ac.account_id
where tr.date_id = :in_date_id
  and di.instrument_type_id = 'O';


select * from trash.so_allocation_trade_record_monitor(20241217);

select * from tmp_trade_record_monitor;
create or replace function trash.so_allocation_trade_record_monitor(in_date_id int4, in_account_ids int8[] default '{}'::int8[])
    returns table
            (
                account_id                      int8,
                trading_firm_id                 varchar(9),
                trades_cnt                      int8,
                trades_qty                      int8,
                trades_principal                numeric,
                trades_qty_expiring             int8,
                unallocated_trades_cnt          int8,
                unallocated_trades_qty          int8,
                unallocated_trades_principal    numeric,
                unallocated_trades_qty_expiring int8,
                allocated_trades_cnt            int8,
                allocated_trades_qty            int8,
                allocated_trades_principal      numeric,
                allocated_trades_qty_expiring   int8,
                unable_trades_cnt               int8,
                unable_trades_qty               int8,
                unable_trades_principal         numeric
            )
    language plpgsql
as
$fn$
declare

begin

    drop table if exists tmp_trade_record_monitor;
    create temp table tmp_trade_record_monitor as
    select ac.account_id,
           ac.trading_firm_id,
           tr.trade_record_id,
           tr.last_qty,
           tr.last_Px,
           case
               when to_char(di.last_trade_date, 'YYYYMMDD')::int4 = in_date_id then true
               else false end         as expiring_today,
           case
               when al.alloc_instr_id is not null then 'allocated'
               else 'unallocated' end as is_alloc,
           case
               when un.alloc_instr_id is not null then true
               end                    as is_unable
    from genesis2.trade_record tr
             join genesis2.instrument di on di.instrument_id = tr.instrument_id
             join genesis2.account ac on tr.account_id = ac.account_id
             left join genesis2.alloc_instr2trade_record atr
                       on atr.trade_record_id = tr.trade_record_id and atr.date_id = in_date_id
             left join lateral (select atr.alloc_instr_id
                                from genesis2.allocation_instruction ai
                                where ai.alloc_instr_id = atr.alloc_instr_id
                                  and ai.is_deleted = 'N'
                                limit 1) al on true
             left join lateral ( select bar.alloc_instr_id
                                 from dash360.bofa_allocation_report bar
                                 where bar.alloc_instr_id = atr.alloc_instr_id
                                   and bar.date_id = atr.date_id
                                   and bar.to_report <> 'report'
                                 limit 1) un on true
    where true
      and tr.is_busted <> 'Y'
      and tr.date_id = in_date_id
      and di.instrument_type_id = 'O'
      and case when in_account_ids = '{}' then true else ac.account_id = any (in_account_ids) end;


    return query
        select trm.account_id,
               trm.trading_firm_id,
               --
               count(trm.trade_record_id)                                                       as trades_cnt,
               sum(trm.last_qty)                                                                as trades_qty,
               sum(trm.last_qty + trm.last_px)                                                  as trades_principal,
               sum(case when trm.expiring_today then 1 else 0 end)                              as trades_qty_expiring,
               -- unallocated
               sum(case when trm.is_alloc = 'unallocated' then 1 else 0 end)                    as unallocated_trades_cnt,
               sum(case when trm.is_alloc = 'unallocated' then last_qty else 0 end)             as unallocated_trades_qty,
               sum(case when trm.is_alloc = 'unallocated' then last_qty + last_px else 0 end)   as unallocated_trades_principal,
               sum(case when trm.is_alloc = 'unallocated' and expiring_today then 1 else 0 end) as unallocated_trades_qty_expiring,
               -- allocated
               sum(case when trm.is_alloc = 'allocated' then 1 else 0 end)                      as allocated_trades_cnt,
               sum(case when trm.is_alloc = 'allocated' then last_qty else 0 end)               as allocated_trades_qty,
               sum(case when trm.is_alloc = 'allocated' then last_qty + last_px else 0 end)     as allocated_trades_principal,
               sum(case when trm.is_alloc = 'allocated' and expiring_today then 1 else 0 end)   as allocated_trades_qty_expiring,
               -- unable
               sum(case when trm.is_unable then 1 else 0 end)                                   as unable_trades_cnt,
               sum(case when trm.is_unable then last_qty else 0 end)                            as unable_trades_qty,
               sum(case when trm.is_unable then last_qty + last_px else 0 end)                  as unable_trades_principal
-- select *
        from tmp_trade_record_monitor trm
        group by trm.account_id, trm.trading_firm_id;
end;
$fn$;

create table trash.so_delete as
select account_id,
       trading_firm_id,
       --
       count(trade_record_id)                                                       as trades_cnt,
       sum(last_qty)                                                                as trades_qty,
       sum(last_qty + last_px)                                                      as trades_principal,
       sum(case when expiring_today then 1 else 0 end)                              as trades_qty_expiring,
       -- unallocated
       sum(case when is_alloc = 'unallocated' then 1 else 0 end)                    as unallocated_trades_cnt,
       sum(case when is_alloc = 'unallocated' then last_qty else 0 end)             as unallocated_trades_qty,
       sum(case when is_alloc = 'unallocated' then last_qty + last_px else 0 end)   as unallocated_trades_principal,
       sum(case when is_alloc = 'unallocated' and expiring_today then 1 else 0 end) as unallocated_trades_qty_expiring,
       -- allocated
       sum(case when is_alloc = 'allocated' then 1 else 0 end)                      as allocated_trades_cnt,
       sum(case when is_alloc = 'allocated' then last_qty else 0 end)               as allocated_trades_qty,
       sum(case when is_alloc = 'allocated' then last_qty + last_px else 0 end)     as allocated_trades_principal,
       sum(case when is_alloc = 'allocated' and expiring_today then 1 else 0 end)   as allocated_trades_qty_expiring,
       -- unable
       sum(case when is_unable then 1 else 0 end)                                   as unable_trades_cnt,
       sum(case when is_unable then last_qty else 0 end)                            as unable_trades_qty,
       sum(case when is_unable then last_qty + last_px else 0 end)                  as unable_trades_principal
-- select *
from t_trade_record_monitor
group by account_id, trading_firm_id



-- compare 1 PROD
-- DROP FUNCTION dash360.clearing_instruction_create(int4, bpchar, int4, bpchar, varchar);

CREATE OR REPLACE FUNCTION dash360.clearing_instruction_create(in_date_id integer, in_clearing_status character,
                                                               in_user_id integer, in_modification_type character,
                                                               in_json_values character varying)
    RETURNS TABLE
            (
                trade_json    character varying[],
                clearing_json character varying[]
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- AK 20231129 : https://dashfinancial.atlassian.net/browse/D360-12491 added cboe_reason_code field to insert into genesis2.clearing_instruction_entry
-- PD 20240530 : https://dashfinancial.atlassian.net/browse/DS-8362 added box_additional_client_memo field to insert statement
declare

    l_clearing_instr_id       int;
    l_clearing_instr_entry_id int;
    trade_json                varchar[];
    clearing_json             varchar[];

begin
    --VP 20230914 https://dashfinancial.atlassian.net/browse/DS-7245
--insert into clearing_instruction
    insert into genesis2.clearing_instruction
    (clearing_instr_id, date_id, status, created_by_user_id, modification_type)
    values (nextval('clearing_instruction_clearing_instr_id_seq'::regclass), in_date_id, in_clearing_status, in_user_id,
            in_modification_type)
    returning clearing_instr_id into l_clearing_instr_id;

    /*INSERT INTO genesis2.clearing_instruction_entry
    (clearing_instr_entry_id, date_id, clearing_instr_id, trade_record_id, account_id, opt_customer_firm, open_close, last_qty, last_px, exec_broker, cmta, clearing_account_number, sub_account, remarks, trade_record_time, street_exec_broker, client_commission_rate, branch_sequence_number, trade_text, frequent_trader_id)
    VALUES(nextval('clearing_instruction_clearing_instr_entry_id_seq'::regclass), in_date_id, l_clearing_instr_id, @TradeRecordId, @AccountId, @Capacity, @OpenClose, @LastQty, @LastPx, @ExecBroker, @CMTA, @ClearingAccountNumber, @SubAccount, @Remarks, @TradeRecordTime, @StreetExecBroker, @CommissionRate, @BranchSeqNbr, @TradeText, @FrequentTraderId)
    returning clearing_instr_entry_id;*/

--insert into clearing_instruction_entry (most of values are from input param in_json_values)
    with ct as (select in_json_values::json as jsn),
         trd_ids as (select json_object_keys(jsn) as old_trade_record_id
                     from ct),
         tr_values as (select trd_ids.old_trade_record_id,
                              ct.jsn -> trd_ids.old_trade_record_id val_arr
                       from ct,
                            trd_ids)
    insert
    into genesis2.clearing_instruction_entry
    select nextval('clearing_instruction_clearing_instr_entry_id_seq'::regclass),
           in_date_id,
           l_clearing_instr_id,
           (l.value ->> 'new_trade_record_id')::bigint,
           tr_values.old_trade_record_id::bigint,
           (l.value ->> 'account_id')::int,
           (l.value ->> 'opt_customer_firm')::bpchar,
           (l.value ->> 'open_close')::bpchar,
           (l.value ->> 'last_qty')::int,
           (l.value ->> 'last_px')::numeric,
           (l.value ->> 'exec_broker')::varchar,
           (l.value ->> 'cmta')::varchar,
           (l.value ->> 'clearing_account_number')::varchar,
           (l.value ->> 'trade_liquidity_indicator')::varchar,
           (l.value ->> 'sub_account')::varchar,
           (l.value ->> 'remarks')::varchar,
           (l.value ->> 'trade_record_time')::timestamp,
           (l.value ->> 'electronic_report_time')::varchar,
           (l.value ->> 'street_account_name')::varchar,
           (l.value ->> 'street_exec_broker')::varchar,
           (l.value ->> 'client_commission_rate')::numeric,
           (l.value ->> 'trade_text')::varchar,
           (l.value ->> 'branch_sequence_number')::varchar,
           (l.value ->> 'frequent_trader_id')::varchar,
           (l.value ->> 'box_additional_firm')::varchar,
           (l.value ->> 'electronic_report_error_text')::varchar,
           (l.value ->> 'cboe_reason_code')::varchar as r,
           (l.value ->> 'box_additional_client_memo')::varchar
    from tr_values,
         json_array_elements(tr_values.val_arr) l;

    select array_agg(row_to_json(cte))
    into trade_json
    from (select l_clearing_instr_id as clearing_instr_id, *
          from dash360.clearing_instruction_modifications(l_clearing_instr_id)) cte;

    select array_agg(row_to_json(cte))
    into clearing_json
    from (select *
          from dash360.clearing_get_change_requests(clearing_instruction_id=>l_clearing_instr_id)) cte;

    return query
        select trade_json, clearing_json;


end;
$function$
;
