create or replace function aux.base32_to_bin(in_value character varying)
    returns text
    language plpgsql
as
$fn$

declare
    each_char  char;
    bit_string text := '';
begin
    foreach each_char in array regexp_split_to_array(in_value, '')
        loop
--             raise notice 'bit_string - %', bit_string;
            bit_string = bit_string || case each_char
                                           when '0' then '00000'
                                           when '1' then '00001'
                                           when '2' then '00010'
                                           when '3' then '00011'
                                           when '4' then '00100'
                                           when '5' then '00101'
                                           when '6' then '00110'
                                           when '7' then '00111'
                                           when '8' then '01000'
                                           when '9' then '01001'
                                           when 'a' then '01010'
                                           when 'b' then '01011'
                                           when 'c' then '01100'
                                           when 'd' then '01101'
                                           when 'e' then '01110'
                                           when 'f' then '01111'
                                           when 'g' then '10000'
                                           when 'h' then '10001'
                                           when 'i' then '10010'
                                           when 'j' then '10011'
                                           when 'k' then '10100'
                                           when 'l' then '10101'
                                           when 'm' then '10110'
                                           when 'n' then '10111'
                                           when 'o' then '11000'
                                           when 'p' then '11001'
                                           when 'q' then '11010'
                                           when 'r' then '11011'
                                           when 's' then '11100'
                                           when 't' then '11101'
                                           when 'u' then '11110'
                                           when 'v' then '11111' end;
        end loop;
    return bit_string;
end;
$fn$
;

select char_length(aux.base32_to_bin('f8cr1bv80000'));
select aux.hex_to_decimal(aux.base32_to_bin('f8cr1bv80000'));

select to_hex('011 110 100 001 100 110 110 000 101 011 111 110 100 000 000 000 000 000 000 000'::bit(4))

select 88888888888888888888::int8;


select aux.base32_to_int8_('gg3ldjio0000') = aux.base32_to_int8('gg3ldjio0000');


create or replace function aux.base32_to_int8(in_string text)
    returns int8
    language plpgsql
as
$$
declare
    base_string text := '0123456789abcdefghijklmnopqrstuv';
    each_char   char;
    ret_result  int8 := 0;

begin
    foreach each_char in array regexp_split_to_array(lower(in_string), '')
        loop
            ret_result = ret_result * 32;
            ret_result = ret_result + (position(each_char in base_string) - 1);
        end loop;
    return ret_result;
end;
$$;


create or replace function aux.base32_to_int8_(in_string text)
    returns int8
    language plpgsql
    immutable
as
$$
declare
    base_string text := '0123456789abcdefghijklmnopqrstuv';
    ret_result  int8 := 0;
    each_char   char;
    i           int  := 1;
    base_length int  := length(in_string);
begin
    while i <= base_length
        loop
            each_char := lower(substring(in_string from i for 1));
            ret_result := ret_result * 32 + (position(each_char in base_string) - 1);
            i := i + 1;
        end loop;

    return ret_result;
end;
$$;

CREATE TABLE aux.your_table_name (
    START_TIME TIMESTAMP,
    START_DATE_ID INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM START_TIME) * 10000 +
                                           EXTRACT(MONTH FROM START_TIME) * 100 +
                                           EXTRACT(DAY FROM START_TIME)) STORED
);

select * from aux.your_table_name
alter table aux.your_table_name add column i int4;

select * from aux.your_table_name

insert into aux.your_table_name (start_time, i) values (clock_timestamp(), 1);

alter table aux.your_table_name add column     START_DATE_ID_V INT GENERATED ALWAYS AS
    (EXTRACT(YEAR FROM START_TIME) * 10000 +
     EXTRACT(MONTH FROM START_TIME) * 100 +
     EXTRACT(DAY FROM START_TIME)) VIRTUAL;

select version()


CREATE TABLE your_table_name (
    START_TIME TIMESTAMP,
    START_DATE_ID INT GENERATED ALWAYS AS
    (EXTRACT(YEAR FROM START_TIME) * 10000 +
     EXTRACT(MONTH FROM START_TIME) * 100 +
     EXTRACT(DAY FROM START_TIME)) VIRTUAL
);


CREATE TABLE trash.so_fix_execution_column_text_ (
	routine_schema information_schema."sql_identifier" COLLATE "C" NULL,
	routine_name information_schema."sql_identifier" COLLATE "C" NULL,
	routine_definition information_schema."character_data" COLLATE "C" NULL,
	md5_before text COLLATE "C" NULL,
	last_update_time timestamptz NULL,
	new_script text NULL,
	execution_order int4 NULL,
	was_executed bool NULL
);


truncate table trash.so_fix_execution_column_text_;

update trash.so_fix_execution_column_text_
set new_script = $insert$

CREATE OR REPLACE FUNCTION aux.base32_to_int8_(in_string text)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- SO 20240912 temp changes (no changes in fact)
declare
    base_string text := '0123456789abcdefghijklmnopqrstuv';
    ret_result  int8 := 0;
    each_char   char;
    i           int  := 1;
    base_length int  := length(in_string);
begin
    while i <= base_length
        loop
            each_char := lower(substring(in_string from i for 1));
            ret_result := ret_result * 32 + (position(each_char in base_string) - 1);
            i := i + 1;
        end loop;

    return ret_result;
end;
$function$
;

    $insert$
where true
  and routine_schema = 'aux'
  and routine_name = 'base32_to_int8_'
  and new_script is null;

create table trash.check_uniq (
    un_id serial not null,
    limit_request_id int4,
    is_active bool
);

create unique index limit_rq on trash.check_uniq (limit_request_id) where (is_active);

insert into trash.check_uniq (limit_request_id, is_active) values (1, true)
update trash.check_uniq
set is_active = false
where limit_request_id = 1
and is_active;

select * from trash.check_uniq;

    SELECT (pp.proargtypes::regtype[])[0:], pg_get_functiondef(pp.oid), replace(replace(replace(replace(replace(replace(replace(FORMAT(
                                                                       'COPY (SELECT pg_get_functiondef(%s)) TO ''%s(%s).sql',
                                                                       pp.oid, pn.nspname, pp.proname,
                                                                       (pp.proargtypes::regtype[])[0:])::text, '{', ''),
                                                       '}', ''), '"', ''), 'character', 'char'), 'char varying',
                               'varchar'), 'integer', 'int'), 'timestamp without time zone', 'tstamp')
from pg_proc pp
         inner join pg_namespace pn on (pp.pronamespace = pn.oid)
         inner join pg_language pl on (pp.prolang = pl.oid)
where pl.lanname NOT IN ('c', 'internal')
    and pn.nspname = 'aux';

SELECT FORMAT(
                                                                       'COPY (SELECT pg_get_functiondef(%s)) TO ''/u01/git/big_data/%s/functions/%s(%s).sql'' WITH (FORMAT csv, QUOTE '' '' );',
                                                                       pp.oid, pn.nspname, pp.proname,
                                                                       (pp.proargtypes::regtype[])[0:])::text
from pg_proc pp
         inner join pg_namespace pn on (pp.pronamespace = pn.oid)
         inner join pg_language pl on (pp.prolang = pl.oid)
where pl.lanname NOT IN ('c', 'internal')
  and pn.nspname = 'dwh';


COPY (SELECT pg_get_functiondef(55874)) TO '/u01/git/big_data/aux/functions/get_exp_date(date).sql' WITH (FORMAT csv, QUOTE ' ' );