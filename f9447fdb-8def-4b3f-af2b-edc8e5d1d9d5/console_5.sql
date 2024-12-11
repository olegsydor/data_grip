create table if not exists trash.alloc_instr_parent_trade_ids
(
    alloc_instr_id  int4,
    trade_record_id int8,
    date_id         int4,
    db_create_time  timestamp default clock_timestamp()
);
create index alloc_instr_parent_trade_ids_trade_record_id_idx on trash.alloc_instr_parent_trade_ids (trade_record_id);

select distinct alloc_instr_id from trash.allocation_report;

 insert into trash.alloc_instr_parent_trade_ids (trade_record_id, alloc_instr_id, date_id)
    select unnest(staging.all_orig_trade_record_id_today(aitr.trade_record_id, aitr.date_id)),
           aitr.alloc_instr_id,
           aitr.date_id
    from genesis2.alloc_instr2trade_record aitr
             join genesis2.trade_record tr on tr.trade_record_id = aitr.trade_record_id
        and aitr.date_id = tr.date_id
    where true
      and aitr.alloc_instr_id in (-51903,-51905,-51907,-51908,-51904)
      and aitr.date_id between :in_start_date_id and :in_end_date_id
      and tr.orig_trade_record_id is not null
      and not exists (select null from trash.alloc_instr_parent_trade_ids at where at.alloc_instr_id = aitr.alloc_instr_id);


select * from trash.get_all_parent_trade_record_ids_by_alloc_instr_id(-51911, 20241204);
select array_agg(trade_record_id) from trash.alloc_instr_parent_trade_ids
where date_id = in_date

--------------
create
    or replace
    function trash.so_allocation_report2(in_start_date_id integer, in_end_date_id integer,
                                        in_exec_broker text DEFAULT '792'::text)
    returns int4
    language plpgsql
as
$fx$
declare
    l_alloc_instr_id_reported int4[];
    l_alloc_instr_id           int4[];
    l_row_cnt                  int4;

begin
    -- get the list of all alloc_instr_id_reported in the chain of the reported records;
    select array_agg(alloc_instr_id)
    into l_alloc_instr_id_reported
    from trash.allocation_report
    where date_id between in_start_date_id and in_end_date_id
    and to_report = 'report'; -- this condition looks excessive

    with base_ins as (
        insert into trash.allocation_report (last_qty, alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty,
                                             opt_is_fix_clfirm_processed, ftr_cmta, ca_cmta,
                                             opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm,
                                             occ_actionable_id, dataset, to_report)
            SELECT ftr.last_qty,
                   alin.alloc_instr_id,
                   alin.side,
                   alin.avg_px,
                   alin.date_id,
                   alin.open_close,
                   ae.alloc_qty,
                   acc.opt_is_fix_clfirm_processed,
                   ftr.cmta                                     AS ftr_cmta,
                   ca.cmta                                      AS ca_cmta,
                   acc.opt_is_fix_custfirm_processed,
                   ftr.opt_customer_firm,
                   acc.opt_customer_or_firm,
                   ae.occ_actionable_id                         as occ_actionable_id,
                   to_char(clock_timestamp(), 'YYYYMMDDHH24MI') as dataset,
                   case
                       --                        when
--                            trash.get_all_parent_trade_record_ids_by_alloc_instr_id(alin.alloc_instr_id, alin.date_id) &&
--                            l_trade_record_id_reported
--                            then 'old false logic'
                       when exists (select null
                                    from trash.allocation_report ar
                                    where ar.alloc_instr_id = ae.alloc_instr_id
                                      and to_report = 'report') then 'skip - current alloc_instr_id'
                       when trash.get_all_parent_alloc_instr_id(alin.alloc_instr_id, alin.date_id) &&
                            l_alloc_instr_id_reported then 'skip alloc_instr_id has been reported'
                       else 'report' end                        as to_report
            FROM genesis2.allocation_instruction_entry ae
                     JOIN genesis2.allocation_instruction alin
                          ON alin.alloc_instr_id = ae.alloc_instr_id AND alin.is_deleted <> 'Y'
                     inner join lateral (select tr.cmta,
                                                tr.opt_customer_firm,
                                                tr.last_qty
                                         from genesis2.alloc_instr2trade_record aitr
                                                  inner join genesis2.trade_record tr
                                                             on aitr.trade_record_id = tr.trade_record_id
                                                                 and aitr.date_id = tr.date_id
                                                                 and tr.is_busted = 'N'
                                                                 and case
                                                                         when in_exec_broker is null then true
                                                                         else tr.exec_broker = in_exec_broker end
                                                                 and tr.exec_broker is not null
                                         where aitr.alloc_instr_id = alin.alloc_instr_id
                                           and aitr.date_id = alin.date_id
                                         limit 1
                ) ftr on true
                     JOIN genesis2.clearing_account ca
                          ON (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                              AND ca.clearing_account_type = '1' AND ca.market_type = 'O')
                     JOIN genesis2.account acc ON (acc.account_id = ca.account_id AND acc.is_deleted <> 'Y' AND
                                                   acc.opt_report_to_mpid = 'MLCB' AND
                                                   acc.trading_firm_id <> 'cantor')
                     JOIN genesis2.option_contract oc ON oc.instrument_id = alin.instrument_id
                     JOIN genesis2.option_series os ON os.option_series_id = oc.option_series_id
                     JOIN genesis2.instrument i ON i.instrument_id = alin.instrument_id
            WHERE alin.date_id between in_start_date_id and in_end_date_id
              and not exists (select null
                              from trash.allocation_report ar
                              where ar.alloc_instr_id = ae.alloc_instr_id
                                and ar.side = alin.side
                                and ar.date_id = alin.date_id)
            returning alloc_instr_id)
    select array_agg(distinct alloc_instr_id)
    into l_alloc_instr_id
    from base_ins;

    select array_length(l_alloc_instr_id, 1) into l_row_cnt;

    insert into trash.alloc_instr_parent_trade_ids (trade_record_id, alloc_instr_id, date_id)
    select unnest(staging.all_orig_trade_record_id_today(aitr.trade_record_id, aitr.date_id)),
           aitr.alloc_instr_id,
           aitr.date_id
    from genesis2.alloc_instr2trade_record aitr
             join genesis2.trade_record tr on tr.trade_record_id = aitr.trade_record_id
        and aitr.date_id = tr.date_id
    where true
      and aitr.alloc_instr_id = any (l_alloc_instr_id)
      and aitr.date_id between in_start_date_id and in_end_date_id
      and tr.orig_trade_record_id is not null
      and not exists (select null
                      from trash.alloc_instr_parent_trade_ids at
                      where at.alloc_instr_id = aitr.alloc_instr_id);

    return l_row_cnt;
end;
$fx$;



select * from trash.allocation_report ar
         order by dataset;
where dataset = '202412061535'

select ar.alloc_instr_id, alloc_qty--, min(to_report), array_agg(pa.trade_record_id) as trade_records
 from trash.allocation_report ar
join trash.alloc_instr_parent_trade_ids pa on pa.alloc_instr_id = ar.alloc_instr_id
where dataset = '202412061535'
group by ar.alloc_instr_id, alloc_qty;


select distinct alloc_instr_id, trade_record_id from trash.alloc_instr_parent_trade_ids;


select * from dash360.report_rps_ml_options_cmta(20241206, 20241209, null);

select * from trash.so_allocation_report(20241206, 20241209, null);


select * from trash.allocation_report ar
         order by dataset;

select * from trash.get_all_parent_trade_record_ids_by_alloc_instr_id(-52394, 20241206)
;


create or replace function dash360.allocation_report(in_start_date_id integer, in_end_date_id integer,
                                          in_exec_broker text default '792'::text)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fn$
declare
        l_load_id int;
    l_step_id int;
    l_alloc_instr_id_reported int4[];
    l_alloc_instr_id           int4[];
    l_row_cnt                  int4;
    l_msg_text text;

begin
    l_msg_text := 'allocation_report for ' || in_start_date_id::text || '-' || in_end_date_id::text || 'for ' ||
                  case when in_exec_broker is null then 'all exec brokers' else in_exec_broker end || ' ';

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;
    select public.load_log(l_load_id, l_step_id, l_msg_text || ' STARTED ====', 0, 'O')
    into l_step_id;

    -- preparing data
    -- get the list of all alloc_instr_id_reported in the chain of the reported records;
    select array_agg(alloc_instr_id)
--     into l_alloc_instr_id_reported
    from dash360.bofa_allocation_report
    where date_id between :in_start_date_id and :in_end_date_id
    and to_report = 'report'; -- this condition looks excessive


    with base_ins as (
        insert into dash360.bofa_allocation_report
            (last_qty, alloc_instr_id, side, avg_px, date_id, open_close, alloc_qty, opt_is_fix_clfirm_processed,
             ftr_cmta, ca_cmta, opt_is_fix_custfirm_processed, opt_customer_firm, opt_customer_or_firm,
             occ_actionable_id, dataset, to_report
--                 , trade_record_sheep
            )
            select ftr.last_qty,
                   alin.alloc_instr_id,
                   alin.side,
                   alin.avg_px,
                   alin.date_id,
                   alin.open_close,
                   ae.alloc_qty,
                   acc.opt_is_fix_clfirm_processed,
                   ftr.cmta,             -- ftr_cmta,
                   ca.cmta,              -- ca_cmta,
                   acc.opt_is_fix_custfirm_processed,
                   ftr.opt_customer_firm,
                   acc.opt_customer_or_firm,
                   ae.occ_actionable_id, -- occ_actionable_id,
                   :l_load_id,            -- dataset,
                   case
                       when ar.date_id is not null then 'skip - current alloc_instr_id'
                       when or_ai.alloc_instr_ids && :l_alloc_instr_id_reported then 'skip - alloc_instr_id has been reported before'
                       else 'report' end as to_report,
--                  or_ai.alloc_instr_ids && l_alloc_instr_id_reported -- trade_record_sheep

            array(select unnest(or_ai.alloc_instr_ids) intersect
              select unnest(:l_alloc_instr_id_reported))

            from genesis2.allocation_instruction_entry ae
                     join genesis2.allocation_instruction alin
                          on alin.alloc_instr_id = ae.alloc_instr_id and alin.is_deleted <> 'Y'
                     left join lateral (select alloc_instr_ids
                                        from staging.get_all_alloc_instr_id_for_orig(alin.alloc_instr_id,
                                                                                     alin.date_id) as x(alloc_instr_ids)
                                        limit 1) or_ai on true
                     inner join lateral (select tr.cmta,
                                                tr.opt_customer_firm,
                                                tr.last_qty
                                         from genesis2.alloc_instr2trade_record aitr
                                                  inner join genesis2.trade_record tr
                                                             on aitr.trade_record_id = tr.trade_record_id
                                                                 and aitr.date_id = tr.date_id
                                                                 and tr.is_busted = 'N'
                                                                 and case
                                                                         when :in_exec_broker is null then true
                                                                         else tr.exec_broker = :in_exec_broker end
                                                                 and tr.exec_broker is not null
                                         where aitr.alloc_instr_id = alin.alloc_instr_id
                                           and aitr.date_id = alin.date_id
                                         limit 1
                ) ftr on true
                     join genesis2.clearing_account ca
                          on (ca.clearing_account_id = ae.clearing_account_id /*AND ca.is_deleted <> 'Y'*/
                              and ca.clearing_account_type = '1' and ca.market_type = 'O')
                     join genesis2.account acc ON (acc.account_id = ca.account_id and acc.is_deleted <> 'Y' and
                                                   acc.opt_report_to_mpid = 'MLCB' and
                                                   acc.trading_firm_id <> 'cantor')
                     join genesis2.option_contract oc on oc.instrument_id = alin.instrument_id
                     join genesis2.option_series os on os.option_series_id = oc.option_series_id
                     join genesis2.instrument i on i.instrument_id = alin.instrument_id
                     left join lateral (select ar.date_id
                                        from dash360.bofa_allocation_report ar
                                        where ar.alloc_instr_id = ae.alloc_instr_id
                                          and to_report = 'report'
                                        limit 1) ar on true
            where alin.date_id between :in_start_date_id and :in_end_date_id
              and not exists (select null
                              from dash360.bofa_allocation_report ar
                              where ar.alloc_instr_id = ae.alloc_instr_id
                                and ar.side = alin.side
                                and ar.date_id = alin.date_id)
            returning alloc_instr_id)
    select array_agg(distinct alloc_instr_id)
    into l_alloc_instr_id
    from base_ins;

    select array_length(l_alloc_instr_id, 1) into l_row_cnt;

    select public.load_log(l_load_id, l_step_id, l_msg_text || ' FINISHED ====', l_row_cnt, 'O')
    into l_step_id;

    return query
        select l_row_cnt::text;

end;
$fn$
;
create temp table t_trade_record_reported as
select tr.trade_record_id, tr.date_id, aitr.alloc_instr_id from genesis2.trade_record tr
join genesis2.alloc_instr2trade_record aitr on tr.trade_record_id = aitr.trade_record_id and aitr.date_id = tr.date_id
where aitr.alloc_instr_id = any(:l_alloc_instr_id_reported)

select array_agg(distinct trade_record_id) from t_trade_record_reported;

SELECT l.date_id,
       l.cmta,
       l.open_close,
       l.order_id,
       l.instrument_id,
       l.side,
       sum(last_qty)                                        AS day_cum_qty,
       CASE sum(last_qty)
           WHEN 0 THEN NULL
           ELSE sum(last_qty * last_px) / sum(last_qty) END AS avg_px,
       max(opt_customer_firm)                               AS customer_or_firm_id,
       l.opt_is_fix_clfirm_processed,
       l.opt_customer_or_firm,
       l.opt_nickel_commission,
       l.opt_penny_commission,
       l.opt_is_fix_custfirm_processed
/*,
       max(street_account_name) as street_account_name*/
FROM (SELECT ftr.date_id                                              AS date_id,
             CASE
                 WHEN (ci.clearing_instr_id IS NOT NULL OR acc.opt_is_fix_clfirm_processed = 'Y')
                     THEN ftr.cmta
                 ELSE NULL END                                        AS cmta,
             ftr.open_close,
             ftr.order_id                                             AS order_id,
             ftr.instrument_id,
             ftr.account_id,
             ftr.side,
             CASE
                 WHEN ci.clearing_instr_id IS NULL THEN ftr.last_qty
                 ELSE cie.last_qty END                                AS last_qty,
             CASE
                 WHEN ci.clearing_instr_id IS NULL THEN ftr.last_px
                 ELSE cie.last_px END                                 AS last_px,
             CASE
                 WHEN ci.clearing_instr_id IS NULL THEN ftr.opt_customer_firm
                 ELSE cie.opt_customer_firm END                          opt_customer_firm,
             CASE WHEN ci.clearing_instr_id IS NULL THEN 0 ELSE 1 END AS is_cleared,
             acc.opt_is_fix_clfirm_processed,
             acc.opt_customer_or_firm,
             acc.opt_nickel_commission,
             acc.opt_penny_commission,
             acc.opt_is_fix_custfirm_processed,
             case when staging.all_orig_trade_record_id_today(ftr.trade_record_id, ftr.date_id) && :reportd_trade_record then 'skip'
      else 'to_report'
      end
      /*,
                 coalesce(ftr.street_account_name, '') as street_account_name*/
      FROM genesis2.trade_record ftr
               JOIN genesis2.account acc ON (acc.account_id = ftr.account_id AND
                                             acc.is_deleted <> 'Y' AND
                                             acc.opt_report_to_mpid = 'MLCB' AND
                                             acc.trading_firm_id <> 'cantor')
               LEFT JOIN genesis2.clearing_instruction_entry cie
                         ON (cie.date_id = ftr.date_id AND
                             COALESCE(cie.new_trade_record_id, cie.trade_record_id) =
                             ftr.trade_record_id AND cie.cmta IS NOT NULL)
               LEFT JOIN genesis2.clearing_instruction ci
                         ON (ci.clearing_instr_id =
                             cie.clearing_instr_entry_id AND ci.status = 'D' AND
                             ci.is_deleted <> 'Y')
      WHERE ftr.date_id between :in_start_date_id and :in_end_date_id
        AND is_busted = 'N'
        AND ftr.order_id > 0
--         and ftr.exec_broker = :in_exec_broker
--         AND NOT EXISTS (SELECT NULL
--                         FROM genesis2.alloc_instr2trade_record t
--                         WHERE date_id between :in_start_date_id and :in_end_date_id
--                           AND t.trade_record_id = ftr.trade_record_id)
          --and t.is_active


      ) l
GROUP BY l.date_id, l.cmta, l.open_close, l.order_id, l.instrument_id, l.side,
         l.opt_is_fix_clfirm_processed, l.opt_customer_or_firm,
         l.opt_nickel_commission, l.opt_penny_commission,
         l.opt_is_fix_custfirm_processed



   select array_agg(alloc_instr_id)
--     into l_alloc_instr_id_reported
    from dash360.bofa_allocation_report
    where date_id between :in_start_date_id and :in_end_date_id
    and to_report = 'report';



create function trash.so_allocation_second_part(in_start_date_id integer, in_end_date_id integer,
                                          in_exec_broker text default '792'::text)
returns int4
language plpgsql
as $fx$
declare
l_alloc_instr_id_reported int4[];
    begin
    -- 0. list of reported alloc_instr_id
    select array_agg(alloc_instr_id)
    into l_alloc_instr_id_reported
    from dash360.bofa_allocation_report
    where date_id between in_start_date_id and in_end_date_id
    and to_report = 'report';

    -- 0. create a list of trade records from reported alloc_instr_id
create temp table t_trade_record_reported as
select tr.trade_record_id, tr.date_id, aitr.alloc_instr_id from genesis2.trade_record tr
join genesis2.alloc_instr2trade_record aitr on tr.trade_record_id = aitr.trade_record_id and aitr.date_id = tr.date_id
where aitr.alloc_instr_id = any(l_alloc_instr_id_reported);

    -- 0. find all trade_records that itself or its origs were in reported list

    -- 0. find all valid trade_records: all except the records from the prev





end;

    $fx$