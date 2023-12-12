-- select jsonb_strip_nulls(
--                jsonb_build_object('key_wd', null,
--                                   'key_wt', null,
--                                   'key_def', null,
--                                   'key_ln', null
--                ))
-- from words.word;


select
    ops.osr_param_set_id,
    min(ops.osr_param_set_desc),
    min(is_deleted),
    min(create_time),
    min(delete_time),
    jsonb_object_agg(osr_param_code, coalesce(osr_enum_member_name, pst_osr_param_value, pfl_osr_param_value::text, pint_osr_param_value::text, pbool_osr_param_value)) as osr_param_values,
    operation,
    min(commit_time)
    from staging.v_flat_osr_param_set ops
group by ops.osr_param_set_id, operation;

select * from staging.V_FULL_OSR_PARAM_SET
where osr_param_set_id = 301;

select osr_param_set_id, operation,
       jsonb_object_agg(osr_param_code, coalesce(osr_enum_member_name, pst_osr_param_value, pfl_osr_param_value::text, pint_osr_param_value::text, pbool_osr_param_value)) || jsonb_build_object('fail', $$"$$)
from staging.V_FULL_OSR_PARAM_SET
where coalesce(osr_enum_member_name, pst_osr_param_value, pfl_osr_param_value::text, pint_osr_param_value::text, pbool_osr_param_value) is not null
group by osr_param_set_id, operation
limit 10;
/*
oemd.OSR_ENUM_MEMBER_NAME is null then null else vl.OSR_PARAM_CODE||'\":\"'||oemd.OSR_ENUM_MEMBER_NAME end,
case when pst.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||pst.OSR_PARAM_VALUE end)  ,
case when pfl.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||to_char(pfl.OSR_PARAM_VALUE) end),
case when pint.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||to_char(pint.OSR_PARAM_VALUE) end) ,
case when pbool.OSR_PARAM_VALUE is null then null else vl.OSR_PARAM_CODE||'\":\"'||pbool.OSR_PARAM_VALUE end), '\",\"')
 */

