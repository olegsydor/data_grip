-- https://dashfinancial.atlassian.net/browse/DS-10874
select *
from dash360.get_trade_record_exchange_fees(in_date_id := 20251222, in_cl_order_id := '3_1of251222',
                                            in_dash_exec_id := '860011673436', in_sec_order_id := 'CDAA0204-20251222',
                                            in_sec_exec_id := 'npktssdk0g02', in_side := '1');



select * from staging.trade_level_book_record
    where trade_record_id = 2347715403;


drop function if exists dash360.get_trade_record_exchange_fees;
create or replace function dash360.get_trade_record_exchange_fees(in_date_id int4,
                                                                  in_cl_order_id varchar(256),
                                                                  in_dash_exec_id varchar(128),
                                                                  in_sec_order_id varchar(256),
                                                                  in_sec_exec_id varchar(128),
                                                                  in_side char) -- 1
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

begin
    return query
        select f.trade_record_id,
               f.tcce_maker_taker_fee_amount,
               f.tcce_transaction_fee_amount,
               f.tcce_trade_processing_fee_amount,
               f.tcce_royalty_fee_amount,
               (select max_trade_record_id >= f.trade_record_id
                from staging.incrementalbilling
                where table_name = 'MIRA_to_GENESIS2_inc') as is_exchange_fee_computed
        --                 ,
--                f.client_order_id
--                 ,
--                f.secondary_order_id
--                 ,
--                f.exch_exec_id
--                 ,
--                f.secondary_exch_exec_id
--                 ,
--                f.side
        from dwh.flat_trade_record f
        where true
          and f.date_id = in_date_id
          and f.client_order_id = in_cl_order_id
          and f.secondary_order_id = in_sec_order_id
          and f.exch_exec_id = in_dash_exec_id
          and f.secondary_exch_exec_id = in_sec_exec_id
          and f.side = in_side
          and f.orig_trade_record_id is null
        limit 1;
end;
$fx$;



import foreign schema billing limit to (incrementalbilling)
from server postgres_uat_genesis2
into staging

select * from staging.incrementalbilling
where table_name = 'MIRA_to_GENESIS2_inc'


select * from information_schema.foreign_tables
         where foreign_server_name = 'big_data_prod'

             where table_name = 'Dash_Trade_Record_Daily_inc'