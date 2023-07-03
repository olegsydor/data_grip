with MD as (select sr.routing_table_id,
                   max(st.start_date_id) as max_date
            from strategy_routing_table sr
                     join strategy_transaction st on (sr.transaction_id = st.transaction_id)
--             where sr.ROUTING_TABLE_ID = 24876
            group by sr.routing_table_id

	union ALL

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



select em.routing_table_id--, e.max_date
from genesis2.routing_table rt
         left join lateral (select sr.routing_table_id,
                                   st.start_date_id-- as max_date
                            from strategy_routing_table sr
                                     join strategy_transaction st on (sr.transaction_id = st.transaction_id)
                            where sr.routing_table_id = rt.routing_table_id
                              and rownum = 1
                            order by 2 desc
             ) em on em.routing_table_id = rt.routing_table_id
where rt.routing_table_id = 20469;


select department_name, employee_id, employee_name
from   departments d
       left join lateral (select employee_id, employee_name
                          from   employees e
                          where  salary >= 2000
                          and    e.department_id = d.department_id) e
                 on e.department_id = d.department_id