select db_create_time::timestamp at time zone 'UTC' at time zone 'US/Central'
from blaze7.client_order
where client_order.record_type = any (array['0', '2'])
and db_create_time < clock_timestamp()-- - interval '5 minutes'
order by 1 desc
limit 1

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
select replace(:in_to, ';',',');


select regexp_replace(:client_name, '[;|/|,/:,/{]', ',', 'g')

	select replace(:in_to, ' ','');
    select replace(:in_to, ',',';');

select string_to_array(:in_to, ';')
create or replace view blaze7.v_busted_trade as
select exec_id,
       order_id,
       chain_id,
       leg_ref_id,
       db_create_time,
       exec_ref_id,
       multileg_reporting_type,
       exec_type,
       is_busted,
       cl_ord_id
from blaze7.order_report rep
WHERE rep.multileg_reporting_type <> '3'
  AND (rep.exec_type::text <> ALL (ARRAY ['f'::text, 'w'::text, 'W'::text, 'g'::text, 'G'::text, 'I'::text, 'i'::text]))
  and rep.is_busted = 'Y'
        and rep.db_create_time > current_date - '5 days'::interval