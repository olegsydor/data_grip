select ex.order_id, cl.parent_order_id
from dwh.execution ex
         join lateral (select parent_order_id
                       from dwh.client_order cl
                       where cl.order_id = ex.order_id
                         and cl.create_date_id <= ex.exec_date_id
                         and cl.parent_order_id is not null
                       limit 1 ) cl on true
where exec_date_id = 20240306