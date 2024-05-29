create or replace function staging.empty_parameter_(inp_json text, keys text[])
    returns text
    language plpgsql
as
$foo$
declare
    f_json jsonb;
    ks     text;
    x      text[] := '{}';
begin
    f_json = inp_json::jsonb;
    foreach ks in array keys
        loop
            if f_json -> ks is null then
                x = array_append(x, ks);
            end if;

        end loop;
    return x::text;
end;
$foo$;


create or replace function staging.empty_parameter(inp_json text, keys text[])
    returns text
    language plpgsql
as
$foo$
declare
    f_json     jsonb;
    ret_string text;
begin
    f_json = jsonb_strip_nulls(inp_json::jsonb);

    ret_string = (select string_agg(x.key, ',' order by key)
                  from (select unnest(keys) as key
                        except
                        select *
                        from jsonb_object_keys(f_json)) x);
    return ret_string;

end;
$foo$;

select *
from staging.empty_parameter('{"key_1": 1, "key_2": 2, "key_3": 3, "key_5": 5}',
                             array ['key_1', 'key_2', 'key_3', 'key_4', 'key_5', 'key_6']);



select array_to_string(array(select unnest(string_to_array(:in_string, '|'))::varchar order by 1), '|');

with base as (select unnest(string_to_array(:in_string, '|')) as x)
select array_to_string(array_agg(x), '|')
from (select x
      from base
      order by 1) c;


SELECT regexp_replace('Lorem     3    Ipsum 23  standard  7                 dummy 		   11   text', '\s+', ' ', 'g');

create table staging.order_test (id int4, val text);
insert into staging.order_test(id, val)
select digit, string from (values (10, 'zero'), (10, 'one'), (10, 'two'), (10, 'three'), (10, 'four')) as t(digit, string);

select * from staging.order_test
order by id, array_position(array ['zero', 'one', 'two', 'three', 'four'], val);

select *
from staging.order_test
order by id, case val
             when 'zero' then 0
             when 'one' then 1
             when 'two' then 2
             when 'three' then 3
             when 'four' then 4 end;



create table staging.users
(
    user_id serial primary key,
    name    text
);

create table staging.orders
(
    order_id     serial primary key,
    user_id      integer references staging.users (user_id),
    order_date   timestamp,
    total_amount numeric
);

insert into staging.users(name)
select string from (values ('zero3'), ('one3'), ('two3'), ('three3'), ('four3'), ('five3')) as t(string);

select * from staging.users;

insert into staging.orders(user_id, order_date, total_amount)
select round(random() * 23) + 1 ,
             '2023-01-01'::timestamp + interval '1 minute' * round(random()::numeric * 758880, 0),
             round(random() * 2000)
      from generate_series(1, 1000000) s(i)

select extract(year from order_date), extract(month from order_date), count(1), sum(total_amount)
from staging.orders
where order_date between '2023-01-01' and '2023-01-10'
group by extract(year from order_date), extract(month from order_date)
order by 1, 2

create index on staging.orders (order_date);
create index on staging.orders (user_id);

select us.name, sum(total_amount)
from staging.users us
         join staging.orders od using (user_id)
where true
--     and order_date between '2023-01-01' and '2023-01-10'
and user_id = 2
group by us.name;


select us.name, od.total_amount
from staging.users us
         join lateral (select sum(total_amount) as total_amount
                       from staging.orders od
                       where od.user_id = us.user_id
                         and order_date between '2023-01-01' and '2023-01-10'
                       limit 1) od on true
where true
  and user_id = 2

