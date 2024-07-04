create schema words;
create table words.word (word text);

select * from words.word;

create schema aux;
comment on schema aux is 'To store auxiliary methods';

create or replace function aux.custom_format(in_numb numeric default null, in_len int default 8)
    returns text
    language plpgsql
as
$$
    -- the function works like the select cast(cast(in_numb as float) as varchar(in_len)) in T-sql
declare
    l_int_part     int;
    l_int_part_len int;
    l_adj          int := 2; -- adjustment keeping in mind decimal point and\or something else
begin
    if in_numb is null then
        return null;
    end if;

    select floor(in_numb) into l_int_part;
    select char_length(l_int_part::text) into l_int_part_len;
    return round(in_numb, in_len - l_int_part_len - l_adj);
end;
$$;

create function aux.get_exp_date(in_date date default null)
    returns text
    language plpgsql
as
$$
declare
begin
    if in_date is null then
        return null;
    end if;
    return lpad(extract(day from in_date)::text, 2, '0') ||
           to_char(in_date, 'Mon') ||
           to_char(in_date, 'YY');
end;
$$;