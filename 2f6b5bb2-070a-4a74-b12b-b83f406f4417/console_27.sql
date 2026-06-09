create function trash.check_int2(in_val int2)
    returns int4
    language plpgsql
as
$$
declare
    l_val int4;
begin
    select n
    into l_val
    from training.cantor
    where n = in_val;
    return l_val;
end;
$$;


select * from trash.check_int2(5)