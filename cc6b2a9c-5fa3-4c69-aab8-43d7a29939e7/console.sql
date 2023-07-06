with MD as (select sr.routing_table_id,
                   max(st.start_date_id) as max_date
            from strategy_routing_table sr
                     join strategy_transaction st on (sr.transaction_id = st.transaction_id)
             where sr.ROUTING_TABLE_ID = 22224
            group by sr.routing_table_id
22224|BD_SPY_FS3||Option|SENSOR|3|Default|Standard|Broker/Dealer|Symbol|||SPY||12909|wchv|2022-10-04 16:11:59.583233
	union

    select sd1.routing_table_id,
           max(st.start_date_id) as max_date
    from strategy_decision_cust_order sd1
             join strategy_decision sd on sd1.strategy_decision_id = sd.strategy_decision_id
             join strategy_transaction st on sd.transaction_id = st.transaction_id
    group by sd1.routing_table_id
)
select rt.routing_table_id                   as routing_table_id,
       rt.routing_table_name                 as routing_table_name,
       rt.routing_table_desc                 as routing_table_desc,
       case
           when rt.instrument_type_id = 'O' then 'Option'
           when rt.instrument_type_id = 'E' then 'Equity'
           when rt.instrument_type_id = 'M' then 'Multileg'
           else rt.instrument_type_id end    as instrument_type,
       ts.target_strategy_name               as target_strategy,
       rt.fee_sensitivity                    as fee_sensitivity,
       case
           when rt.intended_scope_of_use = 'D' then 'Default'
           when rt.intended_scope_of_use = 'A' then 'Account-specific'
           when rt.intended_scope_of_use = 'T' then 'Trading firm-specific'
           else rt.intended_scope_of_use end as routing_table_scope,
       ac.account_class_name                 as account_class,
       cg.capacity_group_name                as capacity_group,
       case
           when rt.routing_table_type = 'C' then 'Instrument Class'
           when rt.routing_table_type = 'T' then 'Global'
           when rt.routing_table_type = 'S' then 'Symbol'
           when rt.routing_table_type = 'L' then 'Symbol List'
           else rt.routing_table_type end    as routing_table_type,
       case
           when rt.instr_class_id = 'NN' then 'Nickel Non-Premium'
           when rt.instr_class_id = 'NP' then 'Nickel Premium'
           when rt.instr_class_id = 'PN' then 'Penny Non-Premium'
           when rt.instr_class_id = 'PP' then 'Penny Premium'
           else rt.instr_class_id end        as instrument_class,
       rt.symbol_list_id                     as symbol_list,
       rt.root_symbol                        as symbol,
       rt.symbol_suffix                      as symbol_sfx,
       md.max_date                           as last_used_date
from
	routing_table rt
	join MD on (
		MD.ROUTING_TABLE_ID = RT.ROUTING_TABLE_ID
	)
	left outer join target_strategy ts on rt.target_strategy = ts.target_strategy
	left outer join account_class ac on rt.account_class_id = ac.account_class_id
	left outer join capacity_group cg on rt.capacity_group_id = cg.capacity_group_id
where
	rt.is_deleted = 'N'
order by
	rt.instrument_type_id,
	rt.target_strategy,
	rt.routing_table_name;

SELECT *
from
	routing_table rt
-- join (select sr.routing_table_id,
--                    st.start_date_id as max_date
--             from strategy_routing_table sr
--                      join strategy_transaction st on
--                 sr.transaction_id = st.transaction_id
--             where ROWNUM = 1
--             order by st.start_date_id desc) m1 on M1.ROUTING_TABLE_ID = RT.ROUTING_TABLE_ID

join ( select sd1.routing_table_id,
           st.start_date_id as max_date
    from strategy_decision_cust_order sd1
             join strategy_decision sd on sd1.strategy_decision_id = sd.strategy_decision_id
             join strategy_transaction st on sd.transaction_id = st.transaction_id
--     group by sd1.routing_table_id
     where ROWNUM = 1
             order by st.start_date_id desc
    ) m2 on m2.ROUTING_TABLE_ID = rt.ROUTING_TABLE_ID
where
	rt.is_deleted = 'N'



select sr.routing_table_id,
                   st.start_date_id as max_date
            from strategy_routing_table sr
                     join strategy_transaction st on
                sr.transaction_id = st.transaction_id
            where ROWNUM = 1
            and sr.ROUTING_TABLE_ID = 12455
            order by st.start_date_id desc



select rt.routing_table_id                   as routing_table_id,
       rt.routing_table_name                 as routing_table_name,
       rt.routing_table_desc                 as routing_table_desc,
       case
           when rt.instrument_type_id = 'O' then 'Option'
           when rt.instrument_type_id = 'E' then 'Equity'
           when rt.instrument_type_id = 'M' then 'Multileg'
           else rt.instrument_type_id end    as instrument_type,
       ts.target_strategy_name               as target_strategy,
       rt.fee_sensitivity                    as fee_sensitivity,
       case
           when rt.intended_scope_of_use = 'D' then 'Default'
           when rt.intended_scope_of_use = 'A' then 'Account-specific'
           when rt.intended_scope_of_use = 'T' then 'Trading firm-specific'
           else rt.intended_scope_of_use end as routing_table_scope,
       ac.account_class_name                 as account_class,
       cg.capacity_group_name                as capacity_group,
       case
           when rt.routing_table_type = 'C' then 'Instrument Class'
           when rt.routing_table_type = 'T' then 'Global'
           when rt.routing_table_type = 'S' then 'Symbol'
           when rt.routing_table_type = 'L' then 'Symbol List'
           else rt.routing_table_type end    as routing_table_type,
       case
           when rt.instr_class_id = 'NN' then 'Nickel Non-Premium'
           when rt.instr_class_id = 'NP' then 'Nickel Premium'
           when rt.instr_class_id = 'PN' then 'Penny Non-Premium'
           when rt.instr_class_id = 'PP' then 'Penny Premium'
           else rt.instr_class_id end        as instrument_class,
       rt.symbol_list_id                     as symbol_list,
       rt.root_symbol                        as symbol,
       rt.symbol_suffix                      as symbol_sfx,
       md.max_date                           as last_used_date

from genesis2.routing_table rt
         left join (select sr.routing_table_id,
                                   max(st.start_date_id) as max_date
                            from strategy_routing_table sr
                                     join strategy_transaction st on (sr.transaction_id = st.transaction_id)
                            group by sr.routing_table_id
    ) em on em.routing_table_id = rt.routing_table_id
where rt.routing_table_id = 20469;


select rt.ROUTING_TABLE_ID,
       (/*+ no_push_pred(i) */select first_value(st.start_date_id) over (partition by sr.transaction_id order by st.START_DATE_ID) max_date_id
                            from strategy_routing_table sr
                                     join strategy_transaction st on (sr.transaction_id = st.transaction_id)
                            where sr.ROUTING_TABLE_ID = rt.ROUTING_TABLE_ID
                            and ROWNUM = 1
    ) as r
from genesis2.routing_table rt
         where r is not null;


select rt.routing_table_id                   as routing_table_id,
       rt.routing_table_name                 as routing_table_name,
       rt.routing_table_desc                 as routing_table_desc,
       case
           when rt.instrument_type_id = 'O' then 'Option'
           when rt.instrument_type_id = 'E' then 'Equity'
           when rt.instrument_type_id = 'M' then 'Multileg'
           else rt.instrument_type_id end    as instrument_type,
       ts.target_strategy_name               as target_strategy,
       rt.fee_sensitivity                    as fee_sensitivity,
       case
           when rt.intended_scope_of_use = 'D' then 'Default'
           when rt.intended_scope_of_use = 'A' then 'Account-specific'
           when rt.intended_scope_of_use = 'T' then 'Trading firm-specific'
           else rt.intended_scope_of_use end as routing_table_scope,
       ac.account_class_name                 as account_class,
       cg.capacity_group_name                as capacity_group,
       case
           when rt.routing_table_type = 'C' then 'Instrument Class'
           when rt.routing_table_type = 'T' then 'Global'
           when rt.routing_table_type = 'S' then 'Symbol'
           when rt.routing_table_type = 'L' then 'Symbol List'
           else rt.routing_table_type end    as routing_table_type,
       case
           when rt.instr_class_id = 'NN' then 'Nickel Non-Premium'
           when rt.instr_class_id = 'NP' then 'Nickel Premium'
           when rt.instr_class_id = 'PN' then 'Penny Non-Premium'
           when rt.instr_class_id = 'PP' then 'Penny Premium'
           else rt.instr_class_id end        as instrument_class,
       rt.symbol_list_id                     as symbol_list,
       rt.root_symbol                        as symbol,
       rt.symbol_suffix                      as symbol_sfx,
       md.max_date                           as last_used_date
from genesis2.routing_table rt
join        ( /*+ no_push_pred(i) */select sr.ROUTING_TABLE_ID, max(st.start_date_id) max_date
                            from strategy_routing_table sr
                                     join strategy_transaction st on (sr.transaction_id = st.transaction_id)
                            WHERE st.START_DATE_ID is not null
                            group by sr.ROUTING_TABLE_ID
    )  md on md.routing_table_id = rt.ROUTING_TABLE_ID
	left outer join target_strategy ts on rt.target_strategy = ts.target_strategy
	left outer join account_class ac on rt.account_class_id = ac.account_class_id
	left outer join capacity_group cg on rt.capacity_group_id = cg.capacity_group_id
where
	rt.is_deleted = 'N'
order by
	rt.instrument_type_id,
	rt.target_strategy,
	rt.routing_table_name;


select sr.ROUTING_TABLE_ID, max(st.start_date_id) max_date
                            from strategy_routing_table sr
                                     join strategy_transaction st on (sr.transaction_id = st.transaction_id)
                            WHERE st.START_DATE_ID is not null
                            and sr.routing_table_id = 20469
                            group by sr.ROUTING_TABLE_ID;



select * from genesis2.REPORTING_SL.getAllocations(null, null,date '2023-07-03', date '2023-07-04');


select
	bai."TradeDate" as "Date",
	tf.trading_firm_name as "TradingFirm",
	a.account_name as "AccountName",
	bai."OPRASymbol" as "OSI Symbol",
	bai."DisplayInstrumentID" as "Symbol",
	case when(
			bai."MaturityYear" is not null
			and bai."MaturityMonth" is not null
			and bai."MaturityDay" is not null
		) then bai."MaturityDay" || '/' || bai."MaturityMonth" || '/' || bai."MaturityYear"
	end as "Expiration",
	bai."OpenClose",
	bai."InstrumentType",
	(
		case
			when bai."Side" = '1' then 'B'
			when bai."Side" = '2' then 'S'
			else 'T'
		end
	) "Side",
	cast((CASE
		when(
			bai."AllocQty" is null
			or bai."AllocQty" = 0
		) then bai."DayCumQty"
		else bai."AllocQty"
	END) AS INTEGER) as "Total Quantity",
	to_CHAR(
		round( bai."DayAvgPx", 5 )
	) as "Average Price",
	NVL(
		AE.ALLOC_QTY,
		bai."DayCumQty"
	) as "Allocated Quantity",
	round(( bai."AccDashCommissionAmount" / bai."DayCumQty" )* NVL( AE.ALLOC_QTY, bai."DayCumQty" ), 6 ) as "Commission",
	round(( bai."AliasMakerTakerFeeAmount" / bai."DayCumQty" )* NVL( AE.ALLOC_QTY, bai."DayCumQty" ), 6 ) as "Maker/Taker",
	round(( bai."AliasTransactionFeeAmount" / bai."DayCumQty" )* NVL( AE.ALLOC_QTY, bai."DayCumQty" ), 6 ) as "Transaction",
	round(( bai."AliasTradeProcessingFeeAmount" / bai."DayCumQty" )* NVL( AE.ALLOC_QTY, bai."DayCumQty" ), 6 ) as "Trade Processing",
	round(( bai."AliasRoyaltyFeeAmount" / bai."DayCumQty" )* NVL( AE.ALLOC_QTY, bai."DayCumQty" ), 6 ) as "Royalty",
	ca.clearing_account_number as "CMTA"
from
	BUNDLE_ALLOCATION_INFO_STORAGE bai
left join account a ON bai."AccountID" = a.account_id
left join trading_firm tf ON a.trading_firm_id = tf.trading_firm_id
left join ALLOCATION_INSTRUCTION ALIN ON ALIN.BUNDLE_ID = bai."BundleID" and ALIN.ALLOC_SCOPE = 'B'	and ALIN.IS_DELETED <> 'Y'
left join ALLOCATION_ENTRY AE ON ALIN.ALLOCATION_INSTRUCTION_ID = AE.ALLOCATION_INSTRUCTION_ID and AE.ALLOC_QTY > 0
left join CLEARING_ACCOUNT ca ON ca.clearing_account_id = AE.clearing_account_id and ca.MARKET_TYPE = bai."InstrumentType" and ca.IS_DELETED <> 'Y'
where 1=1
-- 	and (p_tf_id IS NULL OR a.trading_firm_id=p_tf_id)
-- 	and (p_accounts IS NULL OR a.ACCOUNT_ID MEMBER p_accounts)
  	and bai."TradeDate" BETWEEN :l_trunc_start_date AND :l_trunc_end_date

union all
select
	oai."TradeDate" as "Date",
	tf.trading_firm_name as "TradingFirm",
	a.account_name as "AccountName",
	oai."OPRASymbol" as "OSI Symbol",
	oai."DisplayInstrumentID" as "Symbol",
	case
		when(
			oai."MaturityYear" is not null
			and oai."MaturityMonth" is not null
			and oai."MaturityDay" is not null
		) then oai."MaturityDay" || '/' || oai."MaturityMonth" || '/' || oai."MaturityYear"
	end as "Expiration",
	oai."OpenClose",
	oai."InstrumentType",
	(
		case
			when oai."Side" = '1' then 'B'
			when oai."Side" = '2' then 'S'
			else 'T'
		end
	) "Side",
	cast((CASE
		when(
			oai."AllocQty" is null
			or oai."AllocQty" = 0
		) then oai."DayCumQty"
		else oai."AllocQty"
	END) AS INTEGER) as "Total Quantity",
	TO_CHAR(
		round( oai."DayAvgPx", 5 )
	) as "Average Price",
	NVL(
		AE.ALLOC_QTY,
		oai."DayCumQty"
	) as "Allocated Quantity",
	round(( oai."AccDashCommissionAmount" / oai."DayCumQty" )* NVL( AE.ALLOC_QTY, oai."DayCumQty" ), 6 ) as "Commission",
	round(( oai."AliasMakerTakerFeeAmount" / oai."DayCumQty" )* NVL( AE.ALLOC_QTY, oai."DayCumQty" ), 6 ) as "Maker/Taker",
	round(( oai."AliasTransactionFeeAmount" / oai."DayCumQty" )* NVL( AE.ALLOC_QTY, oai."DayCumQty" ), 6 ) as "Transaction",
	round(( oai."AliasTradeProcessingFeeAmount" / oai."DayCumQty" )* NVL( AE.ALLOC_QTY, oai."DayCumQty" ), 6 ) as "Trade Processing",
	round(( oai."AliasRoyaltyFeeAmount" / oai."DayCumQty" )* NVL( AE.ALLOC_QTY, oai."DayCumQty" ), 6 ) as "Royalty",
	ca.clearing_account_number as "CMTA"
from
	ORDER_ALLOCATION_INFO_STORAGE oai
left join account a ON oai."AccountID" = a.account_id
left join trading_firm tf ON a.trading_firm_id = tf.trading_firm_id
left join ALLOCATION_INSTRUCTION ALIN ON ALIN.ORDER_ID = oai."OrderID" and ALIN.ALLOC_SCOPE = 'S' and ALIN.IS_DELETED <> 'Y'
left join ALLOCATION_ENTRY AE ON ALIN.ALLOCATION_INSTRUCTION_ID = AE.ALLOCATION_INSTRUCTION_ID and AE.ALLOC_QTY > 0
left join CLEARING_ACCOUNT ca ON ca.clearing_account_id = AE.clearing_account_id
	and ca.MARKET_TYPE = oai."InstrumentType"
	and ca.IS_DELETED <> 'Y'
where
	oai."BundleID" is null
-- 	AND (p_tf_id IS NULL OR a.trading_firm_id=p_tf_id)
-- 	AND (p_accounts IS NULL OR a.ACCOUNT_ID MEMBER p_accounts)
	AND oai."TradeDate" BETWEEN :l_trunc_start_date AND :l_trunc_end_date;