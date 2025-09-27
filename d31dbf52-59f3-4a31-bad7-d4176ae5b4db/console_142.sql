SELECT last_px, last_qty, *
FROM dwh.execution ex
WHERE (exec_date_id = 20250924 AND ex.is_busted = 'N' AND ex.exec_type NOT IN ('E', 'S', 'D', 'y'))
  AND last_qty IS NULL
  AND exec_type <> 'F'
  AND order_status = '2'

