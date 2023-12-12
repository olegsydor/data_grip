drop function if exists trash.so_clearing_get_change_requests;

CREATE FUNCTION trash.so_clearing_get_change_requests(start_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                      end_status_date timestamp without time zone DEFAULT NULL::timestamp without time zone,
                                                      user_id bigint DEFAULT NULL::bigint,
                                                      clearing_instruction_id integer DEFAULT NULL::integer)
    RETURNS TABLE
            (
                clearing_instr_id      integer,
                date_id                integer,
                status                 character,
                remarks                character varying,
                trading_firm_names     character varying[],
                display_instrument_ids character varying[],
                create_time            timestamp without time zone,
                created_by_user_id     integer,
                claim_time             timestamp without time zone,
                claimed_by_user_id     integer,
                process_time           timestamp without time zone,
                claimed_by_user_name   character varying,
                created_by_user_name   character varying,
                modification_type      character,
                alloc_instrument_ids   integer[],
                new_trading_firm_ids   character varying[],
                account_ids            bigint[],
                cie_status             integer,
                cie_sent               integer,
                cie_rejected           integer,
                cie_pending            integer
            )
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY 20211112 Performance improvement https://dashfinancial.atlassian.net/browse/DS-4402
    -- SY 20211115 GTH related bug fixed https://dashfinancial.atlassian.net/browse/DS-4431
    -- SY 20220305 Joind condition by date_id has been added inside lateral join
    -- SO 20230920 removed dynamic sql
    -- SO 20230920 Add returned parameters for dash360.clearing_get_change_requests https://dashfinancial.atlassian.net/browse/DS-7287

DECLARE
    f_clearing_instruction_id int4   := so_clearing_get_change_requests.clearing_instruction_id ;
    f_user_id                 bigint := so_clearing_get_change_requests.user_id;

begin


    /*
=================== RUN this is performance is too pure
analyse genesis2.clearing_instruction;
analyse genesis2.user_identifier;
analyse genesis2.clearing_instruction_entry;
do $$ begin  execute 'analyse daily_partitions.trade_record_'||to_char(current_date, 'YYYYMM'); end $$;
analyse genesis2.instrument;
analyse genesis2.account;
analyse genesis2.trading_firm;
analyse clearing_instruction_entry;
analyse genesis2.alloc_instr2trade_record;
analyse genesis2.allocation_instruction;

     * */

    raise info '%: start_status_date = %', clock_timestamp(), start_status_date::text;
    raise info '%: end_status_date = %', clock_timestamp(), end_status_date::text;
    raise info '%: user_id = %', clock_timestamp(), f_user_id::text;
    raise info '%: clearing_instruction_id = %', clock_timestamp(), f_clearing_instruction_id::text;

    drop table if exists ci;
    create temp table ci on commit drop as
    select ci.clearing_instr_id,
           ci.date_id,
           ci.status,
           ci.remarks,
           ci.create_time,
           ci.created_by_user_id,
           ci.claim_time,
           ci.claimed_by_user_id,
           ci.process_time,
           claim_user.user_name  claimed_by_user_name,
           create_user.user_name created_by_user_name,
           ci.modification_type
    from genesis2.clearing_instruction ci
             inner join genesis2.user_identifier create_user on create_user.user_id = ci.created_by_user_id
             left join genesis2.user_identifier claim_user on claim_user.user_id = ci.claimed_by_user_id
        -->> add
             left join lateral (select --ce.clearing_instr_id,
                                       count(*)::int                                                                as total_cnt,
                                       sum(case when electronic_report_status is not null then 1 else 0 end)::int   as status_sent,
                                       sum(case when electronic_report_status in ('I', 'R') then 1 else 0 end)::int as status_rejected,
                                       sum(case when electronic_report_status = 'P' then 1 else 0 end)::int         as status_pending,
                                       sum(case when electronic_report_status = 'A' then 1 else 0 end)::int         as status_accepted,
                                       sum(case when electronic_report_status is null then 1 else 0 end)::int       as status_null
                                from genesis2.clearing_instruction_entry ce
                                where true
                                  and ce.clearing_instr_id = ci.clearing_instr_id
                                limit 1) ce on true
    --<<
    where ci.is_deleted = 'N'
      and case
              when start_status_date is not null and end_status_date is not null
                  then ci.create_time between start_status_date and end_status_date
              else true end
      and case
              when clearing_instruction_id is not null then ci.clearing_instr_id = f_clearing_instruction_id
              else true end
      and case
              when f_user_id is not null then exists (select null
                                                      from genesis2.user_identifier ua
                                                      where ua.user_id = f_user_id
                                                        and ua.user_role = 'A'
                                                        and ua.is_deleted = 'N')
                  or (ci.clearing_instr_id in (select e.clearing_instr_id
                                               from genesis2.clearing_instruction_entry e
                                                        left join staging.user2account ua
                                                                  on e.account_id = ua.account_id and
                                                                     ua.user_id = f_user_id and ua.user_role = 'P'
                                               group by e.clearing_instr_id
                                               having count(e.account_id) = count(ua.account_id))
                      or
                      ci.clearing_instr_id in (select e.clearing_instr_id
                                               from genesis2.clearing_instruction_entry e
                                                        left join (select acc.account_id
                                                                   from staging.trading_firm_admin tf
                                                                            inner join genesis2.account acc
                                                                                       on tf.trading_firm_id = acc.trading_firm_id and acc.is_deleted = 'N'
                                                                            inner join genesis2.user_identifier ui
                                                                                       on ui.user_id = tf.user_id and ui.is_deleted = 'N'
                                                                   where ui.user_role = 'T'
                                                                     and tf.user_id = f_user_id) l
                                                                  on e.account_id = l.account_id
                                               group by e.clearing_instr_id
                                               having count(e.account_id) = count(l.account_id))
                                                  )
              else true end;

    raise info '%: create temp  table ci on commit drop as', clock_timestamp();


    RETURN QUERY
        SELECT ci.clearing_instr_id,
               ci.date_id,
               ci.status,
               ci.remarks,
               o.trading_firm_names,
               o.display_instrument_ids,
               ci.create_time,
               ci.created_by_user_id,
               ci.claim_time,
               ci.claimed_by_user_id,
               ci.process_time,
               ci.claimed_by_user_name,
               ci.created_by_user_name,
               ci.modification_type,
               alc.alloc_instrument_ids,
               o.trading_firm_ids as new_trading_firm_ids,
               o.account_ids,
               case
                   when status_pending + status_rejected > 0 then 1
                   when status_accepted > 0 and total_cnt - status_accepted - status_null = 0 then 2
                   else null end  as cie_status,
               status_sent        as cie_sent,
               status_rejected    as cie_rejected,
               status_pending     as cie_pending
        FROM ci
                 left join lateral (select array_agg(distinct orig_tf.trading_firm_name) trading_firm_names,
                                           array_agg(distinct ce.account_id::int8)       account_ids,
                                           array_agg(distinct acc.trading_firm_id)       trading_firm_ids,
                                           array_agg(distinct i.display_instrument_id2)  display_instrument_ids,
                                       count(*)::int                                                                as total_cnt,
                                       sum(case when electronic_report_status is not null then 1 else 0 end)::int   as status_sent,
                                       sum(case when electronic_report_status in ('I', 'R') then 1 else 0 end)::int as status_rejected,
                                       sum(case when electronic_report_status = 'P' then 1 else 0 end)::int         as status_pending,
                                       sum(case when electronic_report_status = 'A' then 1 else 0 end)::int         as status_accepted,
                                       sum(case when electronic_report_status is null then 1 else 0 end)::int       as status_null
                                    from genesis2.clearing_instruction_entry ce
                                             inner join genesis2.trade_record tr on tr.trade_record_id =
                                                                                    coalesce(ce.new_trade_record_id, ce.trade_record_id) and
                                                                                    tr.date_id = ce.date_id
                                             inner join genesis2.instrument i
                                                        on i.instrument_id = tr.instrument_id and i.is_deleted = 'N'
                                             inner join genesis2.account acc
                                                        on acc.account_id = ce.account_id and acc.is_deleted = 'N'
                                             inner join genesis2.account orig_acc
                                                        on orig_acc.account_id = tr.account_id and orig_acc.is_deleted = 'N'
                                             inner join genesis2.trading_firm orig_tf
                                                        on orig_tf.trading_firm_id = orig_acc.trading_firm_id and
                                                           orig_tf.is_deleted = 'N'
                                    where ce.clearing_instr_id = ci.clearing_instr_id
                                      and ce.date_id = ci.date_id
            ) o on 1 = 1
                 left join lateral (select ce.clearing_instr_id,
                                           array_agg(distinct a.alloc_instr_id) alloc_instrument_ids
                                    from genesis2.clearing_instruction_entry ce
                                             inner join genesis2.alloc_instr2trade_record ai2tr
                                                        on ai2tr.trade_record_id =
                                                           coalesce(ce.new_trade_record_id, ce.trade_record_id)
                                             inner join genesis2.allocation_instruction a
                                                        on a.alloc_instr_id = ai2tr.alloc_instr_id and a.is_deleted = 'N'
                                    where ce.clearing_instr_id = ci.clearing_instr_id
                                      and ce.date_id = ci.date_id
                                    group by ce.clearing_instr_id
                                    limit 1 ) alc on true
        order by ci.clearing_instr_id desc;

    raise info '%: DONE', clock_timestamp();

end;
$function$
;
-----------------

select clearing_instr_id, date_id, status, remarks, trading_firm_names, display_instrument_ids, create_time, created_by_user_id, claim_time, claimed_by_user_id, process_time, claimed_by_user_name, created_by_user_name, modification_type, alloc_instrument_ids, new_trading_firm_ids, account_ids
from dash360.clearing_get_change_requests('2023-09-01', '2023-09-21')
except
select clearing_instr_id, date_id, status, remarks, trading_firm_names, display_instrument_ids, create_time, created_by_user_id, claim_time, claimed_by_user_id, process_time, claimed_by_user_name, created_by_user_name, modification_type, alloc_instrument_ids, new_trading_firm_ids, account_ids
from trash.so_clearing_get_change_requests('2023-09-01', '2023-09-21')

select *
from trash.so_clearing_get_change_requests('2023-09-01', '2023-09-21')


select clearing_instr_id,
    count(*) as total_cnt,
       sum(case when electronic_report_status is not null then 1 else 0 end) as status_sent,
       sum(case when electronic_report_status in ('I', 'R') then 1 else 0 end) as status_rejected,
       sum(case when electronic_report_status = 'P' then 1 else 0 end) as status_pending,
       sum(case when electronic_report_status = 'A' then 1 else 0 end) as status_accepted,
       sum(case when electronic_report_status is null then 1 else 0 end) as status_null
from genesis2.clearing_instruction_entry ce
where true
--      and clearing_instr_id = 69118
group by clearing_instr_id



CREATE OR REPLACE FUNCTION dash360.clearing_instruction_modifications(in_clearing_instr_id integer)
    RETURNS TABLE
            (
                trade_record_id              bigint,
                parent_order_id              bigint,
                parent_client_order_id       character varying,
                client_order_id              character varying,
                symbol                       character varying,
                instrument_type_id           character,
                trade_record_reason          character,
                maturity_date                timestamp without time zone,
                side                         character,
                last_px                      numeric,
                exec_time                    timestamp without time zone,
                client_id                    character varying,
                exchange_name                character varying,
                exchange_id                  character varying,
                liquidity_indicator          character varying,
                account_id                   integer,
                orig_account_id              bigint,
                account_name                 character varying,
                orig_account_name            character varying,
                capacity                     character,
                orig_capacity                character,
                open_close                   character,
                orig_open_close              character,
                last_qty                     integer,
                orig_last_qty                integer,
                gup                          character varying,
                orig_gup                     character varying,
                cmta                         character varying,
                orig_cmta                    character varying,
                clearing_account_number      character varying,
                orig_clearing_account_number character varying,
                sub_account                  character varying,
                orig_sub_account             character varying,
                remarks                      character varying,
                orig_remarks                 character varying,
                tf_name                      character varying,
                modified_time                timestamp without time zone,
                alloc_instr_id               integer,
                report_status                character,
                street_account_name          character varying,
                orig_street_account_name     character varying,
                street_exec_broker           character varying,
                orig_street_exec_broker      character varying,
                client_commission_rate       numeric,
                orig_client_commission_rate  numeric,
                branch_sequence_number       character varying,
                orig_branch_sequence_number  character varying,
                trade_text                   character varying,
                orig_trade_text              character varying,
                frequent_trader_id           character varying,
                orig_frequent_trader_id      character varying,
                electronic_report_error_text character varying
            )
    LANGUAGE plpgsql
AS
$function$
begin

    return query
        select tr.trade_record_id::bigint,
               orig_tr.order_id                              as parent_order_id,
               orig_tr.client_order_id                       as parent_client_order_id,
               orig_tr.street_client_order_id                as client_order_id,
               i.display_instrument_id2                      as symbol,
               i.instrument_type_id,
               orig_tr.trade_record_reason,
               i.last_trade_date                             as maturity_date,
               orig_tr.side,
               tr.last_px,
               tr.trade_record_time                          as exec_time,
               orig_tr.client_id,
               real_exch.exchange_name,
               real_exch.exchange_id,
               orig_tr.trade_liquidity_indicator             as liquidity_indicator,
               tr.account_id                                 as account_id,
               orig_tr.account_id::bigint                    as orig_account_id,
               acc.account_name,
               orig_acc.account_name                         as orig_account_name,
               tr.opt_customer_firm                          as capacity,
               orig_tr.opt_customer_firm                     as orig_capacity,
               tr.open_close,
               orig_tr.open_close                            as orig_open_close,
               tr.last_qty,
               orig_tr.last_qty                              as orig_last_qty,
               tr.exec_broker                                as gup,
               orig_tr.exec_broker                           as orig_gup,
               tr.cmta,
               orig_tr.cmta                                  as orig_cmta,
               tr.clearing_account_number,
               orig_tr.clearing_account_number               as orig_clearing_account_number,
               tr.sub_account,
               orig_tr.sub_account                           as orig_sub_account,
               tr.remarks,
               orig_tr.remarks                               as orig_remarks,
               tf.trading_firm_name                          as tf_name,
               ci.create_time                                as modified_time,
               alc.alloc_instr_id,
               tr.electronic_report_status                      report_status,
               tr.street_account_name,
               orig_tr.street_account_name                   as orig_street_account_name,
               tr.street_exec_broker,
               orig_tr.street_exec_broker                    as orig_street_exec_broker,
               tr.client_commission_rate,
               CCRU.rate                                     as orig_client_commission_rate,
               tr.branch_sequence_number,
               orig_tr.branch_sequence_number                as orig_branch_sequence_number,
               tr.trade_text,
               orig_tr.trade_text                            as orig_trade_text,
               tr.frequent_trader_id,
               orig_tr.frequent_trader_id                    as orig_frequent_trader_id,
               case
                   when tr.electronic_report_status in ('I', 'R')
                       then electronic_report_error_text end as electronic_report_error_text
        from clearing_instruction_entry tr
                 inner join clearing_instruction ci on ci.clearing_instr_id = tr.clearing_instr_id
                 inner join account acc on acc.account_id = tr.account_id
                 inner join trading_firm as tf on tf.trading_firm_id = acc.trading_firm_id and tf.is_deleted = 'N'
                 left join trade_record orig_tr on orig_tr.trade_record_id = tr.trade_record_id
                 left join account orig_acc on orig_tr.account_id = orig_acc.account_id
                 left join exchange exch on exch.exchange_id = orig_tr.exchange_id
                 left join exchange real_exch on real_exch.exchange_id = exch.real_exchange_id
                 left join instrument i on i.instrument_id = orig_tr.instrument_id
                 left join (select AT.TRADE_RECORD_ID, A.alloc_instr_id
                            from ALLOC_INSTR2TRADE_RECORD AT
                                     inner join ALLOCATION_INSTRUCTION A
                                                on A.ALLOC_INSTR_ID = AT.ALLOC_INSTR_ID AND A.IS_DELETED = 'N') alc
                           on (alc.trade_record_id = coalesce(tr.new_trade_record_id, tr.trade_record_id))
                 left join lateral (select L1.rate
                                    from (SELECT row_number()
                                                 over (partition by tl.trade_record_id , book_record_type_id , billing_entity order by cr.priority ) as rn,
                                                 tl.rate
                                          FROM trade_level_book_record tl
                                                   inner join book_record_creator cr
                                                              on tl.book_record_creator_id = cr.book_record_creator_id
                                          WHERE book_record_type_id = 'CCRU'
                                            and tl.trade_record_id = orig_tr.trade_record_id) L1
                                    where rn = 1) CCRU on true
        where ci.clearing_instr_id = in_clearing_instr_id;

end;
$function$
;
