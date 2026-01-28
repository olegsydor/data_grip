/*UPDATE dash360.user_layout_settings
SET payload =
    jsonb_set(
        jsonb_set(
            payload::jsonb,
            '{toolbarItems}',
            CASE
                WHEN payload::jsonb->'toolbarItems' ? 'view'
                THEN payload::jsonb->'toolbarItems'
                ELSE COALESCE(payload::jsonb->'toolbarItems', '[]'::jsonb)
                     || '"view"'::jsonb
            END,
            true
        ),
        '{pinnedItems}',
        CASE
            WHEN payload::jsonb->'pinnedItems' ? 'view'
            THEN payload::jsonb->'pinnedItems'
            ELSE COALESCE(payload::jsonb->'pinnedItems', '[]'::jsonb)
                 || '"view"'::jsonb
        END,
        true
    )::text
where application_id = 'orders'  and section_id = 'todays-blotter-section' and layout_name = 'todays-blotter-toolbar';

 */

 select
   payload::jsonb ||
     (case when NOT (payload::jsonb->'toolbarItems' ? 'view2') then (payload::jsonb->'toolbarItems')::jsonb || '["view2"]'::jsonb else payload::jsonb->'toolbarItems' end),
     payload::jsonb->'pinnedItems', --||'["view"]'::jsonb
  payload::jsonb
 from dash360.user_layout_settings
where application_id = 'orders'  and section_id = 'todays-blotter-section' and layout_name = 'todays-blotter-toolbar';

 select * from dash360.user_layout_settings