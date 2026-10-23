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


select *
from consolidator.get_order_finalized(in_rfr_id := '7200541824215', in_cons_message_id := 106129276501,
                                       in_start_date_id := 20261002, in_end_date_id := 20261002);

create function consolidator.get_order_finalized(in_rfr_id varchar(128), in_cons_message_id int8,
                                                 in_start_date_id int4 default null, in_end_date_id int4 default null)
    returns table
            (
                "Timestamp"       timestamp,
                "Order status"    char,
                "Executed volume" int4,
                "Average price"   numeric(16, 8),
                "Cancel reason"   int2
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
                 join lateral ( select message_timestamp
                                from consolidator.consolidator_message cm
                                where cm.cons_message_id = of.cons_message_id
                                  and cm.date_id = of.date_id
                                  and rfr_id = in_rfr_id
                                  and cons_message_id = in_cons_message_id
                                  and date_id between l_start_date_id and l_end_date_id
                                  and message_type = 16
                                limit 1) cm on true
        where cons_message_id = in_cons_message_id
          and date_id between l_start_date_id and l_end_date_id;

end;
$fx$;

select *
from consolidator.get_ofp_trade_message(in_rfr_id := '7200541824215', in_cons_message_id := 106129276501,
                                       in_start_date_id := 20261002, in_end_date_id := 20261002);

create or replace function consolidator.get_ofp_trade_message(in_rfr_id varchar(128), in_cons_message_id int8,
                                                   in_start_date_id int4 default null, in_end_date_id int4 default null)
    returns table
            (
                "Trade ID"                    int8,
                "Request number"              int2,
                "Security type"               char,
                "Symbol"                      varchar(10),
                "Call/Put identifier"         char,
                "Expiration"                  int4,
                "Strike"                      numeric(16, 8),
                "Buy/Sell indicator"          char,
                "Volume"                      int4,
                "Price"                       numeric(16, 8),
                "Open/close"                  char,
                "Exchange"                    int2,
                "Trade time"                  timestamp(6),
                "Contra broker"               char(5),
                "Contra trader"               char(5),
                "Contra capacity"             char,
                "Contra open/close"           char,
                "Contra cross type"           char,
                "Contra time in force"        char,
                "Contra covered or uncovered" char,
                "Contra clearing account"     char,
                "Contra market maker"         char

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
                 join lateral ( select request_number
                                from consolidator.consolidator_message cm
                                where cm.cons_message_id = ofp.cons_message_id
                                  and cm.date_id = ofp.date_id
                                  and rfr_id = in_rfr_id
                                  and cons_message_id = in_cons_message_id
                                  and date_id between l_start_date_id and l_end_date_id
                                  and message_type = 13
                                limit 1) cm on true
        where cons_message_id = in_cons_message_id
          and date_id between l_start_date_id and l_end_date_id;

end;
$fx$;


alter function consolidator.get_reping_rejection set schema dash360;
alter function consolidator.get_ofp_trade_message set schema dash360;
alter function consolidator.get_order_finalized set schema dash360;

alter function dash360.get_reping_rejection rename to get_reping_rejection_message_information;
alter function dash360.get_ofp_trade_message rename to get_ofp_trade_message_information;
alter function dash360.get_order_finalized rename to get_order_finalized_message_information;