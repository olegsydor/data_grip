create or replace function trash.so_check_tail(in_date_id int4)
returns int4
language plpgsql
as $$
    declare
    l_row_cnt int4;
    begin
        drop table if exists t_os;
        create temp table t_os
        as
            select order_id, exec_type, exec_time, is_busted, cum_qty, leaves_qty
            from dwh.execution
        where exec_date_id = in_date_id;
        get diagnostics l_row_cnt = row_count;

        return l_row_cnt;
    end;
    $$;

select trash.so_check_tail(in_date_id := 20180501);