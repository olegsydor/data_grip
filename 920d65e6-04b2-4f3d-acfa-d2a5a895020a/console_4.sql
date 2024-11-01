create function staging.is_sor_routed(in_report_id text)
returns text
language plpgsql
    stable
as $fx$
    declare

    begin

        with recursive bs as (select rep.order_id,
                                     rep.exec_id,
                                     rep.chain_id,
                                     rep.payload ->> 'RouterExecId' AS exchangetransactionid,
                                     case
                                         when rep.exec_type in ('1', '2', 'r') then rep.payload ->> 'LastMkt'::text
                                         end                        as exdestination
--                               , *
                              from blaze7.order_report rep
                                       join blaze7.client_order co
                                            on co.order_id = rep.order_id and co.chain_id = rep.chain_id
                              WHERE true
                                AND rep.multileg_reporting_type <> '3'
                                AND co.record_type = ANY (ARRAY ['0', '2'])
                                AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i')
                                and rep.exec_id = 'gdjj2uu00000'
--                                 and rep.payload ->> 'RouterExecId' is not null
--                                 and parent_order_id is not null
                              union all

                              select rep.order_id,
                                     rep.exec_id,
                                     rep.chain_id,
                                     rep.payload ->> 'RouterExecId' AS exchangetransactionid,
                                     case
                                         when rep.exec_type in ('1', '2', 'r') then rep.payload ->> 'LastMkt'::text
                                         end                        as exdestination
                              from blaze7.order_report rep
                                       join blaze7.client_order co
                                            on co.order_id = rep.order_id and co.chain_id = rep.chain_id
                                       Inner join bs
                                                  on co.parent_order_id = bs.order_id
                                                      and rep.payload ->> 'RouterExecId' = bs.ExchangeTransactionID
                                                      and rep.chain_id = bs.chain_id
                              WHERE true
                                AND rep.multileg_reporting_type <> '3'
                                AND co.record_type = ANY (ARRAY ['0', '2'])
                                AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i'))
        select *
        from bs
    end;

    $fx$;

select * from blaze7.client_order
    where order_id = 213665488402644992

select * from blaze7.order_report
    where order_id = 213665488402644992




        SELECT client_order.cl_ord_id
                                                  FROM blaze7.client_order
                                                  WHERE client_order.order_id = co.parent_order_id


