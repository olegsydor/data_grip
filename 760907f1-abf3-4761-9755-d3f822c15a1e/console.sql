drop FUNCTION training.example_function;
create or replace function training.example_function(param_name int default null)
returns void
as $$
begin
    if param_name is null then
        raise notice 'Parameter was not passed at all';
    else
        raise notice 'Parameter value: %', param_name;
    end if;
end;
$$ language plpgsql;


select * from training.example_function()



create or replace function training.get_multileg_order_id(in_create_date_id integer,
                                                          in_client_order_id character varying,
                                                          in_fix_connection_id integer,
                                                          in_co_client_leg_ref_id character varying,
                                                          in_transaction_id bigint)
    returns text
    language plpgsql
as
$function$

begin
    return 'Multileg for in_create_date_id = ' || in_create_date_id::text || ', in_client_order_id := ' ||
           in_client_order_id::text || ', in_fix_connection_id := ' || in_fix_connection_id::text ||
           ', in_co_client_leg_ref_id := ' || coalesce(in_co_client_leg_ref_id::text, 'NULL') || ', in_transaction_id := ' ||
           coalesce(in_transaction_id::text, 'NULL');
end;
$function$
;



create or replace function training.get_single_order_id(in_create_date_id integer, in_client_order_id character varying,
                                                      in_fix_connection_id integer,
                                                      in_side character default null::character(1))
    returns text
    language plpgsql
as
$function$
begin
    return 'Single for in_create_date_id = ' || in_create_date_id::text || ', in_client_order_id := ' ||
           in_client_order_id::text || ', in_fix_connection_id := ' || in_fix_connection_id::text ||
           ', in_side := ' || coalesce(in_side::text, 'null');
end;
$function$
;


create or replace function training.get_cross_order_id(in_create_date_id integer, in_client_order_id character varying,
                                                       in_fix_connection_id integer,
                                                       in_co_client_leg_ref_id character varying default null,
                                                       in_parent_client_order_id character varying default null,
                                                       in_transaction_id bigint default null)
    returns text
    language plpgsql
as
$function$
begin
    return 'Cross for in_create_date_id = ' || in_create_date_id::text || ', in_client_order_id := ' ||
           in_client_order_id::text || 'in_parent_client_order_id := ' ||
           coalesce(in_parent_client_order_id::text, 'NULL') || ', in_fix_connection_id := ' ||
           in_fix_connection_id::text || ', in_co_client_leg_ref_id := ' ||
           coalesce(in_co_client_leg_ref_id::text, 'NULL') || ', in_transaction_id := ' ||
           coalesce(in_transaction_id::text, 'NULL');

end ;
$function$
;

create or replace function training.get_wrapper_order_id(in_create_date_id integer,
                                                         in_client_order_id character varying,
                                                         in_fix_connection_id integer,
                                                         in_co_client_leg_ref_id character varying default 'is_nothing',
                                                         in_transaction_id bigint default 0,
                                                         in_parent_client_order_id character varying default 'is_nothing')
    returns text
    language plpgsql
as
$function$
declare
    ret_order_id text := null;

begin
    if in_co_client_leg_ref_id = 'is_nothing' then
        select *
        into ret_order_id
        from training.get_single_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                          in_fix_connection_id := $3);
    end if;


    if ret_order_id is null and in_transaction_id = 0 then
        raise notice 'Cross';
        select *
        into ret_order_id
        from training.get_cross_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                         in_fix_connection_id := $3,
                                         in_co_client_leg_ref_id := $4, in_parent_client_order_id := $6,
                                         in_transaction_id := $5);
    end if;

    if ret_order_id is null and in_parent_client_order_id = 'is_nothing' then
        raise notice 'Multileg';
        select *
        into ret_order_id
        from training.get_multileg_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                            in_fix_connection_id := $3, in_co_client_leg_ref_id := $4,
                                            in_transaction_id := $5);
    end if;

    return ret_order_id;
end;
$function$
;


select * from training.get_wrapper_order_id(in_create_date_id := 1,
                                                         in_client_order_id := 'N',
                                                         in_fix_connection_id := 0,
                                                         in_co_client_leg_ref_id := 'N',
                                                         in_transaction_id := 100)


