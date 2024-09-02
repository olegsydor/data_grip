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


select aux.base32_to_int8('gg3ldjio0000');
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
$$
