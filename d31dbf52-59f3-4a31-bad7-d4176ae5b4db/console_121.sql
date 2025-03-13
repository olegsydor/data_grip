CREATE FUNCTION trash.report_compliance_parent_orders(trading_firm_ids character varying[] DEFAULT '{}'::character varying[],
                                                      account_ids bigint[] DEFAULT '{}'::bigint[],
                                                      start_date_id integer DEFAULT NULL::integer,
                                                      end_date_id integer DEFAULT NULL::integer,
                                                      p_client_id character varying DEFAULT NULL::character varying,
                                                      p_mode character DEFAULT 'A'::character(1))
    RETURNS TABLE
            (
                trading_firm_name     character varying,
                account_name          character varying,
                routed_time           timestamp without time zone,
                event_time            timestamp without time zone,
                order_status          character varying,
                client_order_id       character varying,
                free_text             character varying,
                orig_client_order_id  character varying,
                ex_destination        character varying,
                instrument_type_id    character,
                symbol                character varying,
                customer_or_firm_name character varying,
                display_instrument_id character varying,
                last_trade_date       timestamp without time zone,
                side                  character,
                order_qty             integer,
                exec_qty              bigint,
                avg_px                numeric,
                price                 numeric,
                leaves_qty            bigint,
                exchange_id           character varying,
                sub_strategy          character varying,
                time_in_force         character varying,
                order_type            character varying,
                clearing_firm_id      character varying,
                max_floor             bigint,
                open_close            character,
                client_id             character varying,
                root_symbol           character varying,
                is_mleg               character,
                is_cross              character,
                max_show_qty          integer,
                market_participant_id character varying,
                create_time           timestamp without time zone,
                event_type            character varying,
                opt_exec_broker       character varying,
                exec_instruction      character varying,
                expire_time           timestamp without time zone,
                fee_sensitivity       integer,
                handle_inst           character varying,
                leg_id                character varying,
                locate_broker         character varying,
                occ_optional_data     character varying,
                order_capacty         character varying,
                osi_symbol            character varying,
                internal_order_id     bigint,
                stop_price            numeric
            )
    LANGUAGE plpgsql
    COST 1
    SET enable_material TO 'false'
    SET random_page_cost TO '1'
AS
$function$
    -- 2024-09-07 OS https://dashfinancial.atlassian.net/browse/DS-7719 text_ -> exec_text
-- 2024-10-22 MB: https://dashfinancial.atlassian.net/browse/DS-9027 rename is_acitive to is_active in d_ex_destination_code
DECLARE
    select_stmt text;
    sql_params  text;
begin

    raise info '%: %',clock_timestamp(), 'Started';

    return query
        create table trash.so_parent_order_marketable as
        select tf.trading_firm_name,
               acc.account_name,
               co.process_time                                                               as routed_time,
               ex.exec_time                                                                  as event_time,
               ex.order_status,
               co.client_order_id,
               ex.exec_text                                                                  as free_text,
               oco.client_order_id                                                           as orig_client_order_id,
               edc.ex_destination_code_name                                                  as ex_destination,
               i.instrument_type_id,
               i.symbol,
               cf.customer_or_firm_name,
               i.display_instrument_id,
               i.last_trade_date,
               co.side,
               co.order_qty,
               --ex.cum_qty as exec_qty::int8,
               --ex.avg_px,
               (case when ex.cum_qty = 0 then null else ex.cum_qty end)::int8                as exec_qty,
               (case when ex.avg_px = 0 then null else ex.avg_px end)::numeric               as avg_px,
               co.price,
               ex.leaves_qty::int8,
               co.exchange_id,
               co.sub_strategy_desc                                                          as sub_strategy,
               tif.tif_name                                                                  as time_in_force,
               ot.order_type_name                                                            as order_type,
               fc.fix_comp_id                                                                as clearing_firm_id,
               co.max_floor,
               co.open_close,
               co.client_id_text                                                             as client_id,
               oss.root_symbol                                                               as root_symbol,
               (case when co.multileg_reporting_type = '1' then 'N' else 'Y' end)::character as is_mleg,
               (case when co.cross_order_id is null then 'N' else 'Y' end)::character        as is_cross,
               co.max_show_qty,
               co.market_participant_id,
               co.create_time,
               ex.exec_type                                                                  as event_type,
               --co.opt_exec_broker_id,
               null::varchar                                                                 as opt_exec_broker,
               co.exec_instruction,
               co.expire_time,
               co.fee_sensitivity::integer,
               co.handl_inst::varchar,
               co.co_client_leg_ref_id                                                       as leg_id,
               null::varchar                                                                 as locate_broker,
               co.occ_optional_data,
               ocp.order_capacity_name                                                       as order_capacity,
               oct.opra_symbol                                                               as osi_symbol,
               co.internal_order_id,
               co.stop_price
        from client_order co
                 left join d_ex_destination_code edc
                           on edc.is_active = true and edc.ex_destination_code = co.ex_destination
                 inner join d_account acc on acc.account_id = co.account_id and acc.is_active
                 left join d_fix_connection fc ON fc.fix_connection_id = co.fix_connection_id
                 inner join d_trading_firm tf on tf.trading_firm_id = acc.trading_firm_id and tf.is_active
                 inner join d_instrument i on i.instrument_id = co.instrument_id /*and i.is_active*/
                 left join d_option_contract oct on oct.instrument_id = i.instrument_id /*and oct.is_active */
                 left join d_option_series oss on oss.option_series_id = oct.option_series_id
                 left join d_customer_or_firm cf on cf.customer_or_firm_id = co.customer_or_firm_id and cf.is_active
                 left join d_time_in_force tif on tif.tif_id = co.time_in_force_id and tif.is_active
                 left join d_order_type ot on ot.order_type_id = co.order_type_id
                 left join client_order oco on oco.order_id = co.orig_order_id
                 left join d_order_capacity ocp on ocp.order_capacity_id = co.eq_order_capacity
                 left join
             (select tr.order_id
                   , sum(tr.last_qty)                                           as exec_qty
                   , round(sum(tr.last_px * tr.last_qty) / sum(tr.last_qty), 4) as avg_px
              from dwh.flat_trade_record tr
              where tr.date_id between :start_date_id and :end_date_id
                and tr.is_busted = 'N'
                and tr.account_id > 0
              group by tr.order_id) trd on trd.order_id = co.order_id
                 left join lateral
            ( select ex.exec_text
                   , et.exec_type_description    as exec_type
                   , os.order_status_description as order_status
                   , ex.exec_id
                   , ex.leaves_qty
                   , ex.cum_qty
                   , ex.avg_px
                   , ex.exec_time
              from dwh.execution ex
                       left join d_exec_type et on et.exec_type = ex.exec_type
                       left join d_order_status os on os.order_status = ex.order_status
              where ex.exec_date_id between :start_date_id and :end_date_id
                and ex.order_id = co.order_id
              order by ex.exec_time desc, ex.cum_qty desc nulls last, ex.exec_id desc -- last execution definition
              limit 1
            ) ex on true
                 left join lateral
            ( select ex.exec_time
              from dwh.execution ex
              where ex.exec_date_id between :start_date_id and :end_date_id
                and ex.order_id = co.order_id
              order by ex.exec_time, ex.exec_id -- first execution definition
              limit 1
            ) fex on true
                 left join lateral (select *
                                    from dwh.l1_snapshot ls
                                    where ls.transaction_id = co.transaction_id
                                      and ls.exchange_id = 'NBBO'
                                      and ls.start_date_id = co.create_date_id
                                    limit 1) ls on true
        where co.create_date_id between :start_date_id and :end_date_id
          and co.parent_order_id is null
          and co.multileg_reporting_type in ('1', '2')
          and case
                  when :trading_firm_ids <> '{}' then tf.trading_firm_id = any (:trading_firm_ids)
                  else true end
          and case
                  when :account_ids <> '{}' then co.account_id = any (:account_ids)
                  else true end
          and case when :p_client_id is not null then upper(co.client_id_text) = upper(:p_client_id) else true end
          and case
                  when co.price is null then true
                  when ot.order_type_name = 'Market' then true
                  when co.side in ('1', '3') and co.price >= ls.ask_price then true
                  when co.side not in ('1', '3') and co.price <= ls.bid_price then true
                  else false
            end
        order by 1, 3, 2;

raise info '%: %',clock_timestamp(), select_stmt;


end;

$function$
;

select * from dwh.l1_snapshot;

select * from dwh.d_account
    where account_name in ('MIRARET', 'SAXORET', 'FUTCRET', 'MRSC', 'VLOX')
select to_char(round(:AVG_PX, 4), 'LFM99999990D9000')


select trading_firm_name                                   as "Trading Firm",
       account_name                                        as "Account",
       order_status                                        as "Order Status",
       to_char(event_time, 'MM/DD/YY')                     as "Event Date",
       to_char(routed_time, 'HH24:MI:SS.MS')               as "Routed Time",
       to_char(event_time, 'HH24:MI:SS.MS')                as "Event Time",

       client_order_id                                     as "Cl Ord ID",
       free_text                                           as "Free Text",
       orig_client_order_id                                as "Free Text",
       ex_destination                                      as "Ex Dest",
       case
           when instrument_type_id = 'E' then 'Equity'
           when instrument_type_id = 'O' then 'Option' end as "Security Type",
       symbol                                              as "Underlying Symbol",
       customer_or_firm_name                               as "Capacity",
       display_instrument_id                               as "Symbol",
       to_char(last_trade_date, 'MM/DD/YYYY')              as "Expiration Date",
       to_char(last_trade_date, 'HH24:MI:SS.MS')           as "Expiration Date",
       case
           when side in ('1', '3') then 'Buy'
           when side not in ('1', '3') then 'Sell' end     as "Side",
       order_qty                                           as "Ord Qty",
       exec_qty                                            as "Ex Qty",
       to_char(round(avg_px, 4), 'LFM99999990D9000')       as "Avg Px",
       to_char(round(price, 4), 'LFM99999990D9000')        as "Price",
       leaves_qty                                          as "Lvs Qty",
       exchange_id                                         as "Exchange ID",
       sub_strategy                                        as "Sub Strategy",
       time_in_force                                       as "TIF",
       order_type                                          as "Ord Type",
       clearing_firm_id                                    as "Sending Firm",
       max_floor                                           as "Max Floor",
       open_close                                          as "O/C",
       client_id                                           as "Client ID",
       root_symbol                                         as "Root Symbol",
       is_cross                                            as "Is Cross",
       is_mleg                                             as "Is MLeg",
       max_show_qty                                        as "Max Show Qty",
       market_participant_id                               as "MPID",
       to_char(create_time, 'MM/DD/YY')                    as "Creation Date",
       to_char(create_time, 'HH24:MI:SS.MS')               as "Creation Time",
       event_type                                          as "Event Type",
       opt_exec_broker                                     as "Exec Broker",
       exec_instruction                                    as "Exec Inst",
--        expire_time as "",
       fee_sensitivity                                     as "Fee Sensitivity",
       handl_inst                                          as "Handle Inst",
       leg_id                                              as "Leg ID",
       locate_broker                                       as "Locate Broker",
       occ_optional_data                                   as "OCC Opt Data",
       order_capacity                                      as "Ord Capacity",
       osi_symbol                                          as "OSI Symbol",
       to_char(internal_order_id, 'FM999,999,999,999,999') as "SOR Ord ID",
       stop_price                                          as "Stop Px"
from trash.so_parent_order_marketable
-- where account_name = 'MIRARET'
order by trading_firm_name, routed_time, account_name
limit 200000 offset 600000;

create index so_parent_order_marketable_etl_ids on trash.so_parent_order_marketable (trading_firm_name, routed_time, account_name)
