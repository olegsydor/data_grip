select * from trash.fix_reload_202401_ALL__ob_tmp as fx

insert into trash.fix_reload_202401_ALL__ob_tmp_ex_ord
-- create temp table t_os_os as
select co.order_id, fx.*
from trash.fix_reload_202401_ALL__ob_tmp as fx
         join lateral (select co.order_id
                       from dwh.client_order co
                                join dwh.gtc_order_status gos
                                     on gos.create_date_id = co.create_date_id and gos.order_id = co.order_id
                       where co.client_order_id = fx.client_order_id
                         and co.create_date_id < 20240112
                         and not exists (select null
                                         from trash.fix_reload_202401_ALL__ob_tmp_ex_ord ord
                                         where ord.order_id = gos.order_id)
                       limit 1) co on true
where true

        --and to_char(fx.create_or_exec_ts, 'YYYYMMDD')::int4 in (20240112, 20240116, 20240117)
        ;