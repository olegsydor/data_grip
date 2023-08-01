drop function trash.dash360_imb_get_unmatched_trade_records;
CREATE FUNCTION trash.dash360_imb_get_unmatched_trade_records(in_start_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                              in_end_date_id integer DEFAULT get_dateid(CURRENT_DATE),
                                                              in_account_ids integer[] DEFAULT '{}'::integer[],
                                                              user_filter character varying DEFAULT NULL::character varying)
    RETURNS TABLE
            (
                trade_record_time   timestamp without time zone,
                trade_record_id     bigint,
                trading_firm_id     character varying,
                account_id          bigint,
                customer_type       character varying,
                symbol_osi          character varying,
                symbol              character varying,
                root_symbol         character varying,
                exp_date            date,
                strike_price        numeric,
                put_call            character,
                side                character,
                last_qty            integer,
                last_px             numeric,
                secondary_order_id  character varying,
                exec_broker         character varying,
                is_trade_electronic boolean,
                date_id             integer,
                cmta                character varying,
                exchange_id         character varying
            )
    LANGUAGE plpgsql
AS
$fx$
    -- sy 20210623 https://dashfinancial.atlassian.net/browse/ds-3563 initial creation
-- sy 20210723. https://dashfinancial.atlassian.net/browse/ds-3867. logic for last match time added to avoid showing data that we didn't try to match
-- SO 20210803. https://dashfinancial.atlassian.net/browse/DS-3863. Added new columns
-- PD 20210806. Changed logic for last match time
-- SY 20210816. Reverted filter to show 333 and 733
-- SY 20210827. https://dashfinancial.atlassian.net/browse/DS-4030 Removed filter on exec broker.
-- SY 20210902. https://dashfinancial.atlassian.net/browse/DS-4102. 20 min delay has been introduced
-- SY 20220308. Join to occ_trade_data has been removed
-- SO 20230801. https://dashfinancial.atlassian.net/browse/DS-7082 extended by user filter
declare

    l_last_match_time timestamp;
    l_instrument_id   int8;
    select_stmt       text;

begin

    select max(log_date) - 20 * interval '1 minute'
    into l_last_match_time
    from public.load_timing lt
    where table_name = 'OCC_TRADE_MATCH DONE >>>>>>>>>> ';

    select (regexp_match(user_filter, '\s+instrument_id\s*=\s*([0-9]+)'))[1]
    into l_instrument_id;

    create temp table t_imb_get_unmatched_trade_records on commit drop
    as
    select tr.instrument_id,
           tr.trade_record_time,
           tr.trade_record_id::bigint,
           acc.trading_firm_id,
           tr.account_id::bigint,
           null::varchar                                              as customer_type,
           oc.opra_symbol                                             as symbol_osi, --null::varchar as symbol_osi,
           i.display_instrument_id2                                   as symbol,     --i.symbol,
           os.root_symbol,--otd.symbol as root_symbol,
           to_date(oc.maturity_year::text || lpad(oc.maturity_month::text, 2, '0') ||
                   lpad(oc.maturity_day::text, 2, '0'), 'YYYYMMDD')   as Exp_Dat,
           oc.strike_price,
           oc.put_call,
           tr.side,
           tr.last_qty,
           tr.last_px,
           tr.secondary_order_id,
           tr.exec_broker,
           case tr.subsystem_id when 'LPEDW' then false else true end as is_trade_elecronic,
           tr.date_id,
           tr.cmta,
           tr.exchange_id
    from genesis2.trade_record tr
             inner join genesis2.instrument i on tr.instrument_id = i.instrument_id and i.instrument_type_id = 'O'
             inner join genesis2.option_contract oc on oc.instrument_id = tr.instrument_id
             inner join genesis2.option_series os on oc.option_series_id = os.option_series_id
             inner join genesis2.account acc on acc.account_id = tr.account_id
             left join occ_data.occ_trade_data_matching otdm
                       on otdm.date_id = tr.date_id and otdm.trade_record_id = tr.trade_record_id and
                          otdm.date_id between in_start_date_id and in_end_date_id
    where tr.date_id between in_start_date_id and in_end_date_id
      and tr.is_busted = 'N'
      and otdm.trade_record_id is null
      and tr.db_create_time < l_last_match_time
      and case when l_instrument_id is null then true else tr.instrument_id = l_instrument_id end;

    select_stmt = '
	 select trade_record_time,
	       trade_record_id,
	       trading_firm_id,
	       account_id,
	       customer_type,
	       symbol_osi,
		   symbol,
	       root_symbol,
	       Exp_Dat,
	       strike_price,
	       put_call ,
	       side,
	       last_qty,
	       last_px,
	       secondary_order_id,
	       exec_broker,
	       is_trade_elecronic,
	       date_id,
	       cmta,
	       exchange_id
	from t_imb_get_unmatched_trade_records
	where true ' || regexp_replace(user_filter, '(drop|truncate|delete)', '1/0', 'g');


    return query
        execute select_stmt;
end;
$fx$
;


select * from trash.dash360_imb_get_unmatched_trade_records(20230801, 20230801, null, 'and instrument_id = 102236954 and trade_record_time between ''2023-08-01 06:45:23.173000'' and ''2023-08-01 06:45:28.365000'' and account_id = 28878');
select * from trash.dash360_imb_get_unmatched_trade_records(20230801, 20230801, null, 'and trade_record_time between ''2023-08-01 06:45:23.173000'' and ''2023-08-01 06:45:28.365000'' and account_id = 28878');


select max(log_date) - 20 * interval '1 minute'
-- into l_last_match_time
from public.load_timing lt
where table_name ='OCC_TRADE_MATCH DONE >>>>>>>>>> ';


select i.instrument_id,
    tr.trade_record_time,
       tr.trade_record_id::bigint,
       acc.trading_firm_id,
       tr.account_id::bigint,
       null::varchar                                              as customer_type,
       oc.opra_symbol                                             as symbol_osi, --null::varchar as symbol_osi,
       i.display_instrument_id2                                   as symbol,     --i.symbol,
       os.root_symbol,--otd.symbol as root_symbol,
       to_date(oc.maturity_year::text || lpad(oc.maturity_month::text, 2, '0') || lpad(oc.maturity_day::text, 2, '0'),
               'YYYYMMDD')                                        as Exp_Dat,
       oc.strike_price,
       oc.put_call,
       tr.side,
       tr.last_qty,
       tr.last_px,
       tr.secondary_order_id,
       tr.exec_broker,
       case tr.subsystem_id when 'LPEDW' then false else true end as is_trade_elecronic,
       tr.date_id,
       tr.cmta,
       tr.exchange_id
from genesis2.trade_record tr
         inner join genesis2.instrument i on tr.instrument_id = i.instrument_id and i.instrument_type_id = 'O'
         inner join genesis2.option_contract oc on oc.instrument_id = tr.instrument_id
         inner join genesis2.option_series os on oc.option_series_id = os.option_series_id
         inner join genesis2.account acc on acc.account_id = tr.account_id
         left join occ_data.occ_trade_data_matching otdm
                   on otdm.date_id = tr.date_id and otdm.trade_record_id = tr.trade_record_id and
                      otdm.date_id between :in_start_date_id and :in_end_date_id
where tr.date_id between :in_start_date_id and :in_end_date_id
  and tr.is_busted = 'N'
  and otdm.trade_record_id is null
  and tr.db_create_time < :l_last_match_time;

RETURN QUERY

select regexp_matches('and instrument_id = 102236954 and trade_record_time between ''2023-08-01 06:45:23.173000'' and ''2023-08-01 06:45:28.365000'' and account_id = 28878'
select (regexp_match(:f_user_filter, '\s+instrument_id\s*=\s*([0-9]+)'))[1];


'and instdrument_id= 102236954 and iinstrument_id= 102236954 and f = 0 and oc = 2  and rc = 3'
select regexp_replace('drop truncate select', '(drop|truncate|delete)', '1/0', 'g')

select
select regexp_replace('and instrument_id = 102236954 and trade_record_time between ''2023-08-01 06:45:23.173000'' and ''2023-08-01 06:45:28.365000'' and account_id = 28878', '(drop|truncate|delete)', '1/0', 'g')