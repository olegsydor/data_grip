select status_date_id,
       fpo.parent_order_id,
       fpo.last_exec_id,
       fpo.order_status,
       hods."OrderStatus",
       fpo.pg_db_update_time,
       fpo.pg_db_create_time
from data_marts.f_parent_order fpo
         join dwh.historic_order_details_storage hods on hods."OrderID" = fpo.parent_order_id
         join dwh.client_order cl on cl.order_id = fpo.parent_order_id
where status_date_id = 20260415
  and hods."Status_Date_id" = 20260415
  and fpo.status_date_id = hods."Status_Date_id"
  and fpo.order_status != hods."OrderStatus"
and cl.multileg_reporting_type != '3';

select * from data_marts.load_parent_order_inc(in_parent_order_ids := '{436936742537443562}', in_date_id := 20260415);

select * from d_order_status

drop table t_base;

create temp table t_base as
select coalesce(cl.parent_order_id, ex.order_id) as parent_order_id,
       min(ex.exec_id)                           as min_exec_id,
       max(ex.exec_id)                           as max_exec_id,
       min(coalesce(cl.parent_order_process_time, client_order.process_time))         as parent_order_process_time,
       min(ex.order_create_date_id)              as order_create_date_id,
       min(cl.create_date_id)                    as create_date_id,
       array_agg(distinct ex.dataset_id)
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
where ex.exec_date_id = 20260416
  and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
  and case when in_parent_order_ids is null then true else cl.parent_order_id = any (in_parent_order_ids) end
  and case
          when not ex.is_parent_level and cl.parent_order_id is not null then true
           when ex.is_parent_level and ex.order_status = '4' and cl.parent_order_id is null then true
          else false end
and cl.order_id = 445894764413560327
group by coalesce(cl.parent_order_id, ex.order_id);

select parent_order_process_time, * from dwh.client_order
    where client_order.order_id = 445894764413560327

select *
    --distinct unnest(array_agg)
    from t_base;


drop table if exists t_base;
create temp table t_base as
select coalesce(cl.parent_order_id, ex.order_id)                              as parent_order_id,
       min(ex.exec_id)                                                        as min_exec_id,
       max(ex.exec_id)                                                        as max_exec_id,
       min(coalesce(cl.parent_order_process_time, client_order.process_time)) as parent_order_process_time,
       min(ex.order_create_date_id)                                           as order_create_date_id,
       min(cl.create_date_id)                                                 as create_date_id
from dwh.execution ex
         join dwh.client_order cl on cl.order_id = ex.order_id and cl.create_date_id = ex.order_create_date_id
where ex.exec_date_id = l_date_id
  and case when in_dataset_ids is null then true else ex.dataset_id = any (in_dataset_ids) end
  and case when in_parent_order_ids is null then true else cl.parent_order_id = any (in_parent_order_ids) end
  and case
          when not ex.is_parent_level and cl.parent_order_id is not null then true
          when ex.is_parent_level and ex.order_status = '4' and cl.parent_order_id is null then true
          else false end
group by coalesce(cl.parent_order_id, ex.order_id);



WITH rol AS (SELECT oid,
                    rolname::text AS role_name
             FROM pg_roles
             UNION
             SELECT 0::oid AS oid,
                    'public'::text),
     schemas AS ( -- Schemas
         SELECT oid                                                     AS schema_oid,
                n.nspname::text                                         AS schema_name,
                n.nspowner                                              AS owner_oid,
                'schema'::text                                          AS object_type,
                coalesce(n.nspacl, acldefault('n'::"char", n.nspowner)) AS acl
         FROM pg_catalog.pg_namespace n
         WHERE n.nspname !~ '^pg_'
           AND n.nspname <> 'information_schema'),
     classes AS ( -- Tables, views, etc.
         SELECT schemas.schema_oid,
                schemas.schema_name AS object_schema,
                c.oid,
                c.relname::text     AS object_name,
                c.relowner          AS owner_oid,
                CASE
                    WHEN c.relkind = 'r' THEN 'table'
                    WHEN c.relkind = 'v' THEN 'view'
                    WHEN c.relkind = 'm' THEN 'materialized view'
                    WHEN c.relkind = 'c' THEN 'type'
                    WHEN c.relkind = 'i' THEN 'index'
                    WHEN c.relkind = 'S' THEN 'sequence'
                    WHEN c.relkind = 's' THEN 'special'
                    WHEN c.relkind = 't' THEN 'TOAST table'
                    WHEN c.relkind = 'f' THEN 'foreign table'
                    WHEN c.relkind = 'p' THEN 'partitioned table'
                    WHEN c.relkind = 'I' THEN 'partitioned index'
                    ELSE c.relkind::text
                    END             AS object_type,
                CASE
                    WHEN c.relkind = 'S' THEN coalesce(c.relacl, acldefault('s'::"char", c.relowner))
                    ELSE coalesce(c.relacl, acldefault('r'::"char", c.relowner))
                    END             AS acl
         FROM pg_class c
                  JOIN schemas ON (schemas.schema_oid = c.relnamespace)
         WHERE c.relkind IN ('r', 'v', 'm', 'S', 'f', 'p')),
     cols AS ( -- Columns
         SELECT c.object_schema,
                null::integer                                            AS oid,
                c.object_name || '.' || a.attname::text                  AS object_name,
                'column'                                                 AS object_type,
                c.owner_oid,
                coalesce(a.attacl, acldefault('c'::"char", c.owner_oid)) AS acl
         FROM pg_attribute a
                  JOIN classes c ON (a.attrelid = c.oid)
         WHERE a.attnum > 0
           AND NOT a.attisdropped),
     procs AS ( -- Procedures and functions
         SELECT schemas.schema_oid,
                schemas.schema_name                                     AS object_schema,
                p.oid,
                p.proname::text                                         AS object_name,
                p.proowner                                              AS owner_oid,
                CASE p.prokind
                    WHEN 'a' THEN 'aggregate'
                    WHEN 'w' THEN 'window'
                    WHEN 'p' THEN 'procedure'
                    ELSE 'function'
                    END                                                 AS object_type,
                pg_catalog.pg_get_function_arguments(p.oid)             AS calling_arguments,
                coalesce(p.proacl, acldefault('f'::"char", p.proowner)) AS acl
         FROM pg_proc p
                  JOIN schemas ON (schemas.schema_oid = p.pronamespace)),
     udts AS ( -- User defined types
         SELECT schemas.schema_oid,
                schemas.schema_name                                     AS object_schema,
                t.oid,
                t.typname::text                                         AS object_name,
                t.typowner                                              AS owner_oid,
                CASE t.typtype
                    WHEN 'b' THEN 'base type'
                    WHEN 'c' THEN 'composite type'
                    WHEN 'd' THEN 'domain'
                    WHEN 'e' THEN 'enum type'
                    WHEN 't' THEN 'pseudo-type'
                    WHEN 'r' THEN 'range type'
                    WHEN 'm' THEN 'multirange'
                    ELSE t.typtype::text
                    END                                                 AS object_type,
                coalesce(t.typacl, acldefault('T'::"char", t.typowner)) AS acl
         FROM pg_type t
                  JOIN schemas ON (schemas.schema_oid = t.typnamespace)
         WHERE (t.typrelid = 0
             OR (SELECT c.relkind = 'c'
                 FROM pg_catalog.pg_class c
                 WHERE c.oid = t.typrelid))
           AND NOT EXISTS (SELECT 1
                           FROM pg_catalog.pg_type el
                           WHERE el.oid = t.typelem
                             AND el.typarray = t.oid)),
     fdws AS ( -- Foreign data wrappers
         SELECT null::oid                                               AS schema_oid,
                null::text                                              AS object_schema,
                p.oid,
                p.fdwname::text                                         AS object_name,
                p.fdwowner                                              AS owner_oid,
                'foreign data wrapper'                                  AS object_type,
                coalesce(p.fdwacl, acldefault('F'::"char", p.fdwowner)) AS acl
         FROM pg_foreign_data_wrapper p),
     fsrvs AS ( -- Foreign servers
         SELECT null::oid                                               AS schema_oid,
                null::text                                              AS object_schema,
                p.oid,
                p.srvname::text                                         AS object_name,
                p.srvowner                                              AS owner_oid,
                'foreign server'                                        AS object_type,
                coalesce(p.srvacl, acldefault('S'::"char", p.srvowner)) AS acl
         FROM pg_foreign_server p),

     all_objects AS (SELECT schema_name AS object_schema,
                            object_type,
                            schema_name AS object_name,
                            null::text  AS calling_arguments,
                            owner_oid,
                            acl
                     FROM schemas
                     UNION
                     SELECT object_schema,
                            object_type,
                            object_name,
                            null::text AS calling_arguments,
                            owner_oid,
                            acl
                     FROM classes
                     UNION
                     SELECT object_schema,
                            object_type,
                            object_name,
                            null::text AS calling_arguments,
                            owner_oid,
                            acl
                     FROM cols
                     UNION
                     SELECT object_schema,
                            object_type,
                            object_name,
                            calling_arguments,
                            owner_oid,
                            acl
                     FROM procs
                     UNION
                     SELECT object_schema,
                            object_type,
                            object_name,
                            null::text AS calling_arguments,
                            owner_oid,
                            acl
                     FROM udts
                     UNION
                     SELECT object_schema,
                            object_type,
                            object_name,
                            null::text AS calling_arguments,
                            owner_oid,
                            acl
                     FROM fdws
                     UNION
                     SELECT object_schema,
                            object_type,
                            object_name,
                            null::text AS calling_arguments,
                            owner_oid,
                            acl
                     FROM fsrvs),
     acl_base AS (SELECT object_schema,
                         object_type,
                         object_name,
                         calling_arguments,
                         owner_oid,
                         (aclexplode(acl)).grantor        AS grantor_oid,
                         (aclexplode(acl)).grantee        AS grantee_oid,
                         (aclexplode(acl)).privilege_type AS privilege_type,
                         (aclexplode(acl)).is_grantable   AS is_grantable
                  FROM all_objects)
        ,
     alll as (SELECT acl_base.object_schema,
                     case
                         when acl_base.object_type = 'view' then 'table'
                         else acl_base.object_type
                         end           as object_type,
                     acl_base.object_name,
                     acl_base.calling_arguments,
                     owner.role_name   AS object_owner,
                     grantor.role_name AS grantor,
                     grantee.role_name AS grantee,
                     acl_base.privilege_type,
                     acl_base.is_grantable
              FROM acl_base
                       JOIN rol owner ON (owner.oid = acl_base.owner_oid)
                       JOIN rol grantor ON (grantor.oid = acl_base.grantor_oid)
                       JOIN rol grantee ON (grantee.oid = acl_base.grantee_oid)
              WHERE acl_base.object_name IN (SELECT TRIM(UNNEST(string_to_array(:in_object_name, ','))))
                AND acl_base.object_schema IN (SELECT TRIM(UNNEST(string_to_array(:in_object_schema, ',')))))
select case
           when object_type = 'function' AND grantee = 'public' then
               'REVOKE ALL ON FUNCTION ' || object_schema || '.' || object_name || ' FROM public'
           else 'GRANT ' || string_agg(privilege_type, ', ') || ' ON ' || object_type || ' ' || object_schema || '.' ||
                object_name ||
                ' TO ' || grantee end
from alll
group by grantee, object_schema, object_name, object_type