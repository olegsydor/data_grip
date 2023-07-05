drop function if exists trash.report_routing_table_usage;
create function trash.report_routing_table_usage(in_date_id int4 default null)
    returns table
            (
                export_row text
            )
    language plpgsql
as
$fx$
declare

begin
    return query
        select 'routing_table_id|routing_table_name|routing_table_desc|instrument_type|target_strategy|fee_sensitivity|routing_table_scope|account_class|capacity_group|routing_table_type|instrument_class|symbol_list|symbol|symbol_sfx|account_id|account_name|last_routed_time';

    return query
        select coalesce(routing_table_id::text, '') || '|' ||
               coalesce(routing_table_name, '') || '|' ||
               coalesce(routing_table_desc, '') || '|' ||
               coalesce(instrument_type, '') || '|' ||
               coalesce(target_strategy, '') || '|' ||
               coalesce(fee_sensitivity::text, '') || '|' ||
               coalesce(routing_table_scope, '') || '|' ||
               coalesce(account_class, '') || '|' ||
               coalesce(capacity_group, '') || '|' ||
               coalesce(routing_table_type, '') || '|' ||
               coalesce(instrument_class, '') || '|' ||
               coalesce(symbol_list, '') || '|' ||
               coalesce(symbol, '') || '|' ||
               coalesce(symbol_sfx, '') || '|' ||
               coalesce(account_id::text, '') || '|' ||
               coalesce(account_name, '') || '|' ||
               coalesce(to_char(last_routed_time, 'YYYY-MM-DD HH24:MI:SS.US'), '')
        from (select rt.routing_table_id                   as routing_table_id,
                     rt.routing_table_name                 as routing_table_name,
                     rt.routing_table_desc                 as routing_table_desc,
                     case
                         when rt.instrument_type_id = 'O' then 'Option'
                         when rt.instrument_type_id = 'E' then 'Equity'
                         when rt.instrument_type_id = 'M' then 'Multileg'
                         else rt.instrument_type_id end    as instrument_type,
                     ts.target_strategy_name               as target_strategy,
                     rt.fee_sensitivity                    as fee_sensitivity,
                     case
                         when rt.intended_scope_of_use = 'D' then 'Default'
                         when rt.intended_scope_of_use = 'A' then 'Account-specific'
                         when rt.intended_scope_of_use = 'T' then 'Trading firm-specific'
                         else rt.intended_scope_of_use end as routing_table_scope,
                     dac.account_class_name                as account_class,
                     dag.capacity_group_name               as capacity_group,
                     case
                         when rt.routing_table_type = 'C' then 'Instrument Class'
                         when rt.routing_table_type = 'T' then 'Global'
                         when rt.routing_table_type = 'S' then 'Symbol'
                         when rt.routing_table_type = 'L' then 'Symbol List'
                         else rt.routing_table_type end    as routing_table_type,
                     case
                         when rt.instr_class_id = 'NN' then 'Nickel Non-Premium'
                         when rt.instr_class_id = 'NP' then 'Nickel Premium'
                         when rt.instr_class_id = 'PN' then 'Penny Non-Premium'
                         when rt.instr_class_id = 'PP' then 'Penny Premium'
                         else rt.instr_class_id end        as instrument_class,
                     rt.symbol_list_id                     as symbol_list,
                     rt.root_symbol                        as symbol,
                     rt.symbol_suffix                      as symbol_sfx,
                     rta.account_id                        as account_id,
                     da.account_name                       as account_name,
                     rta.last_routed_time
              from dwh.d_routing_table rt
                       left join lateral (select co.account_id,
                                                 co.routing_table_id,
                                                 co.last_routed_time
                                          from trash.so_routing_max_time_usage co
                                          where co.routing_table_id = rt.routing_table_id
                                          limit 1
                  ) rta on true
                       left join dwh.d_account da on da.account_id = rta.account_id
                       left join dwh.d_account_class dac on da.account_class_id = dac.account_class_id
                       left join dwh.d_capacity_group dag
                                 on dag.capacity_group_id = rt.capacity_group_id
                       left outer join dwh.d_target_strategy ts on ts.target_strategy_id = rt.target_strategy
              where rt.is_active) x;
end;
$fx$;