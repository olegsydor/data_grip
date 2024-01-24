do $$
    declare
    ret_row record;
        begin
        select 1, 2, 3 into ret_row;
        raise notice 'row - %', ret_row;
    end;
    $$