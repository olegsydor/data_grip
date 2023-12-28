create temp table ex_tmp as
select fixex.*,
       ex.exec_id,
       ex.order_id,
       ex.exec_time,
       ex.exec_type,
       ex.exec_date_id
from trash.fix_upload_exec as fixex
    --             {self.pg_out_table_schema}.{self.pg_out_exec_table_name}
    join dwh.execution ex
         on (fixex.trans_type in ('8', '9'))
             and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
             and ex.exch_exec_id is not Null
             and fixex.exch_exec_id = ex.exch_exec_id
             and (
                     abs(
                             extract(epoch from fixex.create_or_exec_ts)
                                 - extract(epoch from ex.exec_time)
                     ) % (24 * 3600)
                     ) < 120
             and ex.exec_date_id in (20231227);

--------------------
create temp table ex_tmp as
            select
            fixex.*,
            ex.exec_id,
            ex.order_id,
            ex.exec_time,
            ex.exec_type,
            ex.exec_date_id
            from
            trash.fix_upload_exec
            as fixex
            join dwh.execution ex
            on (fixex.trans_type in ('8','9'))
            and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
            and ex.exch_exec_id is not Null
            and fixex.exch_exec_id = ex.exch_exec_id
            and (
                    abs(
                        extract(epoch from fixex.create_or_exec_ts)
                        - extract(epoch from ex.exec_time)
                    ) % (24*3600)
            ) < 120
            and  ex.exec_date_id in (20231227)
            ;

            create temp table ex_null_exchexecid_tmp as
            select
            fixex.*,
            ex.exec_id,
            ex.order_id,
            ex.exec_time,
            ex.exec_type,
            ex.exec_date_id
            from
            trash.fix_upload_exec
            as fixex
            join dwh.execution ex
            on (fixex.trans_type in ('8','9'))
            and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
            and ex.exch_exec_id is Null
            --and left(to_char(ex.exec_time , 'HHMISS.MS'),12) = left(to_char(fixex.create_or_exec_ts , 'HHMISS.MS'),12)
            and ex.exec_time - fixex.create_or_exec_ts between -interval '1 second' and interval '1 second'
            and  ex.exec_date_id in (20231227)
            ;

            create temp table cex_tmp as
            select
            fixex.*,
            ex.exec_id,
            ex.order_id,
            ex.exec_time,
            ex.exec_type
            from
            trash.fix_upload_exec
            as fixex
            join dwh.conditional_execution ex
            on (fixex.trans_type in ('8','9'))
            and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
            and ex.exch_exec_id is not Null
            and fixex.exch_exec_id = ex.exch_exec_id
            and (
                    abs(
                        extract(epoch from fixex.create_or_exec_ts)
                        - extract(epoch from ex.exec_time)
                    ) % (24*3600)
            ) < 120
            ;

            create temp table cex_null_exchexecid_tmp as
            select
            fixex.*,
            ex.exec_id,
            ex.order_id,
            ex.exec_time,
            ex.exec_type
            from
            trash.fix_upload_exec
            as fixex
            join dwh.conditional_execution ex
            on (fixex.trans_type in ('8','9'))
            and coalesce(ex.exch_exec_id, 'NA') != 'NONE'
            and ex.exch_exec_id is Null
            --and left(to_char(ex.exec_time , 'YYYYMMDDHHMISS.MS'),20) = left(to_char(fixex.create_or_exec_ts , 'YYYYMMDDHHMISS.MS'),20)
            and ex.exec_time - fixex.create_or_exec_ts between -interval '1 second' and interval '1 second'
            ;

            with
            ex as materialized (
                select * from (
                select ex_tmp.* from ex_tmp
                union
                select ex_null_exchexecid_tmp.* from ex_null_exchexecid_tmp
                ) ex_tmp
                where exists
                    (
                        select null from dwh.client_order co
                        where co.order_id = ex_tmp.order_id
                        and co.client_order_id = ex_tmp.client_order_id
                        and co.create_date_id <= ex_tmp.exec_date_id
                    )
            ),
            cex as materialized (
                select * from (
                select cex_tmp.* from cex_tmp
                union
                select cex_null_exchexecid_tmp.* from cex_null_exchexecid_tmp
                ) cex_tmp
                where exists
                    (
                        select null from dwh.conditional_order con_o
                        where con_o.order_id = cex_tmp.order_id
                        and con_o.client_order_id = cex_tmp.client_order_id
                        and con_o.create_time <= cex_tmp.exec_time
                    )
            )

            select
            trans_type, client_order_id, cl_order_id_orig, exch_exec_id,
            exec_time as create_or_exec_db, order_id
            from ex

            union all

            select
            trans_type, client_order_id, cl_order_id_orig, exch_exec_id,
            exec_time as create_or_exec_db, order_id
            from cex
            ;