select cl_exchange_id,
       ex_exchange_id,
       str_t9730,
--        substr(str_t9730, 2, 1) as counterparty_range_for_saphire,
       par_t9730,
       counterparty_range,
       *
from dash_reporting.imc_final x
where true
  and ex_exchange_id ~~* any (array ['%MIAX%', '%EMLD%','%SPHR%', '%MPRL%'])
  and cl_exchange_id is null