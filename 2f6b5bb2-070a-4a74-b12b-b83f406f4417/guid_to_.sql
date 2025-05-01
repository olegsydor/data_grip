create or replace function blaze7.get_guid_to_clordid(inp_guid varchar)
returns varchar
language plpgsql
as $$
declare
    part1        varchar(12);
    out_string   varchar := '';
    binval       varchar(80) := '';
    bl           int := 1;
    intval       bigint;
    placer       varchar(7);
    is_undersc   int := 1;
    binchar      varchar;
begin
    -- part1 = first 12 symbols without dashes and leading zeros removed
    part1 := lpad(trim(leading '0' from substring(replace(inp_guid, '-', '') from 1 for 12)), 12, '0');

    -- placer = reversed binary of last hex char, padded to 7
    placer := left(reverse(blaze7.get_Hex_To_Bin(substring(part1 from 12 for 1))) || '0000000', 7);

    -- build out_string from part1 using placer
    while bl < length(part1) loop
        if substring(placer from is_undersc for 1) = '0' then
            out_string := out_string || substring(part1 from bl for 1);
            bl := bl + 1;
        else
            out_string := out_string || '_';
        end if;
        is_undersc := is_undersc + 1;
        raise notice '%', out_string;
    end loop;

    out_string := out_string || '_';

    -- convert second part (last 15 hex chars) to binary, then to characters
    -- extract right part of GUID, remove dashes
    declare
        tail varchar := right(replace(inp_guid, '-', ''), 22);
        hexval varchar := substring(replace(tail, '-', '') from 1 for 15);
        short_hex varchar := right(hexval, 12);
    begin
        -- convert hex to integer
        intval := ('x' || short_hex)::bit(48)::bigint;

        -- convert integer to 48-bit binary
        binval := lpad(to_char(intval::bit(48), 'FM999999999999999999'), 48, '0');

        bl := length(binval) - 7;

        while bl > 0 loop
            binchar := substring(binval from bl for 8);
            if binchar <> '00000000' then
                out_string := out_string || blaze7.get_Bin_To_Char(binchar);
            end if;
            bl := bl - 8;
        end loop;
    end;

    -- add last 5 chars of GUID converted from hex to int
    out_string := out_string || cast(('x' || right(inp_guid, 5))::bit(20)::int as varchar);

    return out_string;
end;
$$;


create or replace function blaze7.get_hex_to_bin_(hex_char char)
returns varchar
language sql
as $$
    select (('x' || hex_char)::bit(4))::text
$$;

select blaze7.get_hex_to_bin_('r')

create or replace function blaze7.get_bin_to_char(bin varchar)
returns char
language sql
as $$
    select chr(('b' || bin)::bit(8)::int)
$$;


select blaze7.get_guid_to_clordid('00000000-0001-0000-0000-0006A323D1D5')