select create_date_id, fix_connection_id, client_order_id, side, co_client_leg_ref_id, transaction_id, *
from dwh.client_order co
where cross_order_id is not null
  and multileg_reporting_type = '1';

select *
from public.get_single_order_id(20231002, '180040202044790', 74, '2') as x;


drop function if exists public.get_single_order_id;
create function public.get_single_order_id(in_create_date_id integer, in_client_order_id character varying,
                                           in_fix_connection_id integer, in_side character default null::character(1))
    returns table
            (
                order_id          int8,
                parent_order_id   int8,
                orig_order_id     int8,
                multileg_order_id int8
            )
    language plpgsql
as
$function$
    -- https://dashfinancial.atlassian.net/browse/DS-7457 SO 20231108
    -- https://dashfinancial.atlassian.net/browse/DMP-523 SO 20240124 returns table with multiple values order_id, parent_order_id, orig_order_id, multileg_order_id instead of order_id
begin
    return query
        select co.order_id, co.parent_order_id, co.orig_order_id, co.multileg_order_id
        from dwh.client_order co
        where co.create_date_id = in_create_date_id
          and co.fix_connection_id = in_fix_connection_id
          and co.client_order_id = in_client_order_id
          and case when in_side is null then true else co.side = in_side end
        limit 1;
end;
$function$
;
comment on function public.get_single_order_id(int4, varchar, int4, bpchar) is 'Getting order_id for single orders';

select *
from public.get_multileg_order_id(20231101, 'vc_nov1_box_mleg1', 572, 'vcleg1',
                                  970020467231);

drop function if exists public.get_multileg_order_id;
create function public.get_multileg_order_id(in_create_date_id integer, in_client_order_id character varying,
                                             in_fix_connection_id integer,
                                             in_co_client_leg_ref_id character varying,
                                             in_transaction_id bigint)
    returns table
            (
                order_id          int8,
                parent_order_id   int8,
                orig_order_id     int8,
                multileg_order_id int8
            )
    language plpgsql
as
$function$
    -- https://dashfinancial.atlassian.net/browse/DS-7457 SO 20231108
    -- https://dashfinancial.atlassian.net/browse/DMP-523 SO 20240124 returns table with multiple values order_id, parent_order_id, orig_order_id, multileg_order_id instead of order_id
begin
    return query
        select co.order_id, co.parent_order_id, co.orig_order_id, co.multileg_order_id
        from dwh.client_order co
        where co.create_date_id = in_create_date_id
          and multileg_reporting_type <> '1'
          and co.client_order_id = in_client_order_id
          and case
                  when in_transaction_id is null then co.transaction_id is null
                  else co.transaction_id = in_transaction_id end
          and co.fix_connection_id = in_fix_connection_id
          and case
                  when in_co_client_leg_ref_id is null then co_client_leg_ref_id is null
                  else co.co_client_leg_ref_id = in_co_client_leg_ref_id end
        limit 1;
end;
$function$
;
comment on function public.get_multileg_order_id(int4, varchar, int4, varchar, int8) is 'Getting order_id for multileg orders';

select *
from public.get_cross_order_id(20231002, 'NIOEJLLDBAAAAAAAC1', 1510, '0', null,
                               900001140751);

drop function if exists public.get_cross_order_id;
create function public.get_cross_order_id(in_create_date_id integer, in_client_order_id character varying,
                                          in_fix_connection_id integer,
                                          in_co_client_leg_ref_id character varying default null::character varying,
                                          in_parent_client_order_id character varying default null::character varying,
                                          in_transaction_id bigint default null::bigint)
    returns table
            (
                order_id          int8,
                parent_order_id   int8,
                orig_order_id     int8,
                multileg_order_id int8
            )
    language plpgsql
as
$function$
    -- https://dashfinancial.atlassian.net/browse/DMP-523 SO 20240124 returns table with multiple values order_id, parent_order_id, orig_order_id, multileg_order_id instead of order_id
begin
    return query
        select co.order_id, co.parent_order_id, co.orig_order_id, co.multileg_order_id
        from dwh.client_order co
                 left join lateral ( select par.client_order_id as parent_client_order_id
                                     from dwh.client_order par
                                     where par.order_id = co.parent_order_id
                                       and par.create_date_id <= co.create_date_id
                                       and case
                                               when in_parent_client_order_id is null then 1 = 2
                                               else par.client_order_id = in_parent_client_order_id end
                                     limit 1) par on true
        where co.create_date_id = in_create_date_id
          and cross_order_id is not null
          and co.client_order_id = in_client_order_id
          and co.fix_connection_id = in_fix_connection_id
          and case
                  when in_co_client_leg_ref_id is null then co_client_leg_ref_id is null
                  else co.co_client_leg_ref_id = in_co_client_leg_ref_id end
          and case
                  when in_parent_client_order_id is not null
                      then par.parent_client_order_id = in_parent_client_order_id
                  else par.parent_client_order_id is null end
          and case
                  when in_transaction_id is null then co.transaction_id is null
                  else co.transaction_id = in_transaction_id end;
exception
    when others then
        return query select -5, 0, 0, 0;

end;
$function$
;

select *
from public.get_order_id_by_natural_key(in_create_date_id := 20231002,
                                        in_client_order_id := 'LIOEJLLDBAAAAAAA'::text,
                                        in_side := '2',
                                        in_fix_connection_id := 1510,
                                        in_co_client_leg_ref_id := null,
                                        in_transaction_id := 900001140750,
                                        in_parent_client_order_id := null,
                                        in_multileg_reporting_type := '1',
                                        in_cross_order_id := null,
                                        in_quote_id := null);
    drop function if exists public.get_order_id_by_natural_key;
create function public.get_order_id_by_natural_key(in_create_date_id integer,
                                                   in_client_order_id character varying,
                                                   in_fix_connection_id integer, in_side character,
                                                   in_co_client_leg_ref_id character varying,
                                                   in_transaction_id bigint,
                                                   in_parent_client_order_id character varying,
                                                   in_multileg_reporting_type character,
                                                   in_cross_order_id bigint, in_quote_id character varying)
    returns table
            (
                order_id          int8,
                parent_order_id   int8,
                orig_order_id     int8,
                multileg_order_id int8
            )
    language plpgsql
AS
$function$
    -- 2023-11-29 SO https://dashfinancial.atlassian.net/browse/DS-7457
    -- The algorithm is described here https://dashfinancial.atlassian.net/wiki/spaces/DMP/pages/3773038946/DMP+Order+Search
    -- https://dashfinancial.atlassian.net/browse/DMP-523 SO 20240124 returns table with multiple values order_id, parent_order_id, orig_order_id, multileg_order_id instead of order_id
declare
    ret_order_id text := null;

begin
    if in_multileg_reporting_type = '1' and (in_cross_order_id is null or in_quote_id is null) then
--         raise notice 'Single';
        return query
            select x.order_id,
                   x.parent_order_id,
                   x.orig_order_id,
                   x.multileg_order_id
            from public.get_single_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                            in_fix_connection_id := $3, in_side := $4) as x;
        return;
    end if;


    if in_cross_order_id is null then
--         raise notice 'Multileg';
        return query
            select x.order_id,
                   x.parent_order_id,
                   x.orig_order_id,
                   x.multileg_order_id
            from public.get_multileg_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                              in_fix_connection_id := $3, in_co_client_leg_ref_id := $5,
                                              in_transaction_id := $6) as x;
        return;
    end if;

--     raise notice 'Cross';
    return query
        select x.order_id,
               x.parent_order_id,
               x.orig_order_id,
               x.multileg_order_id
        from public.get_cross_order_id(in_create_date_id := $1, in_client_order_id := $2,
                                       in_fix_connection_id := $3,
                                       in_co_client_leg_ref_id := $5, in_parent_client_order_id := $7,
                                       in_transaction_id := $6) as x;
    return;
end;
$function$
;
