select record_type, order_id, chain_id, order_request_type, payload, md_payload
from (with chained_orders as (select distinct chain_order_id, cl_ord_id
                              from blaze7.blaze7.client_order co
                              where co.order_id = 806944338171936768)
      select 0                                 as record_type,
             co.order_id,
             co.chain_id,
             co.payload ->> 'OrderRequestType' as order_request_type,
             co.payload::text                     payload,
             null                              as md_payload
      from chained_orders cho
               inner join blaze7.blaze7.client_order co
                          on co.chain_order_id = cho.chain_order_id
                                 and co.cl_ord_id = cho.cl_ord_id
                                 and co.record_type = '0'
      union
      select 1                                  as record_type,
             orp.order_id,
             orp.chain_id,
             orp.payload ->> 'OrderRequestType' as order_request_type,
             orp.payload::text                     payload,
             mdr.payload::text                  as md_payload
      from chained_orders cho
               inner join blaze7.blaze7.client_order co
                          on co.chain_order_id = cho.chain_order_id and co.record_type = '0' and co.cl_ord_id = cho.cl_ord_id
               inner join blaze7.blaze7.order_report orp
                          on orp.order_id = co.order_id and orp.chain_id = co.chain_id and
                             orp.multileg_reporting_type in ('1', '2')
               left join blaze7.blaze7.market_data_report mdr on mdr.exec_id = orp.exec_id) s
order by record_type, order_id;


