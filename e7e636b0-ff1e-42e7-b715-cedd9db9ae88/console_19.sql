-- DROP FUNCTION staging.base64_to_hex(text);

create function staging.base64_to_hex(in_value text default null)
    returns text
    language plpgsql
    immutable
AS
$fn$
    -- 20241030 SO https://dashfinancial.atlassian.net/browse/DS-8441
declare
    l_each_char     char;
    l_ln            int;
    l_bit_string    text := '';
    l_result_string text = '';
    l_to_ext        bool = false;

begin
    if in_value is null
    then
        return '';
    end if;

    foreach l_each_char in array regexp_split_to_array(in_value, '')
        loop
            l_bit_string = ascii(l_each_char)::bit(8) || l_bit_string;

        end loop;
    l_ln = length(l_bit_string);

    loop
        if l_ln <= 4 then
            l_bit_string = right('000' || substr(l_bit_string, 1, l_ln), 4);
            l_to_ext = TRUE;
        end if;
        l_result_string = to_hex(substr(l_bit_string, l_ln - 3, 4)::bit(4)::int) || l_result_string;
        l_ln = l_ln - 4;

        if l_to_ext
        then
            exit;
        end if;
    end loop;
    return l_result_string;

end;
$fn$
;
comment on function staging.base64_to_hex is ' auxiliary function to convert base64 text into bit string. Used from execid_to_guid and clordid_to_guid';

select staging.base64_to_hex('01af');

drop function if exists staging.execid_to_guid(text);

create function staging.execid_to_guid(in_text text default null)
    returns text
    language plpgsql
    immutable
as
$fn$
    -- 20241030 SO https://dashfinancial.atlassian.net/browse/DS-8441
declare
    l_part_01 varchar;

begin
    if in_text is null then
        return '00000000-0000-0000-0000-000000000000';
    end if;

    l_part_01 = right('000000000000000000000000' || staging.base64_to_hex(in_text), 32);

    return
        substring(l_part_01, 1, 8) || '-' || substring(l_part_01, 9, 4) || '-' || substring(l_part_01, 13, 4) || '-' ||
        substring(l_part_01, 17, 4) || '-' || substring(l_part_01, 21, 12);

end;
$fn$;
comment on function staging.execid_to_guid is ' Function to convert text like f8cq4dik0000 into pseudo GUID';
-- select staging.execid_to_guid('f8cq4dik0000');


drop function if exists staging.clordid_to_guid;
create function staging.clordid_to_guid(in_text text default null)
    returns text
    language plpgsql
    immutable
as
$fn$
    -- 20241030 SO https://dashfinancial.atlassian.net/browse/DS-8441
declare
    l_main_01       text;
    l_main_02       text;
    l_part_01       text := '';
    l_part_02       text;
    l_result_string text := '';
    l_rec           record;

begin
    if in_text is null
    then
        return '00000000-0000-0000-0000-000000000000';
    end if;

    l_main_01 = substring(in_text, '(.{1,7})_[a-z0-9]*$'::text);
    l_main_02 = substring(in_text, '_([a-z0-9]*)$'::text); -- the second part - after the last underscore

    for l_rec in (select regexp_split_to_table(l_main_01, '_') as lett)
        loop
            l_part_01 = l_rec.lett::text || l_part_01;
        end loop;
    l_part_01 = right('0000' || l_part_01, 4);

    l_part_02 = right('00000000000000000000' || staging.base64_to_hex(substring(l_main_02, '^(.*)\d{6}$'::text)) ||
                      to_hex(substring(l_main_02, '^.*(\d{6})$'::text)::int), 20);

    l_result_string =
            '00000000-' || l_part_01 || '-' || substring(l_part_02, 1, 4) || '-' || substring(l_part_02, 5, 4) || '-' ||
            substring(l_part_02, 9, 12);
    return l_result_string;
end;
$fn$;
comment on function staging.clordid_to_guid is 'Function to convert text like 1_3230826 or f_0_6k230831 into pseudo GUID';
select staging.clordid_to_guid('f_0_6k230831');
select staging.clordid_to_guid('1_3230826');
