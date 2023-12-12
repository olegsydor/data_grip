-- option 1
drop table if exists tmp_exec;
create temp table tmp_exec as
select ex.exec_id,
       ex.order_id,
       ex.exec_time,
       ex.exec_type,
       ex.exec_date_id,
       ex.exch_exec_id
from dwh.execution ex
join trash.fix_upload_exec using (exch_exec_id)
where exec_date_id in (20230911, 20230912, 20230913);


drop table if exists ex_tmp;
create temp table ex_tmp as
select fixex.*,
       ex.exec_id,
       ex.order_id,
       ex.exec_time,
       ex.exec_type,
       ex.exec_date_id
from trash.fix_upload_exec as fixex
         join tmp_exec ex
              on (fixex.trans_type in ('8', '9'))
                  and fixex.exch_exec_id = ex.exch_exec_id
                  and (
                              abs(
                                          extract(epoch from fixex.create_or_exec_ts)
                                          - extract(epoch from ex.exec_time)
                                  ) % (24 * 3600)
                          ) < 120
--                  and ex.exec_date_id in (20230915, 20230918, 20230919)
                  and ex.exec_date_id in (20230911, 20230912, 20230913)

;

drop table if exists cex_tmp;
create temp table cex_tmp as
select fixex.*,
       ex.exec_id,
       ex.order_id,
       ex.exec_time,
       ex.exec_type
from trash.fix_upload_exec
         as fixex
         join dwh.conditional_execution ex
              on (fixex.trans_type in ('8', '9'))
                  and fixex.exch_exec_id = ex.exch_exec_id
                  and (
                              abs(
                                          extract(epoch from fixex.create_or_exec_ts)
                                          - extract(epoch from ex.exec_time)
                                  ) % (24 * 3600)
                          ) < 120
;

drop table if exists res_1;
create temp table res_1 as
with ex as (select ex_tmp.*
                         from ex_tmp
                         where exists
                                   (select null
                                    from dwh.client_order co
                                    where co.order_id = ex_tmp.order_id
                                      and co.client_order_id = ex_tmp.client_order_id
                                      and co.create_date_id <= ex_tmp.exec_date_id)),
     cex as (select cex_tmp.*
                          from cex_tmp
                          where exists
                                    (select null
                                     from dwh.conditional_order con_o
                                     where con_o.order_id = cex_tmp.order_id
                                       and con_o.client_order_id = cex_tmp.client_order_id
                                       and con_o.create_time <= cex_tmp.exec_time)),
     co as (select fixex.*,
                                co.order_id,
                                co.create_time,
                                co.multileg_reporting_type,
                                co.time_in_force_id,
                                co.parent_order_id,
                                co.orig_order_id
                         from trash.fix_upload_exec
                                  as fixex
                                  join dwh.client_order co
                                       on co.client_order_id = fixex.client_order_id
                                           and not fixex.trans_type in ('8', '9')
                                           and (
                                                       abs(
                                                                   extract(epoch from fixex.create_or_exec_ts)
                                                                   - extract(epoch from co.create_time)
                                                           ) % (24 * 3600)
                                                   ) < 120
--                                           and co.create_date_id in (20230915, 20230918, 20230919)
                                           and co.create_date_id in (20230911, 20230912, 20230913)

                         where not fixex.trans_type in ('8', '9')),
     cnd as  (select fixex.*,
                                 co.order_id,
                                 co.create_time,
                                 null multileg_reporting_type,
                                 null time_in_force_id,
                                 co.parent_order_id,
                                 co.orig_order_id
                          from trash.fix_upload_exec
                                   as fixex
                                   join dwh.conditional_order co
                                        on co.client_order_id = fixex.client_order_id
                                            and not fixex.trans_type in ('8', '9')
                                            and abs(
                                                            extract(epoch from fixex.create_or_exec_ts)
                                                            - extract(epoch from co.create_time)
                                                    ) < 120
                          where not fixex.trans_type in ('8', '9'))
select trans_type,
       client_order_id,
       cl_order_id_orig,
       exch_exec_id,
       create_time as create_or_exec_db,
       order_id
from co
union all
select trans_type,
       client_order_id,
       cl_order_id_orig,
       exch_exec_id,
       create_time as create_or_exec_db,
       order_id
from cnd
union all
select trans_type,
       client_order_id,
       cl_order_id_orig,
       exch_exec_id,
       exec_time as create_or_exec_db,
       order_id
from ex
union all
select trans_type,
       client_order_id,
       cl_order_id_orig,
       exch_exec_id,
       exec_time as create_or_exec_db,
       order_id
from cex
;
