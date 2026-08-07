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
where trading_firm_id is not null;




CREATE or replace FUNCTION trash.export_algo_wizard_data(in_algoparamscope character varying DEFAULT NULL::character varying, in_account_ids bigint[] DEFAULT '{}'::bigint[], in_trading_firm_ids character varying[] DEFAULT '{}'::character varying[], in_instrument_type_id character varying DEFAULT NULL::character varying, in_trader_internal_ids integer[] DEFAULT '{}'::integer[])
 RETURNS TABLE(is_deleted character varying, parameter character varying, type character varying, value character varying, description character varying, default_behavior character varying, allowed_values character varying, report_name character varying, trading_firm_id character varying, trading_firm_name character varying, account_name character varying, trader_id character varying)
 LANGUAGE plpgsql
AS $function$
-- SY 20210224: DS-2953 Support of more then 1000 account_ids in filter has been implemented
-- SY 20210224: DS-2956 Target_strategy_desc has been used instead of big case
-- MG 20210222: DS-2912 trading_firm_name added
-- MG 20210222: DS-2912 Added osr_enum_member_name handeling
-- SY 20210205: DS-2659 Added 'D' Logic
-- SY 20210205: DS-2725 Added account_id, trading_firm_id, trader_id as output
-- SY 20210108: DS-2725 account_name and trader_id used instead of account_id and trader_internal_id

declare

l_sql text;
l_sql_param text;

begin

if in_algoParamScope is not null
 then
		if in_algoParamScope = 'A'
		      then  case when  in_account_ids <> '{}'::bigint[]
		                 then if cardinality(in_account_ids) < 1000
		                 		 then l_sql_param:= ' and account_id = any($1) ';
		                       	 else create temp table tmp_acc_filter_list on commit drop as select unnest (in_account_ids) account_id;
		                               l_sql_param:=' and account_id in (select account_id from tmp_acc_filter_list)';
		                      end if;
					     else l_sql_param:=' and account_id is not null ';
					 end case;

		 elseif in_algoParamScope= 'F'
		      then l_sql_param:= case when in_trading_firm_ids <> '{}'::varchar[]
		      						  then ' and trading_firm_id = any($2)  '
		      						  else ' and trading_firm_id is not null'
								 end;
		 elseif in_algoParamScope= 'T'
		      then l_sql_param:= case when in_trader_internal_ids <> '{}'::int[]
		      						  then ' and trader_internal_id = any($4) '
		      						  else ' and trader_internal_id is not null'
		      					 end;
		 elseif in_algoParamScope = 'D'
		      then  l_sql_param:= ' and OSR_PARAM_SET_ID_OPS = OSR_PARAM_SET_ID_DPS ' ;
		 else  l_sql_param := '';
		end if;

		if in_instrument_type_id  is not null
		   then l_sql_param:=l_sql_param||' and instrument_type_id = $3';
		end if;


		l_sql :='select
					case when is_deleted =''N''
							then ''ON''::varchar
							else ''OFF''::varchar
					end as is_deleted,
				osr_param_name,
				paramtype::varchar,
				case paramtype when ''B''
							   then case paramvalue when ''Y'' then ''Yes''
													when ''N'' then ''No''
                                                    else paramvalue
                                     end
                               when ''E''
                               then osr_enum_member_name
                else paramvalue
                end as paramvalue,
				osr_param_desc,
				default_behavior,
				(''Min: ''||coalesce(min_value::text,''null'')||''  Max: '' ||coalesce(max_value::text,''null''))::varchar as allowed_values,
                    case instrument_type_id
                      when ''E'' then ts.target_strategy_desc||'' EQUITY''
                      when ''O'' then ts.target_strategy_desc||'' OPTION''
                      when ''M'' then ts.target_strategy_desc||'' MULTILEG''
                      else ALGO_WIZARD_FOR_EXPORT.TARGET_STRATEGY::varchar
					end  as report_name,
					TRADING_FIRM_ID,
                    TRADING_FIRM_NAME,
		 			ACCOUNT_NAME,
					TRADER_ID
					 from staging.ALGO_WIZARD_FOR_EXPORT
                        left join dwh.d_target_strategy ts on ALGO_WIZARD_FOR_EXPORT.TARGET_STRATEGY=ts.target_strategy_id
						where is_deleted =''N'' '||l_sql_param;

					RETURN QUERY
				execute l_sql using in_account_ids,in_trading_firm_ids,in_instrument_type_id,in_trader_internal_ids ;
				raise INFO ' % ', l_sql;

else

		if  in_account_ids = '{}'::bigint[] and  in_trading_firm_ids = '{}'::varchar[] and  in_trader_internal_ids = '{}'::int[]
		 then
		     raise notice 'in_algoparamscope - %', in_algoparamscope;
			 RETURN QUERY
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'A', in_instrument_type_id=>in_instrument_type_id)
			  union all
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'F', in_instrument_type_id=>in_instrument_type_id)
			  union all
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'T', in_instrument_type_id=>in_instrument_type_id)
			  union all
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'D', in_instrument_type_id=>in_instrument_type_id) ;
		else
			 RETURN QUERY
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'A', in_account_ids =>case in_account_ids when '{}'::bigint[]  then '{NULL}'::bigint[] else in_account_ids end, in_instrument_type_id=>in_instrument_type_id)
			  union all
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'F', in_trading_firm_ids => case in_trading_firm_ids when '{}'::varchar[]  then '{NULL}'::varchar[] else in_trading_firm_ids end, in_instrument_type_id=>in_instrument_type_id)
			  union all
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'T', in_trader_internal_ids => case in_trader_internal_ids when '{}'  then '{NULL}'::int[] else in_trader_internal_ids end, in_instrument_type_id=>in_instrument_type_id)
			  union all
			  select * from trash.export_algo_wizard_data(in_algoparamscope=>'D', in_instrument_type_id=>in_instrument_type_id) ;

		end if;
end if;
end;
$function$
;
