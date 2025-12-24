-- https://dashfinancial.atlassian.net/browse/DS-10874
select *
from dash360.get_trade_record_exchange_fees(in_date_id := 20251222, in_cl_order_id := '3_1of251222',
                                            in_dash_exec_id := '860011673436',
                                            in_side := '1',
                                            in_sec_order_id := 'CDAA0204-20251222',
                                            in_sec_exec_id := 'npktssdk0g02',
                                            in_account_name := 'B7DEV'
     );

select *
from dash360.get_trade_record_exchange_fees(in_date_id := 20251222, in_cl_order_id := '3_1of251222',
                                            in_dash_exec_id := '860011673436',
                                            in_side := '1'
     );




select * from staging.trade_level_book_record
    where trade_record_id = 2347715403;

select * from dwh.d_account

drop function if exists dash360.get_trade_record_exchange_fees;
create or replace function dash360.get_trade_record_exchange_fees(in_date_id int4,
                                                                  in_cl_order_id varchar(256),
                                                                  in_side char,
                                                                  in_dash_exec_id varchar(128),
                                                                  in_sec_order_id varchar(256) default null,
                                                                  in_sec_exec_id varchar(128) default null,
                                                                  in_account_name varchar(30) default null) -- 1
    returns table
            (
                trade_record_id                  int8,
                tcce_maker_taker_fee_amount      numeric(20, 8),
                tcce_transaction_fee_amount      numeric(20, 8),
                tcce_trade_processing_fee_amount numeric(20, 8),
                tcce_royalty_fee_amount          numeric(20, 8),
                is_exchange_fee_computed         bool
            )
    language plpgsql
as
$fx$
declare
    l_account_ids int4[];
begin
    if in_account_name is not null then
        select array_agg(account_id)
        into l_account_ids
        from dwh.d_account
        where account_name = in_account_name;
    end if;
    return query
        select ftr.trade_record_id,
               ftr.tcce_maker_taker_fee_amount,
               ftr.tcce_transaction_fee_amount,
               ftr.tcce_trade_processing_fee_amount,
               ftr.tcce_royalty_fee_amount,
               (select max_trade_record_id >= ftr.trade_record_id
                from staging.incrementalbilling
                where table_name = 'MIRA_to_GENESIS2_inc') as is_exchange_fee_computed
--                 ,
--                ftr.client_order_id,
--                ftr.secondary_order_id,
--                ftr.exch_exec_id,
--                ftr.secondary_exch_exec_id,
--                ftr.side
        from dwh.flat_trade_record ftr
        where true
          and ftr.date_id = in_date_id
          and ftr.client_order_id = in_cl_order_id
          and ftr.side = in_side
          and ftr.exch_exec_id = in_dash_exec_id
          and ftr.orig_trade_record_id is null
          and case when in_sec_order_id is not null then ftr.secondary_order_id = in_sec_order_id else true end
          and case when in_sec_exec_id is not null then ftr.secondary_exch_exec_id = in_sec_exec_id else true end
          and case when in_account_name is not null then ftr.account_id = any (l_account_ids) else true end
--         limit 1
    ;
end;
$fx$;



select account_id, account_name from dwh.flat_trade_record
                                join dwh.d_account using (account_id)
where trade_record_id = 2347715403