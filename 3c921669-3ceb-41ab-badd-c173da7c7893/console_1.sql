select GENESIS2_QA_20100601.get_sg_account(256639, 'O', '733', 'EMLD')
from dual;

select GENESIS2_QA_20100601.get_sg_account(in_account_id => 263292, in_instrument_type => 'O', in_opt_exec_broker => '792', in_exchange_id => 'BOX')
from dual;

CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.get_sg_account(
    in_account_id NUMBER,
    in_instrument_type CHAR,
    in_opt_exec_broker VARCHAR2,
    in_exchange_id VARCHAR2
) RETURN varchar2
    is

    l_opt_customer_or_firm   varchar2(10);
    l_opt_is_fix_execbrok_pr varchar2(10);
    l_opt_is_fix_clfirm_pr   varchar2(10);
    l_opt_is_fix_custfirm_pr varchar2(10);
    l_new_model              char;
    l_trading_firm_id        varchar2(9);
    l_eq_mpid                varchar2(4);
    l_opt_occ_id             varchar2(40);
    l_clearing_firm          varchar2(40);
    l_sg_sub_account         varchar2(10);
    l_sg_mint_account        varchar2(20);
    l_sg_sales_trader_id     varchar2(20);
    l_opt_clearing_firm      varchar2(20);
    l_client_cust_or_firm    varchar2(20) := '';
    l_opt_exec_broker        varchar2(20);
    l_return                 varchar2(1500);

begin

    SELECT
        -- acc.ACCOUNT_NAME accountName,
        max(acc.OPT_CUSTOMER_OR_FIRM),
        max(acc.OPT_IS_FIX_EXECBROK_PROCESSED),
        max(acc.OPT_IS_FIX_CLFIRM_PROCESSED),
        max(acc.OPT_IS_FIX_CUSTFIRM_PROCESSED),
        max(acc.TRADING_FIRM_ID),
        max(acc.eq_mpid),
        max(acc.opt_occ_id),
        max(acc.USE_NEW_MODEL)
    into l_opt_customer_or_firm, l_opt_is_fix_execbrok_pr, l_opt_is_fix_clfirm_pr, l_opt_is_fix_custfirm_pr, l_trading_firm_id,
        l_eq_mpid, l_opt_occ_id, l_new_model
    FROM GENESIS2_QA_20100601.aCCOUNT acc
    WHERE 1 = 1
      and acc.ACCOUNT_ID = in_account_id;

    -- ExecBroker(76)

    IF l_opt_is_fix_execbrok_pr = 'N' THEN
        if l_new_model = 'Y' then
            SELECT max(OE.OPT_EXEC_BROKER)
            into l_opt_exec_broker
            FROM OPT_EXEC_BROKER_CONFIG OE
                     INNER JOIN ACCOUNT2OPT_EXEC_BROKER_CONFIG AO
                                on AO.OPT_EXEC_BROKER_CONFIG_ID = OE.OPT_EXEC_BROKER_CONFIG_ID
            WHERE OE.IS_DELETED = 'N'
              AND AO.ACCOUNT_ID = in_account_id
              AND AO.IS_DEFAULT = 'Y';
        else
            SELECT max(OPT_EXEC_BROKER)
            into l_opt_exec_broker
            FROM OPT_EXEC_BROKER OE
            WHERE OE.IS_DELETED = 'N'
              AND OE.ACCOUNT_ID = in_account_id
              AND OE.IS_DEFAULT = 'Y';
        end if;
    ELSE
        l_opt_exec_broker := 'null';

    end if;

-- II. CustomerOrFirm(204)
    IF coalesce(l_opt_is_fix_clfirm_pr, '-1') != 'N' THEN
        l_opt_is_fix_custfirm_pr := 'null';
    end if;

-- III. ClearingFirm(439)

    IF (in_instrument_type = 'E' or l_opt_is_fix_clfirm_pr != 'N' or in_opt_exec_broker is null) then
        l_clearing_firm := 'null';
    else
        if l_new_model = 'Y' then
            select max(tv.TAG_VALUE)--, abc.ACCOUNT_ID, ocp.EXCHANGE_ID,  obc.OPT_EXEC_BROKER
            into l_clearing_firm
            from GENESIS2_QA_20100601.OPT_EXEC_BROKER_CONFIG obc
                     join GENESIS2_QA_20100601.ACCOUNT2OPT_EXEC_BROKER_CONFIG abc
                          on abc.OPT_EXEC_BROKER_CONFIG_ID = obc.OPT_EXEC_BROKER_CONFIG_ID
                     join GENESIS2_QA_20100601.EXEC_BROKER_CONFIG2EXCH_PARAM ocp
                          on ocp.OPT_EXEC_BROKER_CONFIG_ID = obc.OPT_EXEC_BROKER_CONFIG_ID
                     join GENESIS2_QA_20100601.SPECIFIC_TAG_VALUE tv
                          on tv.SPECIFIC_TAG_SET_ID = ocp.SPECIFIC_TAG_SET_ID
            where 1 = 1
              and abc.ACCOUNT_ID = in_account_id
              and obc.OPT_EXEC_BROKER = l_opt_exec_broker
              and ocp.EXCHANGE_ID = in_exchange_id
              and abc.IS_DEFAULT = 'Y'
              and tv.TAG_NUMBER = 439;
        else
            select max(stv.TAG_VALUE)
            into l_clearing_firm
            from GENESIS2_QA_20100601.OPT_EXEC_BROKER_OLD od
                     join GENESIS2_QA_20100601.OPT_EXEC_BROKER2EXCH_PARAM_OLD ep
                          on ep.OPT_EXEC_BROKER_ID = od.OPT_EXEC_BROKER_ID
                     join GENESIS2_QA_20100601.SPECIFIC_TAG_VALUE stv
                          on stv.SPECIFIC_TAG_SET_ID = ep.SPECIFIC_TAG_SET_ID
            where od.ACCOUNT_ID = in_account_id
              and od.OPT_EXEC_BROKER = l_opt_exec_broker
              and ep.EXCHANGE_ID = in_exchange_id
              and od.IS_DEFAULT = 'Y'
              and stv.TAG_NUMBER = 439
              and od.is_deleted = 'N';
        end if;
    end if;


    --     IV. ActionableID(10440)


-- V. SG Account fields
    select MAX(coalesce(ch.SG_SUB_ACCOUNT, pa.SG_SUB_ACCOUNT)),
           MAX(coalesce(ch.SG_MINT_ACCOUNT, pa.SG_SUB_ACCOUNT)),
           MAX(coalesce(ch.SG_SALES_TRADER_ID, pa.SG_SUB_ACCOUNT))
--     into l_sg_sub_account, l_sg_mint_account, l_sg_sales_trader_id
    from GENESIS2_QA_20100601.SG_ACCOUNT ch
             left join GENESIS2_QA_20100601.SG_ACCOUNT pa
                       on pa.ACCOUNT_ID = ch.SG_PARENT_ACCOUNT_ID
    where ch.ACCOUNT_ID = in_account_id;

    select '{' ||
           '"OPT_IS_FIX_CLFIRM_PROCESSED": "' || l_opt_is_fix_clfirm_pr || '",' ||
           '"OPT_CLEARING_FIRM": "' || l_clearing_firm || '",' ||
           '"OPT_IS_FIX_CUSTFIRM_PROCESSED": "' || l_opt_is_fix_custfirm_pr || '",' ||
           '"OPT_CUST_OR_FIRM": "' || l_opt_customer_or_firm || '",' ||
           '"CLIENT_CUST_OR_FIRM": "' || l_client_cust_or_firm || '",' ||
           '"OPT_IS_FIX_EXECBROK_PROCESSED": "' || l_opt_is_fix_execbrok_pr || '",' ||
           '"OPT_EXEC_BROKER": "' || l_opt_exec_broker || '",' ||
           '"OPT_OCC_ID": "' || l_opt_occ_id || '",' ||
           '"SG_SUB_ACCOUNT": "' || l_sg_sub_account || '",' ||
           '"SG_MINT_ACCOUNT": "' || l_sg_mint_account || '",' ||
           '"SG_SALES_TRADER_ID": "' || l_sg_sales_trader_id ||
           '"}'
--select 'DATA'
    into l_return
    from dual;

    return l_return;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'NO DATA';
    WHEN OTHERS THEN
        RAISE;
END;



    select MAX(coalesce(ch.SG_SUB_ACCOUNT, case when :is_parent_sub_account = 'Y' then pa.SG_SUB_ACCOUNT end)),
           MAX(coalesce(ch.SG_MINT_ACCOUNT, case when :is_parent_mint_account = 'Y' then pa.SG_MINT_ACCOUNT end)),
           MAX(coalesce(ch.SG_SALES_TRADER_ID, case when :is_parent_sales_trader_id = 'Y' then pa.SG_SALES_TRADER_ID end))
    from GENESIS2_QA_20100601.SG_ACCOUNT ch
    left join GENESIS2_QA_20100601.SG_ACCOUNT pa  on pa.ACCOUNT_ID = ch.SG_PARENT_ACCOUNT_ID
    where ch.ACCOUNT_ID = 263209;


select *
    from GENESIS2_QA_20100601.SG_ACCOUNT ch
where ch.ACCOUNT_ID = 263209;

select max(case when DB_FIELD_NAME = 'SG_SUB_ACCOUNT' then 'Y' end),
       max(case when DB_FIELD_NAME = 'SG_MINT_ACCOUNT' then 'Y' end),
       max(case when DB_FIELD_NAME = 'SG_SALES_TRADER_ID' then 'Y' end)
into is_parent_sub_account, is_parent_mint_account, is_parent_sales_trader_id
from SG_NULL_ACCOUNT_PARAMETER
where acoount_id = in_account_id;



INSERT INTO LIQUIDITY_INDICATOR (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT",
                                 LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY)
VALUES ('SPHRF', 'M', 'Maker', NULL, 1, 'N');
INSERT INTO LIQUIDITY_INDICATOR (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT",
                                 LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY)
VALUES ('SPHRF', 'N', 'Not applicable', NULL, NULL, 'N');
INSERT INTO LIQUIDITY_INDICATOR (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, "COMMENT",
                                 LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY)
VALUES ('SPHRF', 'T', 'Taker', NULL, 2, 'N');



--------------------------------------------------------
 select * from
  update
    staging.SO_LIQ_IND
  set dash_liq_ind_type = 'Auction'
where 1 = 1
     and exchange_id = 'XPSX'
 and trade_liquidity_indicator in ('K')
  and dash_liq_ind_type = 'Add/Remove';

with stay as (select li.*
              from staging.SO_LIQ_IND so
                       join "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR_TYPE" LT
                            on upper(lt.liquidity_indicator_type) = upper(trim(so.dash_liq_ind_type))
                       join "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" LI
                            on so.exchange_id = li.exchange_id
                                and so.trade_liquidity_indicator = li.trade_liquidity_indicator
                                and so.description = li.description
                                and li.liquidity_indicator_type_id = lt.liquidity_indicator_type_id
                                and li.is_grey = so.is_grey)
--    , to_del as (
   select li.*
                from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" li
                         left join stay on stay.EXCHANGE_ID = li.EXCHANGE_ID
                    and stay.TRADE_LIQUIDITY_INDICATOR = li.TRADE_LIQUIDITY_INDICATOR
                    and stay.IS_GREY = li.IS_GREY
                    and stay.liquidity_indicator_type_id = li.liquidity_indicator_type_id
                where stay.EXCHANGE_ID is null
--                   and 1 = 2
    )
   , to_ins as (select so.exchange_id,
                       so.trade_liquidity_indicator,
                       so.description,
                       null,
                       lt.LIQUIDITY_INDICATOR_TYPE_ID,
                       so.is_grey,
                       SYSTIMESTAMP
                from staging.SO_LIQ_IND so
                         join "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR_TYPE" LT
                              on upper(lt.liquidity_indicator_type) = upper(trim(so.dash_liq_ind_type))
                         left join stay on stay.EXCHANGE_ID = so.EXCHANGE_ID
                    and stay.TRADE_LIQUIDITY_INDICATOR = so.TRADE_LIQUIDITY_INDICATOR
                    and stay.IS_GREY = so.IS_GREY
                    and stay.liquidity_indicator_type_id = lt.liquidity_indicator_type_id
                where stay.EXCHANGE_ID is null)
select *
from to_del
union all
select *
from to_ins

;
with base as (select listagg(so.EXCHANGE_ID, ', ') within group (order by so.exchange_id)
              from (select distinct exchange_id from staging.SO_LIQ_IND) so
                       )
select * from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" li
         join base on  li.EXCHANGE_ID = base.EXCHANGE_ID


select li.EXCHANGE_ID, li.TRADE_LIQUIDITY_INDICATOR as ind, li.DESCRIPTION as descr, li.LIQUIDITY_INDICATOR_TYPE_ID as type_id, lt.LIQUIDITY_INDICATOR_TYPE as type, li.IS_GREY
from staging.SO_LIQ_IND so
         join "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR_TYPE" LT
              on upper(lt.liquidity_indicator_type) = upper(trim(so.dash_liq_ind_type))
         join "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" LI
              on so.exchange_id = li.exchange_id
                  and so.trade_liquidity_indicator = li.trade_liquidity_indicator
                  and so.description = li.description
                  and li.liquidity_indicator_type_id = lt.liquidity_indicator_type_id
                  and li.is_grey = so.is_grey;

select * from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" li
where exists (select null from staging.SO_LIQ_IND so
                          join
                          where so.exchange_id = li.exchange_id
                  and so.trade_liquidity_indicator = li.trade_liquidity_indicator
                  and so.description = li.description

                  and li.is_grey = so.is_grey)


select * from STAGING.SO_LIQ_IND so
    where LIQ_IND_TYPE_ID is null;


join "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR_TYPE" LT on upper(lt.liquidity_indicator_type) = upper(trim(so.dash_liq_ind_type))
select * from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR_TYPE";

update STAGING.SO_LIQ_IND so
set LIQ_IND_TYPE_ID = (select liquidity_indicator_type_id from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR_TYPE" LT where upper(lt.liquidity_indicator_type) = upper(trim(so.dash_liq_ind_type)))


update STAGING.SO_LIQ_IND so
set LIQ_IND_TYPE_ID = 1
where LIQ_IND_TYPE_ID is null;

-- The new table was created from the CSV file
select * from staging.SO_LIQ_IND;
select * from T_STAY
select * from liquidity_indicator_bkp;
-- For existing rows that match with rows from CSV file
create table T_STAY
(
    EXCHANGE_ID                 VARCHAR2(6)                 not null,
    TRADE_LIQUIDITY_INDICATOR   VARCHAR2(256)               not null,
    DESCRIPTION                 VARCHAR2(256)               not null,
    "COMMENT"                   VARCHAR2(256),
    LIQUIDITY_INDICATOR_TYPE_ID NUMBER(2),
    IS_GREY                     CHAR,
    CREATE_TIME                 TIMESTAMP(3) WITH TIME ZONE not null
);
-- backup "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR"
    create table liquidity_indicator_bkp
    as
        select * from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR";

-- Existing rows
insert into t_stay
select li.*
from staging.SO_LIQ_IND so
         join "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" LI
              on so.exchange_id = li.exchange_id
                  and so.trade_liquidity_indicator = li.trade_liquidity_indicator
                  and so.description = li.description
                  and li.liquidity_indicator_type_id = so.LIQ_IND_TYPE_ID
                  and li.is_grey = so.is_grey;


-- Delete ALL records from liquidity_indicator related to these exchange_ids not matching
select *
-- delete
from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" li
where exchange_id in (select EXCHANGE_ID from staging.SO_LIQ_IND)
and not exists (select null from T_STAY so
                            where so.exchange_id = li.exchange_id
                  and so.trade_liquidity_indicator = li.trade_liquidity_indicator
                  and so.description = li.description
                  and li.liquidity_indicator_type_id = so.LIQUIDITY_INDICATOR_TYPE_ID
                  and li.is_grey = so.is_grey);


-- insert into "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" (EXCHANGE_ID, TRADE_LIQUIDITY_INDICATOR, DESCRIPTION, LIQUIDITY_INDICATOR_TYPE_ID, IS_GREY, CREATE_TIME)
select exchange_id, trade_liquidity_indicator, description, LIQ_IND_TYPE_ID, is_grey, sysdate
from staging.SO_LIQ_IND li
where not exists (select null from T_STAY so
                            where so.exchange_id = li.exchange_id
                  and so.trade_liquidity_indicator = li.trade_liquidity_indicator
                  and so.description = li.description
                  and li.LIQ_IND_TYPE_ID = so.LIQUIDITY_INDICATOR_TYPE_ID
                  and li.is_grey = so.is_grey);



select *--distinct so.exchange_id, so.TRADE_LIQUIDITY_INDICATOR
from staging.SO_LIQ_IND so
         left join "GENESIS2_QA_20100601".exchange ex
              on so.exchange_id = ex.exchange_id
where ex.EXCHANGE_ID is null;

update
    staging.SO_LIQ_IND so
set exchange_id = 'NYSE'
where EXCHANGE_ID = 'XNYS';


select so.*
from staging.SO_LIQ_IND so
         where not exists (select null from "GENESIS2_QA_20100601"."LIQUIDITY_INDICATOR" LI
              where so.exchange_id = li.exchange_id)



select * from   "GENESIS2_QA_20100601".exchange ex
where ex.EXCHANGE_ID = 'XNYS';