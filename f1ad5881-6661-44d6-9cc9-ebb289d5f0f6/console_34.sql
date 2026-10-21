select srr.*
from consolidator.solicit_reping_rejection as srr;

select * from consolidator.consolidator_message
where true
--     and rfr_id = :in_rfr_id
-- and cons_message_id = :in_cons_message_id
-- and date_id between :in_start_date_id and :in_end_date_id
and message_type = 15;
