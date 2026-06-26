select * from genesis2.alloc_drop_message_status
where drop_message_status = 'J';


-- DROP FUNCTION dash360.trade_record_update_ccru(int4, int4, int8, numeric, numeric, int4, varchar);

CREATE OR REPLACE FUNCTION dash360.trade_record_update_ccru(in_user_id integer, in_date_id integer,
                                                            in_trade_record_id bigint, in_rate numeric,
                                                            in_amount numeric,
                                                            in_load_batch_id integer DEFAULT NULL::integer,
                                                            in_book_record_creator_id character varying DEFAULT 'MAN'::character varying)
    RETURNS integer
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY DS-2914 On conflich has been implemented due to miration to native parititoning
-- AK DS-10934 Add new parameter to procedure dash360.trade_record_update_ccru to add new param to se book_record_creator_id (SGDD or other)
-- SO 20260623 https://dashfinancial.atlassian.net/browse/DS-11703 Add validation to APIs for setting CCRU and BROK to block update in AI has already generated and sent 35=J (accepted, rejected, int.rejected)
declare
    l_cnt           int;
    l_date_id       int;
    l_load_batch_id int;
begin
    l_date_id := in_date_id;
    if in_load_batch_id is null
    then
        select nextval('load_batch_load_batch_id_seq'::regclass) into l_load_batch_id;
    else
        l_load_batch_id := in_load_batch_id;
    end if;

    if exists (select null
               from genesis2.alloc_instr2trade_record aitr
                        join genesis2.alloc_drop_message_status adms on adms.alloc_instr_id = aitr.alloc_instr_id
               where aitr.trade_record_id = in_trade_record_id
                 and aitr.date_id = in_date_id
--                and adms.drop_message_status = 'J'
    ) then
        raise exception 'Error: Unable to change commission for a completed Allocation with generated 35=J drop '
            using errcode = '??', /*message='Can''t be allocated due to pending clearing',*/
                hint = 'Error: Unable to change commission for a completed Allocation with generated 35=J drop ';
    end if;

    insert into trade_level_book_record (trade_record_id, book_record_type_id, amount, book_record_creator_id, date_id,
                                         rate, load_batch_id, user_id, create_time, billing_entity)
    values (in_trade_record_id, 'CCRU', in_amount, in_book_record_creator_id, l_date_id, in_rate, l_load_batch_id,
            in_user_id, clock_timestamp(), '-1')
    on conflict (trade_record_id, book_record_type_id, book_record_creator_id, billing_entity, date_id)
        do update set amount        = EXCLUDED.amount,
                      rate          = EXCLUDED.rate,
                      load_batch_id = EXCLUDED.load_batch_id,
                      user_id       = EXCLUDED.user_id,
                      create_time   = EXCLUDED.create_time;

    perform genesis2.etl_subscribe(in_load_batch_id => l_load_batch_id, in_row_cnt => 1,
                                   in_subscription_name => 'big_data.flat_trade_record',
                                   in_source_table_name => 'trade_level_book_record', in_date_id => l_date_id);

    return l_load_batch_id;


exception
    when others then
        RAISE notice '% %', sqlstate, sqlerrm;
        raise;
        return -2;
end;
$function$
;

-- DROP FUNCTION dash360.trade_record_update_brok(int4, int4, int8, numeric, numeric, int4, varchar);

CREATE OR REPLACE FUNCTION dash360.trade_record_update_brok(in_user_id integer, in_date_id integer,
                                                            in_trade_record_id bigint, in_rate numeric,
                                                            in_amount numeric,
                                                            in_load_batch_id integer DEFAULT NULL::integer,
                                                            in_book_record_creator_id character varying DEFAULT 'MAN'::character varying)
    RETURNS integer
    LANGUAGE plpgsql
    COST 1
AS
$function$
    -- SY DS-2914 On conflich has been implemented due to miration to native parititoning
-- AK DS-10934 Add new parameter to procedure dash360.trade_record_update_ccru to add new param to se book_record_creator_id (SGDD or other)
-- SO 20260609 https://dashfinancial.atlassian.net/browse/DS-11642 Add broker commissions rate and amount
declare
    l_date_id       int;
    l_load_batch_id int;
begin

    l_date_id := in_date_id;
    if in_load_batch_id is null
    then
        select nextval('load_batch_load_batch_id_seq'::regclass) into l_load_batch_id;
    else
        l_load_batch_id := in_load_batch_id;
    end if;

    if exists (select null
               from genesis2.alloc_instr2trade_record aitr
                        join genesis2.alloc_drop_message_status adms on adms.alloc_instr_id = aitr.alloc_instr_id
               where aitr.trade_record_id = in_trade_record_id
                 and aitr.date_id = in_date_id
--                and adms.drop_message_status = 'J'
    ) then
        raise exception 'Error: Unable to change commission for a completed Allocation with generated 35=J drop '
            using errcode = '??', /*message='Can''t be allocated due to pending clearing',*/
                hint = 'Error: Unable to change commission for a completed Allocation with generated 35=J drop ';
    end if;

    insert into trade_level_book_record (trade_record_id, book_record_type_id, amount, book_record_creator_id, date_id,
                                         rate, load_batch_id, user_id, create_time, billing_entity)
    values (in_trade_record_id, 'BROK', in_amount, in_book_record_creator_id, l_date_id, in_rate, l_load_batch_id,
            in_user_id, clock_timestamp(), '-1')
    on conflict (trade_record_id, book_record_type_id, book_record_creator_id, billing_entity, date_id)
        do update set amount        = EXCLUDED.amount,
                      rate          = EXCLUDED.rate,
                      load_batch_id = EXCLUDED.load_batch_id,
                      user_id       = EXCLUDED.user_id,
                      create_time   = EXCLUDED.create_time;

    return l_load_batch_id;


exception
    when others then
        RAISE notice '% %', sqlstate, sqlerrm;
        raise;
        return -2;
end;
$function$
;


 if exists (select null
               from genesis2.alloc_instr2trade_record aitr
                        join genesis2.alloc_drop_message_status adms on adms.alloc_instr_id = aitr.alloc_instr_id
               where aitr.trade_record_id in (in_trade_record_ids)
                 and aitr.date_id = in_date_id
    ) then
       STOP
    end if;


select null
               from genesis2.alloc_instr2trade_record aitr
                        join genesis2.alloc_drop_message_status adms on adms.alloc_instr_id = aitr.alloc_instr_id
               where aitr.trade_record_id in (in_trade_record_ids)
                 and aitr.date_id = in_date_id

select dash360.get_data_for_allocation_drop_sg(ai.alloc_instr_id), * from genesis2.allocation_instruction ai
         where date_id = 20260623;

select * from dash360.get_data_for_allocation_drop_sg(-127278) ;

update trash.ind;
set "DASH Liq Ind Type" = case "DASH Liq Ind Type"
    when 'Auction' then 4
    when 'Remove Liquidity' then 2
    when 'Add Liquidity' then 1
    when 'Route Away' then 3
when 'Conditional'then 8
    when 'Neither Added Nor Removed Liquidity' then 0
end
