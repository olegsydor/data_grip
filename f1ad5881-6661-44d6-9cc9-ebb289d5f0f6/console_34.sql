select srr.*
from consolidator.solicit_reping_rejection as srr;

select * from consolidator.consolidator_message
where true
--     and rfr_id = :in_rfr_id
-- and cons_message_id = :in_cons_message_id
-- and date_id between :in_start_date_id and :in_end_date_id
and message_type = 15;


create function consolidator.get_reping_rejection(in_rfr_id varchar(128), in_cons_message_id int8,
                                                  in_start_date_id int4 default null, in_end_date_id int4 default null)
    returns int
    language plpgsql
as
$fx$
    -- SO 20261022 https://dashfinancial.atlassian.net/browse/DS-12202
declare
    l_start_date_id int4 := coalesce(in_start_date_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_end_date_id   int4 := coalesce(in_end_date_id, l_start_date_id);
    l_ret_val       int4;
begin
    select srr.rejection_reason
    into l_ret_val
    from consolidator.solicit_reping_rejection as srr
             join lateral ( select null
                            from consolidator.consolidator_message cm
                            where cm.cons_message_id = srr.cons_message_id
                              and cm.date_id = srr.date_id
                              and rfr_id = in_rfr_id
                              and cons_message_id = in_cons_message_id
                              and date_id between l_start_date_id and l_end_date_id
                              and message_type = 15
                            limit 1) cm on true
    where cons_message_id = in_cons_message_id
      and date_id between l_start_date_id and l_end_date_id;
    return l_ret_val;

end;
$fx$;