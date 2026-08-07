select case
           when is_deleted = 'N'
               then 'ON'::varchar
           else 'OFF'::varchar
           end                                                                                                   as is_deleted,
       osr_param_name,
       paramtype::varchar,
       case paramtype
           when 'B'
               then case paramvalue
                        when 'Y' then 'Yes'
                        when 'N' then 'No'
                        else paramvalue
               end
           when 'E'
               then osr_enum_member_name
           else paramvalue
           end                                                                                                   as paramvalue,
       osr_param_desc,
       default_behavior,
       ('Min: ' || coalesce(min_value::text, 'null') || '  Max: ' ||
        coalesce(max_value::text, 'null'))::varchar                                                              as allowed_values,
       case instrument_type_id
           when 'E' then ts.target_strategy_desc || ' EQUITY'
           when 'O' then ts.target_strategy_desc || ' OPTION'
           when 'M' then ts.target_strategy_desc || ' MULTILEG'
           else ALGO_WIZARD_FOR_EXPORT.TARGET_STRATEGY::varchar
           end                                                                                                   as report_name,
       TRADING_FIRM_ID,
       TRADING_FIRM_NAME,
       ACCOUNT_NAME,
       TRADER_ID
from staging.ALGO_WIZARD_FOR_EXPORT
         left join dwh.d_target_strategy ts on ALGO_WIZARD_FOR_EXPORT.TARGET_STRATEGY = ts.target_strategy_id
where is_deleted = 'N'
--   and account_id is not null
  and trading_firm_id = any('{casey01}')


select * from dash360.export_algo_wizard_data(in_trading_firm_ids := array['casey01'], in_algoparamscope := 'F');

create temp table t_os as select * from dash360.export_algo_wizard_data();

select * from t_os
where trading_firm_id is not null