-- DROP FOREIGN TABLE staging.ex_destination_code;
/*
IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (EX_DESTINATION_CODE)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (RISK_MGMT_TOUCH_TYPE)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (RISK_MGMT_TOUCH_TYPE)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (RISK_MGMT_TOUCH_TYPE)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (acct_comm_opt_rate)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (acct_comm_symbol_list)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (symbol2acct_comm_symbol_list)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (tf2acct_comm_symbol_list)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (acct_comm_opt_premium_tier)
FROM SERVER oracle_prod INTO staging;

IMPORT FOREIGN SCHEMA "GENESIS2_QA_20100601" LIMIT TO (acct_comm_eqt_rate)
FROM SERVER oracle_prod INTO staging;
*/


create or replace function genesis2.get_client_commission_rate(
    in_exchange_id VARCHAR,
    in_symbol VARCHAR,
    in_instrument_type CHAR,
    in_account_id int8,
    in_trading_session_type CHAR,
    in_price numeric,
    in_symbol_suffix varchar default null,
    in_rate_type_id varchar default null,
    in_forced_flow_type char default null
)
    RETURNs numeric
    language plpgsql
as
$fn$
declare
    l_touch_type_id      char;
    l_rate               numeric(16, 8);
    -- 20260119 SO https://dashfinancial.atlassian.net/browse/DS-10947 is expected to used instead of GET_COMMISSION_RATE
    -- 20260604 SO https://dashfinancial.atlassian.net/browse/DS-11623 moving to pg

    l_symbol_list_id_cnt int4;

BEGIN
    -- 1. GET TOUCH_TYPE_ID
    if in_forced_flow_type is null then
        select c.touch_type_id
        into l_touch_type_id
        from exchange e
                 join genesis2.d_ex_destination d on d.exchange_id = e.exchange_id
                 join staging.ex_destination_code c on c.ex_destination_code = d.ex_destination_code
                 join staging.risk_mgmt_touch_type t on c.touch_type_id = t.touch_type_id
        where e.is_deleted = 'N'
          and e.is_active = 'Y'
          and d.is_active = 'Y'
          and c.is_deleted = 'N'
          and e.exchange_id = in_exchange_id
        limit 1;
    else
        l_touch_type_id := in_forced_flow_type;
    end if;

    -- 2. GET symbol_list_id
    drop table if exists tmp_symbol_list;
    create temp table tmp_symbol_list as
    select optr.symbol_list_id
    from staging.acct_comm_opt_rate optr
             join staging.acct_comm_symbol_list sl on optr.symbol_list_id = sl.symbol_list_id
             join staging.symbol2acct_comm_symbol_list asl on asl.symbol_list_id = sl.symbol_list_id
             join staging.tf2acct_comm_symbol_list tfsl on tfsl.symbol_list_id = sl.symbol_list_id
             join trading_firm tf on tf.trading_firm_id = tfsl.trading_firm_id
             join account ac on ac.trading_firm_id = tf.trading_firm_id
    where sl.is_deleted = 'N'
      and asl.symbol = in_symbol
      and case
              when in_symbol_suffix is null
                  then coalesce(asl.symbol_suffix, 'no-suffix')
              else in_symbol_suffix end = coalesce(asl.symbol_suffix, 'no-suffix')
      and sl.instrument_type_id = in_instrument_type
      and ac.account_id = in_account_id;

    -- 3. GET rate
    if in_instrument_type = 'O' then
        select count(*)
        into l_symbol_list_id_cnt
        from tmp_symbol_list;

        select rate
        into l_rate
        from (select *
              from (select 1 as prioritet,
                           optr.rate,
                           prt.min_price
                    from staging.acct_comm_opt_rate optr
                             join staging.acct_comm_opt_premium_tier prt on prt.tier_id = optr.tier_id
                    where true
                      and optr.account_id = in_account_id
                      and optr.touch_type_id = l_touch_type_id
                      and optr.trading_session_type = in_trading_session_type
                      and case when in_rate_type_id is null then optr.rate_type_id else in_rate_type_id end =
                          optr.rate_type_id
                      and case
                              when l_symbol_list_id_cnt > 0 and optr.symbol_list_id in
                                                                (select symbol_list_id
                                                                 from tmp_symbol_list)
                                  then true
                              when l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then true
                              else false end
                      and prt.min_price <= in_price

                    union all

                    select 2 as prioritet,
                           optr.rate,
                           prt.min_price
                    from staging.acct_comm_opt_rate optr
                             join staging.acct_comm_opt_premium_tier prt ON prt.tier_id = optr.tier_id
                    where optr.account_id = in_account_id
                      and optr.touch_type_id = l_touch_type_id
                      and optr.trading_session_type = in_trading_session_type
                      and case when in_rate_type_id is null then optr.rate_type_id else in_rate_type_id end =
                          optr.rate_type_id
                      and l_symbol_list_id_cnt > 0
                      and optr.symbol_list_id is null
                      and prt.min_price <= in_price) x
              order by prioritet, x.min_price desc) y
        limit 1;
    else

        SELECT count(*)
        INTO l_symbol_list_id_cnt
        FROM tmp_symbol_list;

        select rate
        into l_rate
        from (select --1 as prioritet,
                     optr.rate
              from staging.acct_comm_eqt_rate optr

              where optr.account_id = in_account_id
                and optr.touch_type_id = l_touch_type_id
                and case
                        when l_symbol_list_id_cnt > 0 and optr.symbol_list_id in
                                                          (select symbol_list_id
                                                           from tmp_symbol_list)
                            then 1
                        when l_symbol_list_id_cnt = 0 and optr.rate_scope = 'G' then 1
                        else 0 end = 1
              order by optr.symbol_list_id nulls last) x
        limit 1;

    end if;

    return l_rate;
end;
$fn$;


SELECT GENESIS2.get_client_commission_rate('MXOP', 'TSLA', 'O', 263743, 'R', 55.1, null, 'OSL', 'L') AS commission_rate;
