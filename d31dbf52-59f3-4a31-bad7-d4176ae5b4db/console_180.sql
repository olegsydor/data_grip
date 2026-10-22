create function consolidator.get_reping_rejection(in_rfr_id varchar(128), in_cons_message_id int8,
                                                  in_start_date_id int4 default null, in_end_date_id int4 default null)
    returns int
    language plpgsql
as
$fx$
declare
    l_start_date_id int4  := coalesce(in_start_date_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_end_date_id   int4  := coalesce(in_end_date_id, l_start_date_id);
    l_ret_val       jsonb := '{}'::jsonb;
    l_ret_val       int4;
begin
    if exists (select null
               from consolidator.consolidator_message
               where true
                 and rfr_id = in_rfr_id
                 and cons_message_id = in_cons_message_id
                 and date_id between l_start_date_id and l_end_date_id
                 and message_type = 15) then
--         select jsonb_agg(
--                        jsonb_build_object('Rejection reason', case srr.rejection_reason
--                                                                   when 0 then 'Generic exception'
--                                                                   when 1
--                                                                       then 'Original customer order was finalized already'
--                                                                   when 2
--                                                                       then 'Marketable instruction is being executed for the order'
--                                                                   when 3 then 'Order was sent to SOR'
--                                                                   when 4
--                                                                       then 'Original customer order was not found' end)
--                )
        select srr.rejection_reason
        into l_ret_val
        from consolidator.solicit_reping_rejection as srr
        where cons_message_id = in_cons_message_id
          and date_id between l_start_date_id and l_end_date_id;
    end if;
    return l_ret_val;

end;
$fx$;


with inp (c1, c2) as (values (0, 1),
                             (1, 1),
                             (2, 5),
                             (3, 4),
                             (4, 0))
select jsonb_agg(
               jsonb_build_object('Rejection reason', case c1
                                                          when 0 then 'Generic exception'
                                                          when 1 then 'Original customer order was finalized already'
                                                          when 2
                                                              then 'Marketable instruction is being executed for the order'
                                                          when 3 then 'Order was sent to SOR'
                                                          when 4 then 'Original customer order was not found' end)
       )
from inp