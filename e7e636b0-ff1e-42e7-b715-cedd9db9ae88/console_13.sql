-- DROP FUNCTION dash360.report_fintech_adh_occ_contra(int4, int4, _int4, _varchar);

CREATE OR REPLACE FUNCTION dash360.report_fintech_adh_occ_contra(p_start_date_id integer DEFAULT NULL::integer,
                                                                 p_end_date_id integer DEFAULT NULL::integer,
                                                                 p_account_ids integer[] DEFAULT '{}'::integer[],
                                                                 p_trading_firm_ids character varying[] DEFAULT '{}'::character varying[])
    RETURNS TABLE
            (
                export_row text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
  select_stmt     text;
  sql_params      text;
  l_row_cnt       integer;

  l_start_date_id  integer;
  l_end_date_id    integer;
  l_gtc_start_date_id integer;

   l_load_id        integer;
   l_step_id        integer;

  l_trading_firm_ids    character varying[];
  l_account_ids    integer[];

begin

  /* https://dashfinancial.atlassian.net/browse/DEVREQ-2460 */

  select nextval('public.load_timing_seq') into l_load_id;
  l_step_id:=1;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_adh_occ_contra STARTED===', 0, 'O')
   into l_step_id;


  l_trading_firm_ids := p_trading_firm_ids;


  select array_agg(account_id)
    into l_account_ids
  from genesis2.account
  where 1<>1
    or case when p_trading_firm_ids <> '{}'::varchar[] then trading_firm_id = ANY (l_trading_firm_ids) end
    or case when p_account_ids <> '{}'::integer[] then account_id = ANY (p_account_ids) end
  ;


  if p_start_date_id is not null and p_end_date_id is not null
  then
    l_start_date_id := p_start_date_id;
    l_end_date_id := p_end_date_id;
  else
    l_start_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
    l_end_date_id := (to_char(NOW(), 'YYYYMMDD'))::integer;
  end if;


    select public.load_log(l_load_id, l_step_id, left(' p_account_ids = '||coalesce(p_account_ids::varchar,''), 200), cardinality(p_account_ids), 'O')
   into l_step_id;

    select public.load_log(l_load_id, l_step_id, left(' l_trading_firm_ids = '||coalesce(l_trading_firm_ids::varchar,''), 200), cardinality(l_trading_firm_ids), 'O')
   into l_step_id;

    select public.load_log(l_load_id, l_step_id, left(' l_account_ids = '||coalesce(l_account_ids::varchar,''), 200), cardinality(l_account_ids), 'O')
   into l_step_id;

    select public.load_log(l_load_id, l_step_id, ' Period: l_start_date_id = '||l_start_date_id::varchar||', l_end_date_id = '||l_end_date_id::varchar, 0, 'O')
   into l_step_id;

   RETURN QUERY
    select 'trading_firm_name,account_name,trade_record_id,trade_id,date_id,rpt_id,previously_reported,last_qty,last_px,trans_type,report_type,trade_type,trade_sub_type,clearing_business_date,match_status,symbol,put_call,maturity_date,strike_px,mic_code,side,input_device,open_close,optional_data,secondary_order_id,capacity,exchange_optional_data,linkage_originating_exch,multileg_reporting_type,secondary_exch_exec_id,clearing_member_number,account_type,subaccount_originator,gup_clearing_firm_originator,exec_broker_originator,customer_acct_originator,exec_time_originator,contra_side,contra_open_close,contra_optionaldata,contra_secondary_order_id,contra_custcapacity,contra_exchangeoptionaldata,contra_multileg_reporting_type,contra_seconday_exch_exec_id,contra_clearing_member_number,contra_account_type,contra_subaccount,contra_gup_clearing_firm,contra_exec_broker,exec_time_contra' as roe
    union all
    select
      coalesce(s.trading_firm_name::varchar, '')                  ||','||  --
      coalesce(s.account_name::varchar, '')                       ||','||  --
      coalesce(s.trade_record_id::varchar, '')                    ||','||  --
      coalesce(s.trade_id::varchar, '')                           ||','||  --
      coalesce(s.date_id::varchar, '')                            ||','||  --
      coalesce(s.rpt_id::varchar, '')                             ||','||  --
      coalesce(s.previously_reported::varchar, '')                ||','||  --
      coalesce(s.last_qty::varchar, '')                           ||','||  --
      coalesce(s.last_px::varchar, '')                            ||','||  --
      coalesce(s.trans_type::varchar, '')                         ||','||  --
      coalesce(s.report_type::varchar, '')                        ||','||  --
      coalesce(s.trade_type::varchar, '')                         ||','||  --
      coalesce(s.trade_sub_type::varchar, '')                     ||','||  --
      coalesce(s.clearing_business_date::varchar, '')             ||','||  --
      coalesce(s.match_status::varchar, '')                       ||','||  --
      coalesce(s.symbol::varchar, '')                             ||','||  --
      coalesce(s.put_call::varchar, '')                           ||','||  --
      coalesce(s.maturity_date::varchar, '')                      ||','||  --
      coalesce(s.strike_px::varchar, '')                          ||','||  --
      coalesce(s.mic_code::varchar, '')                           ||','||  --
      coalesce(s.side::varchar, '')                               ||','||  --
      coalesce(s.input_device::varchar, '')                       ||','||  --
      coalesce(s.open_close::varchar, '')                         ||','||  --
      coalesce(s.optional_data::varchar, '')                      ||','||  --
      coalesce(s.secondary_order_id::varchar, '')                 ||','||  --
      coalesce(s.capacity::varchar, '')                           ||','||  --
      coalesce(s.exchange_optional_data::varchar, '')             ||','||  --
      coalesce(s.linkage_originating_exch::varchar, '')           ||','||  --
      coalesce(s.multileg_reporting_type::varchar, '')            ||','||  --
      coalesce(s.secondary_exch_exec_id::varchar, '')             ||','||  --
      coalesce(s.clearing_member_number::varchar, '')             ||','||  --
      coalesce(s.account_type::varchar, '')                       ||','||  --
      coalesce(s.subaccount_originator::varchar, '')              ||','||  --
      coalesce(s.gup_clearing_firm_originator::varchar, '')       ||','||  --
      coalesce(s.exec_broker_originator::varchar, '')             ||','||  --
      coalesce(s.customer_acct_originator::varchar, '')           ||','||  --
      coalesce(to_char(s.exec_time_originator, 'YYYY-MM-DD HH24:MI:SS.MS')::varchar, '')               ||','||  --
      coalesce(s.contra_side::varchar, '')                        ||','||  --
      coalesce(s.contra_open_close::varchar, '')                  ||','||  --
      coalesce(s.contra_optionaldata::varchar, '')                ||','||  --
      coalesce(s.contra_secondary_order_id::varchar, '')          ||','||  --
      coalesce(s.contra_custcapacity::varchar, '')                ||','||  --
      coalesce(s.contra_exchangeoptionaldata::varchar, '')        ||','||  --
      coalesce(s.contra_multileg_reporting_type::varchar, '')     ||','||  --
      coalesce(s.contra_seconday_exch_exec_id::varchar, '')       ||','||  --
      coalesce(s.contra_clearing_member_number::varchar, '')      ||','||  --
      coalesce(s.contra_account_type::varchar, '')                ||','||  --
      coalesce(s.contra_subaccount::varchar, '')                  ||','||  --
      coalesce(s.contra_gup_clearing_firm::varchar, '')           ||','||  --
      coalesce(s.contra_exec_broker::varchar, '')                 ||','||  --
      coalesce(to_char(s.exec_time_contra, 'YYYY-MM-DD HH24:MI:SS.MS')::varchar, '')                            --

      as roe
    from
      (
        select ac.trading_firm_name
          , ac.account_name
          , tr.trade_record_id
          , otd.trade_id
          , otd.date_id
          , otd.rpt_id
          , otd.previously_reported
          --, otd.last_qty
          --, otd.last_px
          , tr.last_qty
          , tr.last_px
          , otd.trans_type
          , otd.report_type
          , otd.trade_type
          , otd.trade_sub_type
          , to_char(otd.clearing_business_date, 'YYYY-MM-DD') as clearing_business_date
          , otd.match_status
          , otd.symbol
          , (case when substring(otd.cfi, 1, 1) = 'O' then substring(otd.cfi, 2, 1) end) as put_call
          , to_char(otd.maturity_date, 'YYYY-MM-DD') as maturity_date
          , otd.strike_px
          , otd.mic_code
          , otd.side
          , otd.input_device
          , otd.open_close
          , otd.optional_data
          , otd.secondary_order_id
          , otd.capacity
          , otd.exchange_optional_data
          , otd.linkage_originating_exch
          , otd.multileg_reporting_type
          , otd.secondary_exch_exec_id
          , otd.clearing_member_number
          , otd.account_type
          , otd.subaccount_originator
          , otd.gup_clearing_firm_originator
          , otd.exec_broker_originator
          , otd.customer_acct_originator
          , coalesce(otd.exec_time_originator, otd.trade_record_time) as exec_time_originator
          , (case when rest.is_restricted then null else otd.contra_side end) as contra_side
          , (case when rest.is_restricted then null else otd.contra_open_close end) as contra_open_close
          , (case when rest.is_restricted then null else otd.contra_optionaldata end) as contra_optionaldata
          , (case when rest.is_restricted then null else otd.contra_secondary_order_id end) as contra_secondary_order_id
          , (case when rest.is_restricted then null else otd.contra_custcapacity end) as contra_custcapacity
          , (case when rest.is_restricted then null else otd.contra_exchangeoptionaldata end) as contra_exchangeoptionaldata
          , (case when rest.is_restricted then null else otd.contra_multileg_reporting_type end) as contra_multileg_reporting_type
          , (case when rest.is_restricted then null else otd.contra_seconday_exch_exec_id end) as contra_seconday_exch_exec_id
          , (case when rest.is_restricted then null else otd.contra_clearing_member_number end) as contra_clearing_member_number
          , (case when rest.is_restricted then null else otd.contra_account_type end) as contra_account_type
          , (case when rest.is_restricted then null else otd.contra_subaccount end) as contra_subaccount
          , (case when rest.is_restricted then null else otd.contra_gup_clearing_firm end) as contra_gup_clearing_firm
          , (case when rest.is_restricted then null else otd.contra_exec_broker end) as contra_exec_broker
          , (case when rest.is_restricted then null else coalesce(otd.exec_time_contra, otd.trade_record_time) end) as exec_time_contra
        from genesis2.trade_record tr
          inner join lateral
            (
              select otdm.date_id, otdm.trade_record_id, otdm.rpt_id, otdm.trade_id
              from occ_data.occ_trade_data_matching otdm
              where otdm.trade_record_id = tr.trade_record_id
                and otdm.date_id = tr.date_id
                and otdm.date_id between l_start_date_id and l_end_date_id -- 20220914 and 20220914 --
              limit 100500 -- each trade can have different trade_id values
            ) otdm on true
          inner join lateral
            (
              select otd.*
              from occ_data.occ_trade_data otd
              where otd.trade_id = otdm.trade_id
                and otd.date_id = otdm.date_id
                and otd.date_id between l_start_date_id and l_end_date_id -- 20220914 and 20220914 --
              limit 100500 --
            ) otd on true
          left join lateral
            (
              select true as is_restricted
              from occ_data.contra_occ_trade_data_matching cotdm
              where cotdm.trade_id = otdm.trade_id
                and cotdm.date_id = otdm.date_id
                and cotdm.rpt_id = otdm.rpt_id
              limit 1
            ) rest on true
          left join
            (
              select ac.account_id
                , ac.account_name
                , tf.trading_firm_name
                , row_number() over (partition by ac.account_id order by tf.trading_firm_id) as rn -- dedupl, just in case we not limit deleted trading firms
              from genesis2.account ac
                left join genesis2.trading_firm tf on tf.trading_firm_id = ac.trading_firm_id
            ) ac on ac.account_id = tr.account_id and ac.rn=1
        where 1=1
          and tr.is_busted = 'N'
          and tr.date_id between l_start_date_id and l_end_date_id -- 20220914 and 20220914 --
          --and tr.account_id in (select account_id from genesis2.account where trading_firm_id = ANY (l_trading_firm_ids)) -- in ('scalptrad', 'eroom01', 'OFP0021', 'eroomht')
          and tr.account_id = ANY (l_account_ids)
        order by tr.trade_record_id
      ) s
    ;

   select public.load_log(l_load_id, l_step_id, 'dash360.report_fintech_adh_occ_contra COMPLETE===', coalesce(l_row_cnt,0), 'O')
   into l_step_id;

end;
$function$
;
