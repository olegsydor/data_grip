-- DROP FUNCTION dash360.report_alloc_instr_trade_record(int4, text);
create or replace function dash360.report_alloc_instr_trade_record(in_date_id integer, in_exec_broker text)
    returns table
            (
                "Exec Broker"           text,
                "Type"                  text,
                "Trading Firm Name"     text,
                "Account Name"          text,
                "Alloc Instr ID"        integer,
                "Trade Record ID"       bigint,
                "Symbol"                text,
                "Side"                  text,
                "O/C"                   text,
                "Exec Qty"              integer,
                "Avg Px"                numeric,
                "CMTA"                  text,
                "OCC AID"               text,
                "Capacity"              text,
                "Reported Status"       text,
                "Reported Time"         timestamp without time zone,
                "Trade is Busted"       character,
                "Created Time"          timestamp without time zone,
                "Created by User"       text,
                "Alloc is Deleted"      character,
                "Deleted Time"          timestamp without time zone,
                "Deleted by User"       text,
                "First Trade Exec Time" text,
                "Last Trade Exec Time"  text
            )
    LANGUAGE plpgsql
    SECURITY DEFINER
AS $function$
    -- 2025-01-17 OS https://dashfinancial.atlassian.net/browse/DS-9441
    -- 2025-01-21 OS https://dashfinancial.atlassian.net/browse/DS-9441 add new columns reported_time, is_deleted, delete_time, user_name
    -- 2025-02-12 OS https://dashfinancial.atlassian.net/browse/DS-9572 add new columns
declare
    l_load_id int;
    l_step_id int;
    l_row_cnt int;

begin
    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id,
                           'report_alloc_instr_trade_record for ' || in_date_id::text || ' STARTED ====', 0, 'O')
    into l_step_id;

    return query
        select min(tr.exec_broker)  as exec_broker,                                     -- "Exec Broker"
               'allocation',                                                            -- "Type"
               min(tf.trading_firm_name),                                               -- "Trading Firm Name"
               min(ac.account_name) as account_name,                                    -- "Account Name"
               bar.alloc_instr_id,                                                      -- "Alloc Instr ID"
               null::int8,                                                              -- "Trade Record ID"
               min(di.display_instrument_id2),                                          -- "Symbol"
               min(case bar.side when '1' then 'Buy' when '2' then 'Sell' end),         -- "Side"
               min(case bar.open_close when 'O' then 'Open' when 'C' then 'Close' end), -- "O/C"
               min(ai.total_qty),                                                       -- "Exec Qty"
               min(bar.avg_px),                                                         -- "Avg Px"
               min(bar.ca_cmta),                                                        -- "CMTA"
               min(bar.occ_actionable_id),                                              -- "OCC AID"
               string_agg(distinct concat_ws(': ', cst.customer_or_firm_id, cst.customer_or_firm_name),
                          ', '),                                                        -- "Capacity"

               'Reported',                                                              -- "Reported Status"
               min(bar.db_create_time),                                                 -- "Reported Time"
               '',                                                                      -- "Trade is busted"
               min(ai.create_time),                                                     -- "Created Time"
               min(uic.user_name),                                                      -- "Created by User"
               min(ai.is_deleted),                                                      -- "Alloc is deleted"
               min(ai.delete_time),                                                     -- "Deleted Time"
               min(ui.user_name),                                                       -- "Deleted by User"
               min(to_char(tr.first_trade_exec_time, 'HH24:MI:SS')),
               min(to_char(tr.last_trade_exec_time, 'HH24:MI:SS'))

        from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker,
                                      tr.account_id,
                                      min(coalesce(tr.street_trade_record_time, tr.trade_record_time)) as first_trade_exec_time,
                                      max(coalesce(tr.street_trade_record_time, tr.trade_record_time)) as last_trade_exec_time
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
                                 and tr.exec_broker = in_exec_broker
                               group by tr.exec_broker, tr.account_id
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and uic.is_deleted <> 'Y'
        where bar.date_id = in_date_id
          and bar.to_report = 'R'
        group by bar.alloc_instr_id

        union all


        select tr.exec_broker::varchar(32),                                                  -- "Exec Broker"
               'trade',                                                                      -- "Type"
               tf.trading_firm_name,                                                         -- "Trading Firm Name"
               ac.account_name,                                                              -- "Account Name"
               null,                                                                         -- "Alloc Instr ID"
               btr.trade_record_id,                                                          -- "Trade Record ID"
               di.display_instrument_id2,                                                    -- "Symbol"
               case tr.side when '1' then 'Buy' when '2' then 'Sell' end,                    -- "Side"
               case tr.open_close when 'O' then 'Open' when 'C' then 'Close' end,            -- "O/C"
               tr.last_qty,                                                                  -- "Exec Qty"
               tr.last_px,                                                                   -- "Avg Px"
               null,                                                                         -- "CMTA"
               null,                                                                         -- "OCC AID"
               concat_ws(': ', tr.opt_customer_firm, cst.customer_or_firm_name),             -- "Capacity"
               'Reported',                                                                   -- "Reported Status"
               coalesce((select bar.db_create_time
                         from dash_reporting.bofa_allocation_report bar
                                  join genesis2.alloc_instr2trade_record aitr
                                       on aitr.date_id = bar.date_id and aitr.alloc_instr_id = bar.alloc_instr_id
                                  join genesis2.trade_record tri
                                       on tri.date_id = bar.date_id and tri.trade_record_id = aitr.trade_record_id
                         where true
--                           and tri.exch_exec_id = tr.exch_exec_id
                           and tri.exec_id = tr.exec_id
                           and tri.is_billed = 'R'
                         order by 1
                         limit 1), tr.db_create_time),                                         -- "Reported Time"
               tr.is_busted,                                                                   -- "Trade is busted"
               null,                                                                           -- "Created Time"
               null,                                                                           -- "Created by User"
               null,                                                                           -- "Alloc is deleted"
               null,                                                                           -- "Deleted Time"
               null,                                                                           -- "Deleted by User"
               to_char(coalesce(tr.street_trade_record_time, tr.trade_record_time), 'HH24:MI:SS'),
               to_char(coalesce(tr.street_trade_record_time, tr.trade_record_time), 'HH24:MI:SS')
        from dash_reporting.bofa_trade_record btr
                 join genesis2.trade_record tr using (trade_record_id, date_id)
                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = tr.instrument_id
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = tr.opt_customer_firm
        where btr.date_id = in_date_id
          and btr.to_report = 'R'
          and tr.exec_broker = in_exec_broker;
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id,
                           'report_alloc_instr_trade_record for ' || in_date_id::text ||
                           ' COMPLETED ====', l_row_cnt, 'O')
    into l_step_id;
end;
$function$
;