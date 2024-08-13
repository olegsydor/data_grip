select *,
 (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::time at time zone 'UTC' at time zone 'US/Eastern')::time
from trash.so_20240812_disc
where true
and msg_type not in('1', '5')
	        and case
                  when (to_timestamp(fix_date, 'YYYYMMDD-HH24:MI:SS')::time at time zone 'UTC' at time zone
                        'US/Eastern')::time > '16:40'::time then
                      msg_type not in ('9', 'F')
                  else true end


