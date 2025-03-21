select * from training.cantor;

create table training.trg_ins
(
    id int4,
    ts timestamp default clock_timestamp()
);
alter table training.trg_ins add id_jsn jsonb;

select * from training.trg_ins;

create or replace function training.trg_delete()
returns trigger
language plpgsql
as $$
    begin
    insert into training.trg_ins (id, id_jsn)
    select old.n, jsonb_build_object('id', old.n);
    return old;
    end;
    $$;


create trigger trg_cantor_before_delete
    before delete
     on training.cantor
    for each row
    execute function training.trg_delete();



SELECT ts.* FROM training.t_sample AS ts;
create index t_sample_btree_idx on training.t_sample (sensor_id);
create index t_sample_hash_idx on training.t_sample using hash (sensor_id);