create
     or replace
    drop function staging.custom_format(in_numb numeric default null, in_len int default 8)
    returns text
    language plpgsql
as
$$
    -- SO 2024-07-20
    -- the function works like the select cast(cast(in_numb as float) as varchar(in_len)) in T-sql
    -- for numbers < 1 it returns .valuable_decimals_only like .123 without trailing zeros

declare
    l_int_part     int;
    l_int_part_len int;
    l_adj          int := 2; -- adjustment keeping in mind decimal point and\or something else
begin
    if in_numb is null then
        return null;
    end if;
    if in_numb < 1 then
        return to_char(in_numb, 'FM999.999999');
    end if;

    select floor(in_numb) into l_int_part;
    select char_length(l_int_part::text) into l_int_part_len;
    return round(in_numb, in_len - l_int_part_len - l_adj);
end;
$$;
comment on function staging.custom_format is 'The function is used in away_trade flow for cases when input number < 1 or >= 1';

select trade_record_time,
       date_id,
       subsystem_id,
       account_name,
       cl_ord_id,
       instrument_id,
       side,
       openclose,
       exec_id,
       exchange_id,
       liquidityindicator,
       secondary_order_id,
       exch_exec_id,
       secondary_exch_exec_id,
       case
           when last_mkt in ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when last_mkt in ('XPAR', 'PLAK', 'PARL') then 'LQPT'
           when last_mkt in ('SOHO', 'KNIGHT', 'LSCI', 'NOM') then 'ECUT'
           when last_mkt in ('FOGS', 'MID') then 'XCHI'
           when last_mkt in ('C2', 'CBOE2') then 'C2OX'
           when last_mkt = 'SMARTR' then 'COWEN'
           when last_mkt in ('ACT', 'BOE', 'OTC', 'lp', 'VOL') then 'BRKPT'
           when last_mkt in ('XPSE') then 'N'
           when last_mkt in ('TO') then '1'
           else last_mkt end                                                                      as last_mkt,
       lastshares,
       last_px,
       ex_destination,
       sub_strategy,
       order_id,

       coalesce(
               case
                   when
                       ct.expiration_date is not null and coalesce(ct.strike, 0.00) <> 0.00
                       then ct.opt_qty::numeric
                   else ct.eq_qty::numeric end,
               ct.eq_leaves_qty::numeric
       )                                                                                          as street_order_qty,
       multileg_reporting_type,
       ct.exec_broker,
       ct.cmtafirm,

       case
           when ct.tif in (24, 17, 10, 1, 44) then 0
           when ct.tif in (26, 18, 3, 45, 12) then 1
           when ct.tif in (31, 8, 15, 46) then 2
           when ct.tif in (47, 28, 11, 19, 5) then 3
           when ct.tif in (48, 2, 13, 25, 20) then 4
           when ct.tif in (36, 37, 38, 49) then 5
           when ct.tif in (50, 14, 21, 33) then 6
           when ct.tif in (32, 9, 16) then 7
           end                                                                                    as street_time_in_force,
       opt_customer_firm,
       CASE
           when ct.crossing_side = 'C' and ct.cross_cl_ord_id is not null then 'Y'
           when ct.crossing_side <> 'C' and ct.orig_cl_ord_id is not null then 'Y'
           else 'N'
           END                                                                                    as is_cross_order,
       contra_broker,
       order_price,
       order_process_time,
       remarks,
       is_busted,
       street_client_order_id,
       fix_comp_id,
       leaves_qty,
       leg_ref_id,
       case
           when ct.orig_order_id is not null then 26
           when ct.contra_order_id is not null then 26
           when ct.parent_order_id is not null then 10
           when ct.parent_order_id is null and ct.last_child_order is not null then 10
           when rep_comment like '%OVR%' then 4
           else 50 end                                                                            as strategy_decision_reason_code,
       is_parent,
       symbol,
       strike_price,
       case ct.type_code
           when 'P' then '0'
           when 'C' then '1'
           end                                                                                    as put_or_call,
       extract(year from ct.expiration_date)                                                      as maturity_year,
       extract(month from ct.expiration_date)                                                     as maturity_month,
       extract(day from ct.expiration_date)                                                       as maturity_day,
       ct.securitytype                                                                            as security_type,
       ct.child_orders,
       ct.handling                                                                                as handling_id,
       ct.secondary_order_id2,

-- display_instrument_id
       ---
       ct.rootcode,
       ct.typecode,
ct.expiration_date,
ct.strike_price,
regexp_replace(coalesce(ct.rootcode, ''), '\.|-', '', 'g'),
       --
       case
           when ct.expiration_date is not null and ct.strike_price is not null then
               replace(coalesce(
                               regexp_replace(coalesce(ct.rootcode, ''), '\.|-', '', 'g') || ' ' ||
                               to_char(ct.expiration_date::date, 'DDMonYY') || ' ' ||
                               staging.custom_format(ct.strike_price) ||
                               left(ct.typecode, 8),
                               case
                                   when ct.ord_ContractDesc not like ct.basecode || ' %'
                                       then ct.basecode || ' ' || REPLACE(ct.ord_ContractDesc, ct.BaseCode, '')
                                   when ct.legcount::int = 1 and ct.typecode = 'S' then ct.ord_ContractDesc || ' Stock'
                                   when ct.ord_ContractDesc not like ' %' then ct.ord_ContractDesc || ' '
                                   else ct.ord_ContractDesc end
                       ), '/', '')
           else
               regexp_replace(coalesce(ct.rootcode, ''), '\.|-', '', 'g')
           end                                                                                    as display_instrument_id,
       case when ct.expiration_date is not null and ct.strike_price is not null then 'O' else 'E' end as instrument_type_id,
       regexp_replace(coalesce(ct.basecode, ''), '\.|-', '', 'g')                                 as activ_symbol,
       case when ct.orderreportspecialtype = 'M' then 1 else 0 end                                as is_sor_routed,
	(case
        when lag(ct.companyname,1) over (partition by ct.ExchangeTransactionID order by ct.generation) <> ct.companyname
         and lag(ct.OrderID,1) over (partition by ct.ExchangeTransactionID order by ct.generation) = ct.ParentORdeRID  then 1
        else 0
    end ) as is_company_name_changed,
    ct.companyname,
    ct.generation,
    max(ct.generation) over (partition by ct.ExchangeTransactionID) mx_gen,
    sum(ct.is_company_name_changed) over (partition by secondary_exch_exec_id) as num_firms
--        ''
from staging.v_away_trade_query ct;


create table staging.t_users
(
    id                       int           not null
        constraint t_users_pk primary key generated by default as identity,
    user_id                  int           null,
    company_id               int           null,
    user_login               text,
    user_password            text,
    password_hint            text,
    status                   int           null,
    active_date              timestamp     null,
    person_id                int           null,
    create_date              timestamp     null,
    update_date              timestamp     null,
    login_num                int           null,
    expiration_date          timestamp     null,
    product_id               int           null,
    login_count              int           null,
    login_timestamp          timestamp     null,
    pwd_timestamp            timestamp     null,
    disable_login            int           null,
    auto_expire_pwd          int           null,
    pwd_reset                int           null,
    inactivity_count         int           null,
    user_fix_remote_comp_id  text,
    is_manual_cancel_replace int           null,
    symbol_type              int           null,
    bb_supress_new           int           null,
    session_id               text          null,
    aors_user_name           text          null,
    password_change_required int           null,
    description              text          null,
    system_id                int           null,
    edw_active               int default 0 null,
    edw_user_id              int           null
);


-- staging.dash_exchange_names definition

-- Drop table

-- DROP TABLE staging.dash_exchange_names;

CREATE TABLE staging.dash_exchange_names
(
    exchange_unq_id          int2         NOT NULL,
    exchange_id              varchar(6)   NOT NULL,
    exchange_name            varchar(256) NULL,
    activ_exchange_code      varchar(6)   NULL,
    internalization_priority int2         NULL,
    eq_mpid                  varchar(4)   NULL,
    is_activ_md_required     bpchar(1)    NULL,
    display_exchange_name    varchar(32)  NULL,
    instrument_type_id       bpchar(1)    NULL,
    customer_or_firm_tag     int2         NULL,
    trading_venue_class      bpchar(1)    NULL,
    exch_rt_pref_code_tag    int4         NULL,
    is_rt_mngr_eligible      bpchar(1)    NULL,
    tcce_display_name        varchar(40)  NULL,
    exegy_exchange_code      varchar(6)   NULL,
    date_start               timestamp    NULL,
    date_end                 timestamp    NULL,
    real_exchange_id         varchar(6)   NULL,
    may_street_exchange_code numeric(18)  NULL,
    is_active                int4         NULL,
    mic_code                 varchar(4)   NULL,
    last_mkt                 varchar(5)   NULL,
    exec_broker_tag          numeric(5)   NULL,
    dark_venue_category_id   bpchar(1)    NULL,
    cat_exchange_id          varchar(9)   NULL,
    cat_crd                  varchar(15)  NULL,
    cat_is_exchange          bpchar(1)    NULL,
    cat_suppress             bpchar(1)    NULL,
    cat_collapse             bpchar(1)    NULL,
    is_exchange_active       int4         NULL
);

CREATE TABLE staging.d_Blaze_Exchange_Codes
(
    ID             bigint       NOT NULL,
    mic_code       varchar(50)  NOT NULL,
    security_type  varchar(50)  NOT NULL,
    venue_exchange varchar(50)  NOT NULL,
    business_name  varchar(128) NOT NULL,
    ex_destination varchar(50)  NOT NULL,
    last_mkt       varchar(50)  NULL
);

  select
      trade_record_time,
      db_create_time,
      date_id,
      'to perform' as is_busted,
      'LPEDW'                                                                as subsystem_id,
       case
           when coalesce(us.aors_user_name, us.user_Login) = 'BBNTRST' then 'NTRSCBOE'
           else coalesce(us.aors_user_name, us.user_Login) end                           as account_name,
aw.cl_ord_id as client_order_id,
'???' as instrument_id,
aw.side,
aw.openclose,
'???' as exec_id,
'0'                                                                    as exch_exec_id,
aw.secondary_exch_exec_id,
den.last_mkt,
den1.last_mkt,
aw.ex_destination,
lm.last_mkt as a_last_mkt,
case when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) in ('CBOE-CRD NO BK','PAR','CBOIE') then 'W'
		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) in ('XPAR','PLAK','PARL') then 'LQPT'
		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) in ('SOHO','KNIGHT','LSCI','NOM') then 'ECUT'
		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) in ('FOGS','MID') then 'XCHI'
		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination)  in ('C2','CBOE2') then 'C2OX'
		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) = 'SMARTR' then 'COWEN'
		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) in ('ACT','BOE','OTC','lp','VOL')  then 'BRKPT'
		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) in ('XPSE')  then 'N'
 		 when coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) in ('TO')  then '1'
		 else coalesce(den.last_mkt,den1.last_mkt,aw.ex_destination) end as last_mkt,
             case
           when aw.expiration_date is not null and aw.strike_price is not null then
               replace(coalesce(
                               regexp_replace(coalesce(aw.rootcode, ''), '\.|-', '', 'g') || ' ' ||
                               to_char(aw.expiration_date::date, 'DDMonYY') || ' ' ||
                               staging.trailing_dot(aw.strike_price) ||
                               left(aw.typecode, 8),
                               case
                                   when aw.ord_ContractDesc not like aw.basecode || ' %'
                                       then aw.basecode || ' ' || REPLACE(aw.ord_ContractDesc, aw.BaseCode, '')
                                   when aw.legcount::int = 1 and aw.typecode = 'S' then aw.ord_ContractDesc || ' Stock'
                                   when aw.ord_ContractDesc not like ' %' then aw.ord_ContractDesc || ' '
                                   else aw.ord_ContractDesc end
                       ), '/', '')
           else
               regexp_replace(coalesce(aw.rootcode, ''), '\.|-', '', 'g')
           end                                                                                    as display_instrument_id
      ,
      aw.status,
      * from staging.v_away_trade aw
LEft join staging.d_Blaze_Exchange_Codes lm
on aw.Ex_Destination = coalesce(lm.last_mkt,lm.ex_destination) and CASE WHEN aw.SecurityType = '1' THEN 'O' WHEN aw.SecurityType= '2' THEN 'E' ELSE aw.SecurityType END = lm.Security_Type

        left join staging.T_Users us on us.user_id = aw.userid::int
        left join lateral (select last_mkt
                            from staging.dash_exchange_names den
                            where den.mic_code = aw.ex_destination
                              and aw.exec_type in ('1', '2', 'r')
                              and den.real_exchange_id = den.exchange_id
                              and den.mic_code != ''
                              and den.is_active = 1
                            limit 1) den on true
         left join lateral (select last_mkt, mic_code
                            from staging.dash_exchange_names den
                            where den.exchange_id = aw.ex_destination
                              and aw.exec_type in ('1', '2', 'r')
                              and den.real_exchange_id = den.exchange_id
                              and den.mic_code != ''
                              and den.is_active = 1
                            limit 1) den1 on true
        left join lateral (select )
  where true
  and cl_ord_id in ('1_65240605','1_2b8240605','1_254240617','1_3c6240617','1_16o240626')
  and order_id in (652865815179165700,
652934019335323648,
657283755907481600,
657302344068759552,
657302260082016256,
660511556445929472
)
    and aw.status in ('1', '2')
--   and order_id = 657302260082016256
  and aw.cl_ord_id in ('1_16o240626')

