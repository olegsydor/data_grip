select *
from dash360.report_sg_middle_offic_ooc_alloc_report(in_start_date_id := 20260825, in_end_date_id := 20260825,
                                                     in_trading_firm_ids := null,
                                                     in_account_ids := '{263743,258492,5387}');

select *
from dash360.report_sg_middle_offic_ooc_alloc_report(in_start_date_id := 20260825, in_end_date_id := 20260825,
                                                     in_trading_firm_ids := null,
                                                     in_account_ids := null);


CREATE OR REPLACE FUNCTION dash360.report_sg_middle_offic_ooc_alloc_report(in_start_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                                           in_end_date_id int4 default to_char(current_date, 'YYYYMMDD')::int4,
                                                                           in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                                           in_account_ids integer[] DEFAULT '{}'::integer[])
    RETURNS table
            (
                "ITEM"          int8,
                "BUY/SELL"      text,
                "CONTRACTS"     int4,
                "SYMBOL"        varchar(10),
                "MONTH"         text,
                "STRIKE"        numeric(12, 4),
                "PUT/CALL"      bpchar(1),
                "AVG. PRICE"    numeric(14, 6),
                "CONTRA PARTY"  varchar(3),
                "CUSTOMER"      varchar(20),
                "MARKET MAKER"  text,
                "TRAILER CODE"  text,
                "FROM (C/F/M)"  bpchar(1),
                "TO (C/F/M)"    bpchar(1),
                "FROM CLR NO"   text,
                "BUY/SELL FROM" text,
                date_id         int4
            )
    LANGUAGE plpgsql
AS
$fn$
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

    return query
        select aie.allocation_instruction_entry_id         as "ITEM",
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
          and ai.account_id = any (l_account_ids);
    get diagnostics l_row_cnt = row_count;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' COMPLETED ====', l_row_cnt, 'C')
    into l_step_id;
end;
$fn$