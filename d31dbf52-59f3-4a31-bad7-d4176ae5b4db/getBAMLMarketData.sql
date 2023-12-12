select * from dash360.get_baml_market_data(in_date_id := 20231204)
create function dash360.get_baml_market_data(in_date_id int4)
    returns table
            (
                ret_row text
            )
    language plpgsql
as
$fx$
begin
    return query
        select 'Cl Ord ID,Routed Date,Routed Time,Exchange,Price,Size';

    return query
        select array_to_string(array [
                                   str.client_order_id,
                                   to_char(str.process_time, 'YYYYMMDD'),
                                   to_char(str.process_time, 'HH24:MI:SS.FF6'),
                                   md.exchange_id,
                                   to_char(case when str.side = '1' then md.bid_price else md.ask_price end,
                                           'FM999999.0099'),
                                   case when str.side = '1' then md.bid_quantity::text else ask_quantity::text end
                                   ], ',', '')
        from dwh.client_order str
                 inner join dwh.mv_active_account_snapshot ac on (str.account_id = ac.account_id)
                 inner join dwh.d_instrument i on (str.instrument_id = i.instrument_id)
                 left join lateral (select l1.exchange_id, bid_price, bid_quantity, ask_price, ask_quantity
                                    from dwh.l1_snapshot l1
                                    where l1.transaction_id = str.transaction_id
                                      and str.create_date_id = l1.start_date_id
                                    limit 1) md on true
        where str.parent_order_id is not null
          and str.multileg_reporting_type = '1'
          and str.trans_type <> 'F'
          and str.create_date_id = in_date_id
          and ac.trading_firm_id = 'baml'
          and exists (select 1
                      from dwh.execution
                      where order_id = str.order_id
                        and exec_type = 'F'
                        and exec_date_id = in_date_id)
          and i.instrument_type_id = 'O'
        order by 1;
end;
$fx$;

select array_to_string(ARRAY [
                                   put_call::text,
                                   symbol,
                                   report_id::text,
                                   c_canceled::text,
                                   contra_give_cmta::text,
                                   trade_date_time::text,
                                   account_name,
                                   parent_client_order_id
                                   ], ',', '')
        from genesis2.occ_trade_data