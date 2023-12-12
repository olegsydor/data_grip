SELECT ParamSetID, ParamCode, ParamValue, ParamType
FROM (
   SELECT OPV.osr_param_set_id AS ParamSetID, OPV.osr_param_code AS ParamCode, OBPV.osr_param_value AS ParamValue, 'B' AS paramtype
   FROM OSR_PARAM_VALUE_FILTERED opv
   INNER JOIN osr_bool_param_value obpv on OPV.osr_param_value_id=OBPV.osr_param_value_id
   UNION (
      SELECT OPV.osr_param_set_id AS ParamSetID, OPV.osr_param_code AS ParamCode, OEPV.osr_param_value AS ParamValue, 'E' AS paramtype
      FROM OSR_PARAM_VALUE_FILTERED OPV
      INNER JOIN osr_enum_param_value OEPV on OPV.osr_param_value_id=OEPV.osr_param_value_id
   )
   UNION (
      SELECT OPV.osr_param_set_id AS ParamSetID, OPV.osr_param_code AS ParamCode, to_char(OIPV.osr_param_value) AS ParamValue, 'I' AS paramtype
      FROM OSR_PARAM_VALUE_FILTERED OPV
      INNER JOIN osr_int_param_value OIPV on OPV.osr_param_value_id=OIPV.osr_param_value_id
   )
   UNION (
      SELECT OPV.osr_param_set_id AS ParamSetID, OPV.osr_param_code AS ParamCode, to_char(OFPV.osr_param_value) AS ParamValue, 'F' AS paramtype
      FROM OSR_PARAM_VALUE_FILTERED OPV
      INNER JOIN osr_float_param_value OFPV on OPV.osr_param_value_id=OFPV.osr_param_value_id
   )
   UNION (
      SELECT OPV.osr_param_set_id AS ParamSetID, OPV.osr_param_code AS ParamCode, OSPV.osr_param_value AS ParamValue, 'S' AS paramtype
      FROM OSR_PARAM_VALUE_FILTERED OPV
      INNER JOIN osr_string_param_value OSPV on OPV.osr_param_value_id=OSPV.osr_param_value_id
   )
) PP
INNER JOIN OSR_PARAM_SET OPS on PP.ParamSetID = OPS.osr_param_set_id
WHERE OPS.IS_DELETED <> 'Y'

select osr_param_value AS ParamValue, 'B' AS paramtype
from osr_bool_param_value
union
select osr_param_value AS ParamValue, 'E' AS paramtype
FROM osr_enum_param_value
union
select to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
FROm osr_int_param_value
union
select to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
FROM osr_float_param_value
union
select osr_param_value AS ParamValue, 'S' AS paramtype
FROM osr_string_param_value;

select distinct osr_param_value AS ParamValue, 'B' AS paramtype
from osr_bool_param_value
union all
select distinct osr_param_value AS ParamValue, 'E' AS paramtype
FROM osr_enum_param_value
union all
select distinct to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
FROm osr_int_param_value
union all
select distinct to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
FROM osr_float_param_value
union all
select distinct osr_param_value AS ParamValue, 'S' AS paramtype
FROM osr_string_param_value
;
SELECT count(*) FROM ATLAS_RME_ACC_PARAMETERS;

create or replace view staging.so_ATLAS_RME_ACC_PARAMETERS_2 as
with ospv as (select distinct OSR_PARAM_VALUE_ID as osr_param_value_id, osr_param_value AS ParamValue, 'B' AS paramtype
              from genesis2.osr_bool_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'E' AS paramtype
              FROM genesis2.osr_enum_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
              FROm genesis2.osr_int_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
              FROM genesis2.osr_float_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'S' AS paramtype
              FROM genesis2.osr_string_param_value)
select acc.ACCOUNT_ID       as     AccountID,
       opv.OSR_PARAM_SET_ID as     "PARAMSETID",
       opv.OSR_PARAM_CODE   as     "PARAMCODE",
       p."PARAMVALUE"       as     "PARAMVALUE",
       p."PARAMTYPE"        as     "PARAMTYPE",
       sc2p.risk_mgmt_config_scope Scope
from genesis2.ACCOUNT acc -- table
         join genesis2.RISK_MGMT_ACC2OSR_PARAM_SET acc2ps on acc.ACCOUNT_ID = acc2ps.account_id -- table
         INNER JOIN genesis2.OSR_PARAM_SET OPS on OPS.osr_param_set_id = acc2ps.OSR_PARAM_SET_ID and OPS.IS_DELETED <> 'Y'
         join (select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.osr_param_value_id
               from genesis2.OSR_PARAM_DICTIONARY pd
                        join genesis2.OSR_PARAM_VALUE pv
                             on (pd.osr_param_code = pv.osr_param_code
                                 and pd.osr_param_scope <> 'E')
               union
               select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.OSR_PARAM_VALUE_ID
               from genesis2.OSR_PARAM_DICTIONARY pd
                        join genesis2.OSR_PARAM_VALUE pv on (pd.osr_param_code = pv.osr_param_code and pd.osr_param_scope = 'E')
--                         join genesis2.ROUTING_TABLE_ENTRY rte  on (rte.osr_param_set_id = pv.osr_param_set_id and rte.is_deleted <> 'Y')
               ) opv
              on opv.OSR_PARAM_SET_ID = acc2ps.osr_param_set_id
         join ospv p on OPV.osr_param_value_id = p.osr_param_value_id
         join genesis2.RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
              on opv.OSR_PARAM_CODE = sc2p.osr_param_code and
                 sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope and
                 sc2p.risk_mgmt_config_scope in ('A', 'B')
WHERE ACC.IS_DELETED <> 'Y';


select * from staging.so_ATLAS_RME_ACC_PARAMETERS
minus
select * from staging.so_ATLAS_RME_ACC_PARAMETERS_2
                ORDER BY "AccountID", "Scope"
minus
select * from staging.so_ATLAS_RME_ACC_PARAMETERS
                ORDER BY "AccountID", "Scope"


SELECT * FROM ATLAS_RME_ACC_PARAMETERS ORDER BY AccountID, Scope

    select * from ATLAS_RME_ACC_PARAMETERS;


SELECT * FROM ATLAS_RME_ACC_PARAMETERS ORDER BY AccountID, Scope


create or replace view ATLAS_RME_ACC_PARAMETERS as
with ospv as (select distinct OSR_PARAM_VALUE_ID as osr_param_value_id, osr_param_value AS ParamValue, 'B' AS paramtype
              from genesis2.osr_bool_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'E' AS paramtype
              FROM genesis2.osr_enum_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'I' AS paramtype
              FROm genesis2.osr_int_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, to_char(osr_param_value) AS ParamValue, 'F' AS paramtype
              FROM genesis2.osr_float_param_value
              union all
              select distinct OSR_PARAM_VALUE_ID, osr_param_value AS ParamValue, 'S' AS paramtype
              FROM genesis2.osr_string_param_value)
select acc.ACCOUNT_ID       as     AccountID,
       opv.OSR_PARAM_SET_ID as     "PARAMSETID",
       opv.OSR_PARAM_CODE   as     "PARAMCODE",
       p."PARAMVALUE"       as     "PARAMVALUE",
       p."PARAMTYPE"        as     "PARAMTYPE",
       sc2p.risk_mgmt_config_scope Scope
from genesis2.ACCOUNT acc -- table
         join genesis2.RISK_MGMT_ACC2OSR_PARAM_SET acc2ps on acc.ACCOUNT_ID = acc2ps.account_id -- table
         INNER JOIN genesis2.OSR_PARAM_SET OPS on OPS.osr_param_set_id = acc2ps.OSR_PARAM_SET_ID and OPS.IS_DELETED <> 'Y'
         join (select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.osr_param_value_id
               from genesis2.OSR_PARAM_DICTIONARY pd
                        join genesis2.OSR_PARAM_VALUE pv
                             on (pd.osr_param_code = pv.osr_param_code
                                 and pd.osr_param_scope <> 'E')
               union
               select pv.OSR_PARAM_CODE, pv.OSR_PARAM_SET_ID, pv.OSR_PARAM_VALUE_ID
               from genesis2.OSR_PARAM_DICTIONARY pd
                        join genesis2.OSR_PARAM_VALUE pv on (pd.osr_param_code = pv.osr_param_code and pd.osr_param_scope = 'E')
--                         join genesis2.ROUTING_TABLE_ENTRY rte  on (rte.osr_param_set_id = pv.osr_param_set_id and rte.is_deleted <> 'Y')
               ) opv
              on opv.OSR_PARAM_SET_ID = acc2ps.osr_param_set_id
         join ospv p on OPV.osr_param_value_id = p.osr_param_value_id
         join genesis2.RISK_MGMT_CONF_SCOPE2OSR_PARAM sc2p
              on opv.OSR_PARAM_CODE = sc2p.osr_param_code and
                 sc2p.risk_mgmt_config_scope = acc2ps.risk_mgmt_conf_scope and
                 sc2p.risk_mgmt_config_scope in ('A', 'B')
WHERE ACC.IS_DELETED <> 'Y';
