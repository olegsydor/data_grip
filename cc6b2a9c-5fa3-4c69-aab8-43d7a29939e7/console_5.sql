with flt as (select pv.*
             from OSR_PARAM_DICTIONARY pd,
                  OSR_PARAM_VALUE pv
             where pd.osr_param_code = pv.osr_param_code
               and pd.osr_param_scope <> 'E'
             union all
             select pv.*
             from OSR_PARAM_DICTIONARY pd,
                  OSR_PARAM_VALUE pv,
                  ROUTING_TABLE_ENTRY rte
             where pd.osr_param_code = pv.osr_param_code
               and pd.osr_param_scope = 'E'
               and rte.osr_param_set_id = pv.osr_param_set_id
               and rte.is_deleted <> 'Y')
, ospv as (
select distinct osr_param_value AS ParamValue, 'B' AS paramtype
              from osr_bool_param_value
where OSR_PARAM_VALUE_ID in (select osr_param_value_id from flt)
              union all
              select distinct osr_param_value AS ParamValue, 'E' AS paramtype
              FROM osr_enum_param_value
              where OSR_PARAM_VALUE_ID in (select osr_param_value_id from flt)
              union all
              select distinct to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
              FROm osr_int_param_value
              where OSR_PARAM_VALUE_ID in (select osr_param_value_id from flt)
              union all
              select to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
              FROM osr_float_param_value
              where OSR_PARAM_VALUE_ID in (select osr_param_value_id from flt)
              union all
              select osr_param_value AS ParamValue, 'S' AS paramtype
              FROM osr_string_param_value
    where OSR_PARAM_VALUE_ID in (select osr_param_value_id from flt)
    )

 select acc.ACCOUNT_ID       as     AccountID,
        opv.OSR_PARAM_SET_ID as     "PARAMSETID",
        opv.OSR_PARAM_CODE   as     "PARAMCODE",
        p."PARAMVALUE"       as     "PARAMVALUE",
        p."PARAMTYPE"        as     "PARAMTYPE",
        sc2p.risk_mgmt_config_scope Scope
from ACCOUNT acc
         join RISK_MGMT_ACC2OSR_PARAM_SET acc2ps on acc.ACCOUNT_ID = acc2ps.account_id
         INNER JOIN OSR_PARAM_SET OPS on OPS.osr_param_set_id = acc2ps.OSR_PARAM_SET_ID and OPS.IS_DELETED <> 'Y'
         join ospv on ospv.paramvalue =
         join RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
              on opv.OSR_PARAM_CODE = sc2p.osr_param_code and
                 sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope and
                 sc2p.risk_mgmt_config_scope in ('A', 'B')
WHERE ACC.IS_DELETED <> 'Y';


  with ospv as (select distinct OSR_PARAM_VALUE_ID as osr_param_value_id, osr_param_value AS ParamValue, 'B' AS paramtype
              from osr_bool_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'E' AS paramtype
              FROM osr_enum_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
              FROm osr_int_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
              FROM osr_float_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'S' AS paramtype
              FROM osr_string_param_value)
select acc.ACCOUNT_ID       as     AccountID,
       opv.OSR_PARAM_SET_ID as     "PARAMSETID",
       opv.OSR_PARAM_CODE   as     "PARAMCODE",
       p."PARAMVALUE"       as     "PARAMVALUE",
       p."PARAMTYPE"        as     "PARAMTYPE",
       sc2p.risk_mgmt_config_scope Scope
from ACCOUNT acc
         join RISK_MGMT_ACC2OSR_PARAM_SET acc2ps on acc.ACCOUNT_ID = acc2ps.account_id
         INNER JOIN OSR_PARAM_SET OPS on OPS.osr_param_set_id = acc2ps.OSR_PARAM_SET_ID and OPS.IS_DELETED <> 'Y'
         join (select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.osr_param_value_id
               from OSR_PARAM_DICTIONARY pd
                        join OSR_PARAM_VALUE pv
                             on (pd.osr_param_code = pv.osr_param_code
                                 and pd.osr_param_scope <> 'E')
               union
               select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.OSR_PARAM_VALUE_ID
               from OSR_PARAM_DICTIONARY pd
                        join OSR_PARAM_VALUE pv on (pd.osr_param_code = pv.osr_param_code and pd.osr_param_scope = 'E')
               ) opv
              on opv.OSR_PARAM_SET_ID = acc2ps.osr_param_set_id
         join ospv p on OPV.osr_param_value_id = p.osr_param_value_id
         join RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
              on opv.OSR_PARAM_CODE = sc2p.osr_param_code and
                 sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope and
                 sc2p.risk_mgmt_config_scope in ('A', 'B')
WHERE ACC.IS_DELETED <> 'Y';



-------------------------------------------------------------------------
  with ospv as (select row_number() over (partition by OSR_PARAM_VALUE order by OSR_PARAM_VALUE_ID) as rn, OSR_PARAM_VALUE_ID as osr_param_value_id, osr_param_value AS ParamValue, 'B' AS paramtype
              from osr_bool_param_value
              union all
              select  row_number() over (partition by OSR_PARAM_VALUE order by OSR_PARAM_VALUE_ID) as rn, OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'E' AS paramtype
              FROM osr_enum_param_value
              union all
              select  row_number() over (partition by OSR_PARAM_VALUE order by OSR_PARAM_VALUE_ID) as rn, OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
              FROm osr_int_param_value
              union all
              select  row_number() over (partition by OSR_PARAM_VALUE order by OSR_PARAM_VALUE_ID) as rn, OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
              FROM osr_float_param_value
              union all
              select  row_number() over (partition by OSR_PARAM_VALUE order by OSR_PARAM_VALUE_ID) as rn, OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'S' AS paramtype
              FROM osr_string_param_value)
select acc.ACCOUNT_ID       as     AccountID,
       opv.OSR_PARAM_SET_ID as     "PARAMSETID",
       opv.OSR_PARAM_CODE   as     "PARAMCODE",
       p."PARAMVALUE"       as     "PARAMVALUE",
       p."PARAMTYPE"        as     "PARAMTYPE",
       sc2p.risk_mgmt_config_scope Scope
from ACCOUNT acc
         join RISK_MGMT_ACC2OSR_PARAM_SET acc2ps on acc.ACCOUNT_ID = acc2ps.account_id
         INNER JOIN OSR_PARAM_SET OPS on OPS.osr_param_set_id = acc2ps.OSR_PARAM_SET_ID and OPS.IS_DELETED <> 'Y'
         join (select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.osr_param_value_id
               from OSR_PARAM_DICTIONARY pd
                        join OSR_PARAM_VALUE pv
                             on (pd.osr_param_code = pv.osr_param_code
                                 and pd.osr_param_scope <> 'E')
               union
               select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.OSR_PARAM_VALUE_ID
               from OSR_PARAM_DICTIONARY pd
                        join OSR_PARAM_VALUE pv on (pd.osr_param_code = pv.osr_param_code and pd.osr_param_scope = 'E')
               ) opv
              on opv.OSR_PARAM_SET_ID = acc2ps.osr_param_set_id
         join ospv p on OPV.osr_param_value_id = p.osr_param_value_id and p.rn = 1
         join RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
              on opv.OSR_PARAM_CODE = sc2p.osr_param_code and
                 sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope and
                 sc2p.risk_mgmt_config_scope in ('A', 'B')
WHERE ACC.IS_DELETED <> 'Y';

insert into so_test_perf (AccountID, PARAMSETID, PARAMCODE, PARAMVALUE, PARAMTYPE, Scope, knd)
with ospv as (select distinct OSR_PARAM_VALUE_ID as osr_param_value_id, osr_param_value AS ParamValue, 'B' AS paramtype
              from osr_bool_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'E' AS paramtype
              FROM osr_enum_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
              FROm osr_int_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
              FROM osr_float_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'S' AS paramtype
              FROM osr_string_param_value)
-- select
-- acc.AccountID,
-- p."PARAMSETID",p."PARAMCODE",p."PARAMVALUE",p."PARAMTYPE",
-- sc2p.risk_mgmt_config_scope Scope
-- from
-- ATLAS_ACCOUNT_INFO_V2 acc,
-- RISK_MGMT_ACC2OSR_PARAM_SET acc2ps,
-- ATLAS_PARAMETERS p,
-- RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
-- where acc.AccountID = acc2ps.account_id
-- and acc2ps.osr_param_set_id = p.ParamSetID
-- and p.ParamCode = sc2p.osr_param_code
-- and sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope
-- and (sc2p.risk_mgmt_config_scope = 'A' or sc2p.risk_mgmt_config_scope = 'B')
-- minus

select DISTINCT acc.ACCOUNT_ID       as     AccountID,
                opv.OSR_PARAM_SET_ID as     "PARAMSETID",
                opv.OSR_PARAM_CODE   as     "PARAMCODE",
                p."PARAMVALUE"       as     "PARAMVALUE",
                p."PARAMTYPE"        as     "PARAMTYPE",
                sc2p.risk_mgmt_config_scope Scope,
                'new'                as     knd
from ACCOUNT acc
         join RISK_MGMT_ACC2OSR_PARAM_SET acc2ps on acc.ACCOUNT_ID = acc2ps.account_id
         INNER JOIN OSR_PARAM_SET OPS on OPS.osr_param_set_id = acc2ps.OSR_PARAM_SET_ID and OPS.IS_DELETED <> 'Y'
         join (select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.osr_param_value_id
               from OSR_PARAM_DICTIONARY pd
                        join OSR_PARAM_VALUE pv
                             on (pd.osr_param_code = pv.osr_param_code
                                 and pd.osr_param_scope <> 'E')
               union
               select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.OSR_PARAM_VALUE_ID
               from OSR_PARAM_DICTIONARY pd,
                    OSR_PARAM_VALUE pv,
                    ROUTING_TABLE_ENTRY rte
               where pd.osr_param_code = pv.osr_param_code
                 and pd.osr_param_scope = 'E'
                 and rte.osr_param_set_id = pv.osr_param_set_id
                 and rte.is_deleted <> 'Y') opv
              on opv.OSR_PARAM_SET_ID = acc2ps.osr_param_set_id
         join ospv p on OPV.osr_param_value_id = p.osr_param_value_id
         join RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
              on opv.OSR_PARAM_CODE = sc2p.osr_param_code and
                 sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope and
                 sc2p.risk_mgmt_config_scope in ('A', 'B')
WHERE ACC.IS_DELETED <> 'Y';
minus
create table so_test_perf as
  select
acc.AccountID,
p."PARAMSETID",p."PARAMCODE",p."PARAMVALUE",p."PARAMTYPE",
sc2p.risk_mgmt_config_scope Scope, 'old' as knd
from
ATLAS_ACCOUNT_INFO_V2 acc,
RISK_MGMT_ACC2OSR_PARAM_SET acc2ps,
ATLAS_PARAMETERS p,
RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
where acc.AccountID = acc2ps.account_id
and acc2ps.osr_param_set_id = p.ParamSetID
and p.ParamCode = sc2p.osr_param_code
and sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope
and (sc2p.risk_mgmt_config_scope = 'A' or sc2p.risk_mgmt_config_scope = 'B');


select AccountID, PARAMSETID, PARAMCODE, PARAMVALUE, PARAMTYPE, Scope
from so_test_perf
where knd = 'new'
minus
select AccountID, PARAMSETID, PARAMCODE, PARAMVALUE, PARAMTYPE, Scope
from so_test_perf
where knd = 'old'
minus
select AccountID, PARAMSETID, PARAMCODE, PARAMVALUE, PARAMTYPE, Scope
from so_test_perf
where knd = 'new'

select count(*)
from so_test_perf
where knd = 'new'
union all
select count(*)
from so_test_perf
where knd = 'old'