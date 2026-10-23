select *
from dash360.get_reping_rejection_message_information(in_rfr_id := '7200541824215', in_cons_message_id := 106129276501,
                                       in_start_date_id := 20261002, in_end_date_id := 20261002);

drop function dash360.get_reping_rejection_message_information;
create function dash360.get_reping_rejection_message_information(in_rfr_id varchar(128), in_cons_message_id int8,
                                                                 in_start_date_id int4 default null,
                                                                 in_end_date_id int4 default null)
    returns table
            (
                rejection_reason int2
            )
    language plpgsql
as
$fx$
    -- SO 20261022 https://dashfinancial.atlassian.net/browse/DS-12202
declare
    l_start_date_id int4 := coalesce(in_start_date_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_end_date_id   int4 := coalesce(in_end_date_id, l_start_date_id);

begin
    return query
        select srr.rejection_reason
        from consolidator.solicit_reping_rejection as srr
                 join lateral ( select null
                                from consolidator.consolidator_message cm
                                where cm.cons_message_id = srr.cons_message_id
                                  and cm.date_id = srr.date_id
                                  and cm.rfr_id = in_rfr_id
                                  and cm.cons_message_id = in_cons_message_id
                                  and cm.date_id between l_start_date_id and l_end_date_id
                                  and cm.message_type = 15
                                limit 1) cm on true
        where srr.cons_message_id = in_cons_message_id
          and srr.date_id between l_start_date_id and l_end_date_id;
end;
$fx$;



drop function if exists dash360.get_order_finalized_message_information;
create function dash360.get_order_finalized_message_information(in_rfr_id varchar(128), in_cons_message_id int8,
                                                                in_start_date_id int4 default null,
                                                                in_end_date_id int4 default null)
    returns table
            (
                message_timestamp timestamp,
                order_status      char,
                executed_volume   int4,
                avg_px            numeric(16, 8),
                cancel_reason     int2
            )
    language plpgsql
as
$fx$
    -- SO 20261023 https://dashfinancial.atlassian.net/browse/DS-12200
declare
    l_start_date_id int4 := coalesce(in_start_date_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_end_date_id   int4 := coalesce(in_end_date_id, l_start_date_id);
begin
    return query
        select cm.message_timestamp,
               of.order_status,
               of.executed_volume,
               of.avg_px,
               of.cancel_reason
        from consolidator.order_finilized as of
                 join lateral ( select cm.message_timestamp
                                from consolidator.consolidator_message cm
                                where cm.cons_message_id = of.cons_message_id
                                  and cm.date_id = of.date_id
                                  and cm.rfr_id = in_rfr_id
                                  and cm.cons_message_id = in_cons_message_id
                                  and cm.date_id between l_start_date_id and l_end_date_id
                                  and cm.message_type = 16
                                limit 1) cm on true
        where of.cons_message_id = in_cons_message_id
          and of.date_id between l_start_date_id and l_end_date_id;

end;
$fx$;


drop function if exists dash360.get_ofp_trade_message_information;
create or replace function dash360.get_ofp_trade_message_information(in_rfr_id varchar(128), in_cons_message_id int8,
                                                                     in_start_date_id int4 default null,
                                                                     in_end_date_id int4 default null)
    returns table
            (
                trade_id                    int8,
                request_number              int2,
                security_type               char,
                symbol                      varchar(10),
                call_put_identifier         char,
                expiration                  int4,
                strike                      numeric(16, 8),
                side                        char,
                volume                      int4,
                price                       numeric(16, 8),
                open_close                  char,
                exchange                    int2,
                trade_time                  timestamp(6),
                contra_broker               char(5),
                contra_trader               char(5),
                contra_capacity             char,
                contra_open_close           char,
                contra_cross_type           char,
                contra_time_in_force        char,
                contra_covered_or_uncovered char,
                contra_clearing_account     char,
                contra_market_maker         char

            )
    language plpgsql
as
$fx$
    -- SO 20261023 https://dashfinancial.atlassian.net/browse/DS-12199
declare
    l_start_date_id int4 := coalesce(in_start_date_id, to_char(current_date, 'YYYYMMDD')::int4);
    l_end_date_id   int4 := coalesce(in_end_date_id, l_start_date_id);
begin
    return query
        select ofp.trade_id,
               cm.request_number,
               ofp.security_type,
               ofp.symbol,
               ofp.call_put_identifier,
               ofp.expiration,
               ofp.strike,
               ofp.side,
               ofp.volume,
               ofp.price,
               ofp.open_close,
               ofp.exchange,
               ofp.trade_time,
               ofp.contra_broker,
               ofp.contra_trader,
               ofp.contra_capacity,
               ofp.contra_open_close,
               ofp.contra_cross_type,
               ofp.contra_time_in_force,
               ofp.contra_covered_or_uncovered,
               ofp.contra_clearing_account,
               ofp.contra_market_maker
        from consolidator.ofp_trade as ofp
                 join lateral ( select cm.request_number
                                from consolidator.consolidator_message cm
                                where cm.cons_message_id = ofp.cons_message_id
                                  and cm.date_id = ofp.date_id
                                  and cm.rfr_id = in_rfr_id
                                  and cm.cons_message_id = in_cons_message_id
                                  and cm.date_id between l_start_date_id and l_end_date_id
                                  and cm.message_type = 13
                                limit 1) cm on true
        where ofp.cons_message_id = in_cons_message_id
          and ofp.date_id between l_start_date_id and l_end_date_id;

end;
$fx$;
