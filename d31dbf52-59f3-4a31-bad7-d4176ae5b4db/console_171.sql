select *
from dash360.report_ecr(start_date_id := 20260101, end_date_id := 20261231,
                        trading_firm_ids := '{"barclay05","barclay04","barclay06","barclay09","barclay07"}',
                        instrument_type_id := 'O', client_id := null,
                        p_demo_mode := 'N', p_row_limit := null, p_commission_display_mode := '1', p_group_by := 'S',
                        in_only_sub_dollar := 'A')