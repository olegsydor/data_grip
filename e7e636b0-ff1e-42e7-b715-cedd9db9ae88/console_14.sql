select *
from dash360.report_fintech_adh_occ_contra(p_start_date_id := 20240523, p_end_date_id := 20240523,
                                            p_account_ids := null,--'{64885,54904,70420}',
                                            p_trading_firm_ids := '{"dzpribank","bnplon","jsjsoin"}'
     )

