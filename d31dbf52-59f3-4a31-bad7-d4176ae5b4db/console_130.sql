-- DROP FUNCTION dwh.get_root_order_id(int8);

CREATE OR REPLACE FUNCTION dwh.get_root_order_id(order_id_in bigint)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
-- 2025-03-20 [Oleskii Haram] Moved from trash schema (original name: trash.ob_get_root_order_id). Used in client_order_today.py tool.
DECLARE
    root_order_id BIGINT;
BEGIN
    -- Use a recursive CTE to walk up the order tree based on client_order
    WITH RECURSIVE up_tree AS (
        -- Start with the given order_id
        SELECT
            co.order_id,
            co.orig_order_id,
            co.parent_order_id,
            co.multileg_order_id,
			co.create_date_id
        FROM dwh.client_order co
        WHERE co.order_id = order_id_in

        UNION ALL

        -- Recursively walk up the tree using the three relationships
        SELECT
            parent_co.order_id,
            parent_co.orig_order_id,
            parent_co.parent_order_id,
            parent_co.multileg_order_id,
			parent_co.create_date_id
        FROM dwh.client_order parent_co
        JOIN up_tree ut
            ON ( parent_co.order_id = ut.orig_order_id
            OR parent_co.order_id = ut.parent_order_id
            OR parent_co.order_id = ut.multileg_order_id )
			AND parent_co.order_id != ut.order_id
			AND parent_co.create_date_id <= ut.create_date_id
    )
    -- Find the top-most order (the one with NULL orig_order_id, parent_order_id, and multileg_order_id)
    SELECT ut.order_id INTO root_order_id
    FROM up_tree ut
    WHERE ut.orig_order_id IS NULL
      AND ut.parent_order_id IS NULL
      AND ut.multileg_order_id IS NULL
    LIMIT 1;

    -- Return the found root_order_id
    RETURN root_order_id;
END;
$function$
;

-- DROP FUNCTION dwh.collect_root_order_tree_but_street(int8);

create function trash.collect_root_order_tree_but_street(root_order_id bigint)
    returns table
            (
                order_id                bigint,
                create_date_id          integer,
                create_time             timestamp without time zone,
                client_order_id         character varying,
                orig_order_id           bigint,
                parent_order_id         bigint,
                multileg_order_id       bigint,
                leg_ref_id              character varying,
                fix_message_id          bigint,
                source_type             character varying,
                multileg_reporting_type character,
                trans_type              character,
                time_in_force_id        character
            )
    LANGUAGE plpgsql
AS $function$
-- 2025-03-20 [Oleskii Haram] Moved from trash schema (original name: trash.ob_collect_root_order_tree_but_street). Used in dwh.collect_order_exec_tree_from_root_but_street_no_fixmsg().
BEGIN
    RETURN QUERY
        select * from dwh.client_order
    where create_date_id = 20250403
    and orig_order_id is not null
    and parent_order_id is not null
    and time_in_force_id in ('1', '6');


EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
    WITH RECURSIVE down_tree AS (
        -- Step 1: Start with the given root_order_id
        SELECT
            co.order_id,
            co.create_date_id,
            co.create_time,
            co.client_order_id,
            co.orig_order_id,
            co.parent_order_id,
            co.multileg_order_id,
            co.co_client_leg_ref_id as leg_ref_id,
            co.fix_message_id,
			'co'::VARCHAR as source_type,
			co.multileg_reporting_type,
			co.trans_type,
			co.time_in_force_id
        FROM dwh.client_order co
        WHERE co.order_id = :root_order_id

        UNION ALL

        -- Step 2: Recursively walk down the tree using orig_order_id, parent_order_id, and multileg_order_id
        SELECT
            chd.order_id,
            chd.create_date_id,
            chd.create_time,
            chd.client_order_id,
            chd.orig_order_id,
            chd.parent_order_id,
            chd.multileg_order_id,
            chd.co_client_leg_ref_id as leg_ref_id,
            chd.fix_message_id,
            'co'::VARCHAR            as source_type,
            chd.multileg_reporting_type,
            chd.trans_type,
            chd.time_in_force_id
        FROM dwh.client_order chd
        JOIN down_tree base
            ON (chd.orig_order_id = base.order_id
                OR chd.parent_order_id = base.order_id
                OR chd.multileg_order_id = base.order_id )
			AND chd.order_id != base.order_id -- a fuse to prevent loop
            AND chd.create_date_id >= base.create_date_id  -- Prune based on create_date_id
		AND ( chd.parent_order_id is null
			OR (chd.trans_type in ('F', 'G') AND base.time_in_force_id in ('1', '6') AND chd.orig_order_id = base.order_id )
			OR chd.time_in_force_id in ('1','6'))
    )
-- 	,dedup as (
-- 	select *,
-- 		row_number() over (partition by down_tree.order_id rows between unbounded preceding and unbounded following /* down_tree.level */ ) as rn
-- 		from down_tree
-- 	)
    -- Step 3: Select all orders collected in the recursive down_tree CTE
    SELECT --distinct on (co.order_id)
        co.order_id,
            co.create_date_id,
            co.create_time,
            co.client_order_id,
            co.orig_order_id,
            co.parent_order_id,
            co.multileg_order_id,
            co.leg_ref_id,
            co.fix_message_id,
			co.source_type,
			co.multileg_reporting_type,
			co.trans_type,
			co.time_in_force_id
    FROM down_tree co
	where co.rn = 1;
END;
$function$
;


CREATE OR REPLACE FUNCTION dwh.collect_order_exec_tree_from_root_but_street_no_fixmsg(root_order_id_ bigint)
 RETURNS TABLE(order_id bigint, root_order_id bigint, event_date_id integer, event_time timestamp without time zone, client_order_id character varying, orig_order_id bigint, parent_order_id bigint, multileg_order_id bigint, leg_ref_id character varying, exec_id bigint, fix_message_id bigint, fix_message_text text, source_type character varying)
 LANGUAGE plpgsql
AS $function$
-- 2025-03-20 [Oleskii Haram] Moved from trash schema (original name: trash.ob_collect_order_exec_tree_from_root_but_street_no_fixmsg). Used in client_order_today.py tool.
BEGIN
RETURN QUERY
WITH co AS (
    SELECT DISTINCT
        tree.order_id,
        root_order_id_ as root_order_id,
        tree.create_date_id AS event_date_id,
        tree.create_time AS event_time,
        tree.client_order_id,
        tree.orig_order_id,
        tree.parent_order_id,
        tree.multileg_order_id,
        tree.leg_ref_id,
        NULL::BIGINT AS exec_id,
        tree.fix_message_id,
        -- NULL::TEXT AS fix_message_text,
        tree.source_type
    FROM dwh.collect_root_order_tree_but_street(root_order_id_) AS tree
)
,
co_ex as (
	SELECT
	    co.order_id,
	    co.root_order_id,
	    ex.exec_date_id AS event_date_id,
	    ex.exec_time AS event_time,
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

	SELECT
	    co.order_id,
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
	FROM co

)
,
co_ex_fm as (
	SELECT
	    co.order_id,
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
	    /*fmj.fix_message*/ ''::TEXT AS fix_message_text,
	    co.source_type,
		case when co.exec_id is null
			then 1
			else
				row_number() over (partition by co.fix_message_id rows between unbounded preceding and unbounded following)
			end as ern
	FROM co_ex co
--	LEFT JOIN LATERAL (
--	    SELECT fmj.fix_message
--	    FROM fix_capture.fix_message_json fmj
--	    WHERE fmj.fix_message_id = co.fix_message_id
--	    AND fmj.date_id = co.event_date_id
--		limit  1
--	) AS fmj ON true
) -- end co_ex_fm
SELECT
	    co.order_id,
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