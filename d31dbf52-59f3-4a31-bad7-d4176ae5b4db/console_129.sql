-- DROP FUNCTION dwh.collect_order_exec_tree_from_root_but_street_no_fixmsg(int8);

CREATE OR REPLACE FUNCTION dwh.collect_order_exec_tree_from_root_but_street_no_fixmsg(root_order_id_ bigint)
    RETURNS TABLE
            (
                order_id          bigint,
                root_order_id     bigint,
                event_date_id     integer,
                event_time        timestamp without time zone,
                client_order_id   character varying,
                orig_order_id     bigint,
                parent_order_id   bigint,
                multileg_order_id bigint,
                leg_ref_id        character varying,
                exec_id           bigint,
                fix_message_id    bigint,
                fix_message_text  text,
                source_type       character varying
            )
    LANGUAGE plpgsql
AS
$function$
-- 2025-03-20 [Oleskii Haram] Moved from trash schema (original name: trash.ob_collect_order_exec_tree_from_root_but_street_no_fixmsg). Used in client_order_today.py tool.
BEGIN
    RETURN QUERY
        WITH co AS (SELECT DISTINCT tree.order_id,
                                    root_order_id_      as root_order_id,
                                    tree.create_date_id AS event_date_id,
                                    tree.create_time    AS event_time,
                                    tree.client_order_id,
                                    tree.orig_order_id,
                                    tree.parent_order_id,
                                    tree.multileg_order_id,
                                    tree.leg_ref_id,
                                    NULL::BIGINT        AS exec_id,
                                    tree.fix_message_id,
                                    -- NULL::TEXT AS fix_message_text,
                                    tree.source_type
                    FROM dwh.collect_root_order_tree_but_street(root_order_id_) AS tree)
                ,
             co_ex as (SELECT co.order_id,
                              co.root_order_id,
                              ex.exec_date_id AS event_date_id,
                              ex.exec_time    AS event_time,
                              co.client_order_id,
                              co.orig_order_id,
                              co.parent_order_id,
                              co.multileg_order_id,
                              co.leg_ref_id,
                              ex.exec_id,
                              ex.fix_message_id,
                              --fmj.fix_message::TEXT AS fix_message_text,
                              'exec'::VARCHAR AS source_type
                       FROM co
                                JOIN LATERAL (
                           SELECT e.exec_id, e.exec_date_id, e.exec_time, e.fix_message_id
                           FROM dwh.execution e
                           WHERE e.order_id = co.order_id
                             AND e.exec_date_id >= co.event_date_id
                             AND e.exec_type != 'D'
                             AND e.exec_time >= co.event_time - INTERVAL '2 seconds'
                             AND e.fix_message_id IS NOT NULL
                           limit 100500
                           ) AS ex ON true

                       UNION ALL

                       SELECT co.order_id,
                              co.root_order_id,
                              co.event_date_id,
                              co.event_time,
                              co.client_order_id,
                              co.orig_order_id,
                              co.parent_order_id,
                              co.multileg_order_id,
                              co.leg_ref_id,
                              co.exec_id,
                              co.fix_message_id,
                              --fmj.fix_message::TEXT AS fix_message_text,
                              co.source_type
                       FROM co)
                ,
             co_ex_fm as (SELECT co.order_id,
                                 co.root_order_id,
                                 co.event_date_id,
                                 co.event_time,
                                 co.client_order_id,
                                 co.orig_order_id,
                                 co.parent_order_id,
                                 co.multileg_order_id,
                                 co.leg_ref_id,
                                 co.exec_id,
                                 co.fix_message_id,
                              /*fmj.fix_message*/
                                 ''::TEXT AS fix_message_text,
                                 co.source_type,
                                 case
                                     when co.exec_id is null
                                         then 1
                                     else
                                                 row_number()
                                                 over (partition by co.fix_message_id rows between unbounded preceding and unbounded following)
                                     end  as ern
                          FROM co_ex co
--	LEFT JOIN LATERAL (
--	    SELECT fmj.fix_message
--	    FROM fix_capture.fix_message_json fmj
--	    WHERE fmj.fix_message_id = co.fix_message_id
--	    AND fmj.date_id = co.event_date_id
--		limit  1
--	) AS fmj ON true
             ) -- end co_ex_fm
        SELECT co.order_id,
               co.root_order_id,
               co.event_date_id,
               co.event_time,
               co.client_order_id,
               co.orig_order_id,
               co.parent_order_id,
               co.multileg_order_id,
               co.leg_ref_id,
               co.exec_id,
               co.fix_message_id,
               co.fix_message_text,
               co.source_type
        FROM co_ex_fm co
        WHERE co.ern = 1 -- needed to leave only last instances of ERs that relate to both F and original order, being synthetic in the original order

    ;
END;
$function$
;