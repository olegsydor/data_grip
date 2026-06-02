create function staging.load_finish_change_trg() returns trigger
    language plpgsql
as
$$
begin
    perform public.send('oleh. sydor@iongroup. com', 'EOS INC ETL',
                        to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS') || ': For date_id ' || new.date_id::text ||
                        ' ' || new.node_name || '. ' || 'THe process has finished'
            );
    return new;
end ;
$$;


create trigger load_finish_insert_trigger after
insert
    on
    staging.load_finish for each row execute function inc_hft.load_finish_change_trg();


