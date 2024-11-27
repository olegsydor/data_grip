select cl_exchange_id,
       ex_exchange_id,
       str_t9730,
--        substr(str_t9730, 2, 1) as counterparty_range_for_saphire,
       par_t9730,
       counterparty_range,
           case
               when tbs.ex_exec_type = 'F' then
                   case
                       when tbs.par_order_id is not null then tbs.ex_contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
from dash_reporting.imc_final x
where true
  and ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%'])
  and cl_exchange_id is null


select
               case
               when tbs.ex_exec_type = 'F' then
                   case
--                        when tbs.ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%']) then substr(coalesce(str_t9730, par_t9730), 2, 1)
                       when tbs.ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%']) then substr(str_t9730, 2, 1)
                       when tbs.par_order_id is not null then tbs.ex_contra_account_capacity
                       else tbs.es_contra_account_capacity
                       end
               end                                                                                     as COUNTERPARTY_RANGE,
*
from dash_reporting.imc_base_ext_md tbs
where true
and tbs.ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%'])