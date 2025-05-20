--Executing procedure:("dash360.allocations_create"). 
-- Parameters: "@in_user_id=6690; @in_date_id=20250509; 
-- @in_change_vector={"2347039623":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":12,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040157":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":10,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040125":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":6,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347039341":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":4,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040158":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":1,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}]}; "

select jsonb_object_keys (:l_change_vector)::bigint;

select '{"2347039623":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":12,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040157":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":10,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040125":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":6,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347039341":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":4,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}],"2347040158":[{"cmta":"103","clearing_account_number":"103","street_account_name":"sab2","account_nickname":"hotbutton_new","last_qty":1,"allocation_avg_price":83.9909090909091,"trade_record_reason":"L"}]}'::jsonb;

select e.clearing_instr_id
                 from  clearing_instruction_entry e
--                  inner join clearing_instruction ca on e.clearing_instr_id = ca.clearing_instr_id and e.date_id = ca.date_id
                 where true
--     and e.date_id = :in_date_id
--                  and ca.status in ('P', 'C')
                 and e.trade_record_id in (select jsonb_object_keys (:l_change_vector)::bigint );


select * from genesis2.trade_record
                 where true
--     and e.date_id = :in_date_id
--                  and ca.status in ('P', 'C')
                 and trade_record_id in (select jsonb_object_keys (:l_change_vector)::bigint );
