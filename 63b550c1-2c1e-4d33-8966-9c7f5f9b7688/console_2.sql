create schema chk_suggestion

create function chk_suggestion.inner_call(in_cnt int2)
    returns int4
    language plpgsql
as
$fx$
declare
    row_cnt int4;
begin
    create temp table whole on commit drop as
    select word
    from words.word
    where word_length = in_cnt;
    get diagnostics row_cnt = row_count;
    return row_cnt;
end;
$fx$;

create or replace function chk_suggestion.outer_call()
    returns void
    language plpgsql
as
$fx$
declare
    each int2;
    s_um int4 := 0;
begin
    for each in 1..5
        loop
            s_um = s_um + chk_suggestion.inner_call(each::int2);
        end loop;
end;
$fx$;

select * from chk_suggestion.outer_call()