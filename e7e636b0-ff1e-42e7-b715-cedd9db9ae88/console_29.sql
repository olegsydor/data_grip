select
    exec_broker as "Exec Broker", --list of all exec_broker from trades releated to AI. e.g. 333, 733, 792.
	type as "Type", --show `allocation` if we generate line from allocation, `trade` if from trade record
	account_name as "Account Name",-- taken from account_id
	alloc_instr_id as "Alloc Instr ID",
	alloc_instr_entry_id as "Alloc Instr Entry ID",
	sybmol as "Symbol", -- display_instrument_v2
	side as "Side",
	open_close as "O/C",
	exec_qty as "Exec Qty",
	avg_px as "Avg Px",
	CMTA as "CMTA",
	OCC AID as "OCC AID",
	reported_status as "Reported Status",
	reported_time as "Reported Time", --better recursion, but otherwise use our logic.
	is_deleted as "Alloc is deleted",
	created_time as "Created Time",
	created_by_user_name as "Created by User", -- Taken from Users dictionary
    deleted_by_user_name as "Deleted by User", -- Taken from Users dicitionary by deleted_user_id
	deleted_time as "Deleted time"
from dash_reporting.bofa_allocation_report bar
                 join genesis2.allocation_instruction ai
                      on ai.alloc_instr_id = bar.alloc_instr_id and ai.date_id = bar.date_id
                 join lateral (select tr.exec_broker, tr.account_id
                               from genesis2.alloc_instr2trade_record aitr
                                        join genesis2.trade_record tr using (trade_record_id, date_id)
                               where (aitr.alloc_instr_id = bar.alloc_instr_id and aitr.date_id = bar.date_id)
                               and tr.exec_broker = in_exec_broker
                               limit 1) tr on true
                 left join genesis2.customer_or_firm cst on cst.customer_or_firm_id = bar.opt_customer_or_firm

                 join genesis2.account ac on tr.account_id = ac.account_id and ac.is_deleted <> 'Y'
                 left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id and tf.is_deleted <> 'Y'
                 join genesis2.instrument di on di.instrument_id = bar.instrument_id
                 left join genesis2.user_identifier ui on ui.user_id = ai.deleted_by_user_id and ui.is_deleted <> 'Y'
                 left join genesis2.user_identifier uic on uic.user_id = ai.created_by_user_id and uic.is_deleted <> 'Y'
        where bar.date_id = in_date_id
          and bar.to_report = 'R'
--         group by bar.alloc_instr_id
