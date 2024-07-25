CREATE TABLE staging.TUsers
(
    ID                     int           NOT NULL,
    UserId                 int           NULL,
    CompanyID              int           NULL,
    Login                  varchar(128)  NULL,
    Password               varchar(300)  NULL,
    PasswordHint           varchar(128)  NULL,
    Status                 int           NULL,
    ActiveDate             timestamp     NULL,
    PersonId               int           NULL,
    CreateDate             timestamp     NULL,
    UpdateDate             timestamp     NULL,
    LoginNum               int           NULL,
    ExpirationDate         timestamp     NULL,
    ProductID              int           NULL,
    LoginCount             int           NULL,
    LoginTimestamp         timestamp     NULL,
    PwdTimestamp           timestamp     NULL,
    DisableLogin           int           NULL,
    AutoExpirePwd          int           NULL,
    PwdReset               int           NULL,
    InactivityCount        int           NULL,
    UserFixRemoteCompID    varchar(128)  NULL,
    IsManualCancelReplace  int           NULL,
    SymbolType             int           NULL,
    BBSupressNew           int           NULL,
    SessionID              text          NULL,
    AORSUsername           varchar(128)  NULL,
    PasswordChangeRequired int           NULL,
    Description            varchar(256)  NULL,
    SystemID               int           NULL,
    EDWActive              int DEFAULT 0 NULL,
    EDWUserID              int           NULL
);
select * from staging.TUsers;

CREATE TABLE staging.dash_exchange_names
(
    exchange_unq_id          smallint       NOT NULL,
    exchange_id              varchar(6)     NOT NULL,
    exchange_name            varchar(256)   NULL,
    activ_exchange_code      varchar(6)     NULL,
    internalization_priority smallint       NULL,
    eq_mpid                  varchar(4)     NULL,
    is_activ_md_required     char(1)        NULL,
    display_exchange_name    varchar(32)    NULL,
    instrument_type_id       char(1)        NULL,
    customer_or_firm_tag     smallint       NULL,
    trading_venue_class      char(1)        NULL,
    exch_rt_pref_code_tag    int            NULL,
    is_rt_mngr_eligible      char(1)        NULL,
    tcce_display_name        varchar(40)    NULL,
    exegy_exchange_code      varchar(6)     NULL,
    date_start               timestamp      NULL,
    date_end                 timestamp      NULL,
    real_exchange_id         varchar(6)     NULL,
    may_street_exchange_code numeric(18, 0) NULL,
    is_active                int            NULL,
    mic_code                 varchar(4)     NULL,
    last_mkt                 varchar(5)     NULL,
    exec_broker_tag          numeric(5, 0)  NULL,
    dark_venue_category_id   char(1)        NULL,
    cat_exchange_id          varchar(9)     NULL,
    cat_crd                  varchar(15)    NULL,
    cat_is_exchange          char(1)        NULL,
    cat_suppress             char(1)        NULL,
    cat_collapse             char(1)        NULL,
    is_exchange_active       int            NULL
);

CREATE TABLE staging.dBlazeExchangeCodes
(
    ID             bigint       NOT NULL,
    mic_code       varchar(50)  NOT NULL,
    security_type  varchar(50)  NOT NULL,
    venue_exchange varchar(50)  NOT NULL,
    business_name  varchar(128) NOT NULL,
    ex_destination varchar(50)  NOT NULL,
    last_mkt       varchar(50)  NULL
);


CREATE TABLE staging.dTimeInForce
(
    ID       bigint       NOT NULL,
    enum     varchar(50)  NOT NULL,
    enumname varchar(128) NULL,
    name     varchar(128) NULL
);

CREATE TABLE staging.LTimeInForce
(
    ID          int         NOT NULL
        constraint PK_LTimeInForce primary key,
    Code        int2        NOT NULL,
    Description varchar(16) NULL,
    ShortDesc   varchar(16) NULL,
    SystemID    int         NOT NULL,
    EDWID       int         NULL
);


CREATE TABLE staging.LForWhom
(
    ID          int         NOT NULL
        CONSTRAINT PK_LForWhom PRIMARY KEY,
    Code        int2        NOT NULL,
    Description varchar(64) NULL,
    ShortDesc   varchar(64) NULL,
    TypeCode    varchar(1)  NULL,
    SystemID    int         NOT NULL,
    EDWID       int         NULL
);



CREATE TABLE staging.TCompany
(
    ID                   int           NOT NULL,
    CompanyID            int           NULL,
    CompanyCode          varchar(64)   NULL,
    CompanyName          varchar(64)   NULL,
    CreateDate           timestamp     NULL,
    UpdateDate           timestamp     NULL,
    FIXRemoteCompID      varchar(64)   NULL,
    Phone                varchar(20)   NULL,
    IntroducingCompanyID int           NULL,
    Alias                varchar(50)   NULL,
    HomeExchange         char(1)       NULL,
    IsPostTradeMod       int           NULL,
    CBOESubsidyCode      varchar(8)    NULL,
    AORSRemoteCompID     varchar(32)   NULL,
    DefaultOwnerID       int           NULL,
    IsFBW                int           NULL,
    IsManualCancel       int           NULL,
    IsFBWAmex            int           NULL,
    BBSupressNew         int           NULL,
    Type                 int           NULL,
    SystemID             int           NULL,
    EDWActive            int DEFAULT 0 NULL,
    CESGCustID           int           NULL,
    MPIDEntity           varchar(4)    NULL,
    FirmBus              varchar(10)   NULL,
    EDWCompanyID         int           NULL,
    RoutingGroupID       int           NULL
);

CREATE TABLE staging.dBlazeOrderStatus
(
    ID                     bigint       NOT NULL
        CONSTRAINT PK_dBlazeOrderStatus PRIMARY KEY,
    enum                   varchar(50)  NOT NULL,
    enumname               varchar(128) NULL,
    name                   varchar(128) NULL,
    groupStatus            varchar(128) NULL,
    blazeStatusCode        varchar(128) NULL,
    Order_or_Report_status int          NULL
);


CREATE TABLE staging.LOrderStatus
(
    ID          int         NOT NULL
        CONSTRAINT PK_LOrderStatus PRIMARY KEY,
    StatusCode  int         NOT NULL,
    StatusDesc  varchar(64) NOT NULL,
    UpdateDate  timestamp   NULL,
    IsCompleted int         NULL,
    SystemID    int         NOT NULL,
    EDWID       int         NULL
);

CREATE TABLE staging.dLiquidityType
(
    ID       bigint       NOT NULL,
    enum     varchar(50)  NOT NULL,
    enumname varchar(128) NULL,
    name     varchar(128) NULL
);



drop function if exists staging.get_status;
create function staging.get_status(in_exec_type bpchar,
                                   in_child_exec_ref_id text,
                                   in_originated_by text,
                                   in_orderreportspecialtype text)
    returns int
    language plpgsql
as
$$

declare
    l_status_id text;
    l_ret_value int;
begin
    select case
               when in_exec_type in ('e', 'd')
                   then (select case
                                    when rp.exec_type = '4' and rp.payload ->> 'OriginatedBy' = 'E' then 'F'
                                    else rp.exec_type end
                         from blaze7.order_report rp
                         where rp.exec_id = in_child_exec_ref_id)
               when in_exec_type = '4' and in_originated_by = 'E' then 'F'
               else in_exec_type
               end
    into l_status_id;

    select case
               when coalesce(los.edwid, bos.id, 0) = 151 and in_orderreportspecialtype = 'M' then 156
               else coalesce(los.edwid, bos.id, 0) end
    from staging.dblazeorderstatus bos
             left join staging.lorderstatus los
                       on bos.id = los.statuscode and los.systemid = 8
    where bos.enum = l_status_id
      and bos.order_or_report_status = 2
    into l_ret_value;

    return l_ret_value;

end;
$$;

create or replace function staging.custom_format(in_numb numeric default null, in_len int default 8)
    returns text
    language plpgsql
as
$$
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


drop view if exists staging.v_away_trade_query;
create or replace view staging.v_away_trade_query as
select rep.exec_type                                                          as exec_type,
       rep.payload ->> 'TransactTime'                                         AS trade_record_time,
       to_char((rep.payload ->> 'TransactTime')::timestamp, 'YYYYMMDD')::int4 AS date_id,
       case
           when exists (select null
                        From blaze7.order_report r2
                        where r2.payload ->> 'BustExecRefId' = rep.exec_id
                          and rep.cl_ord_id = r2.cl_ord_id
                          and staging.get_status(rep.exec_type, rep.payload ->> 'ChildExecRefId',
                                                 rep.payload ->> 'OriginatedBy',
                                                 rep.payload ->> 'OrderReportSpecialType') in
                              (149, 194, 152)) then 'Y'
           else 'N' end                                                       as is_busted,

       'LPEDW'                                                                as subsystem_id,
       case
           when coalesce(users.AORSUsername, users.Login) = 'BBNTRST' then 'NTRSCBOE'
           else coalesce(users.AORSUsername, Login) end                           as account_name,
       co.cl_ord_id,
       'instrument_id'                                                        as instrument_id,
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'LegSide'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'
           END                                                                AS side,
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'PositionEffect'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'
           WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,PositionEffect}'
           WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,PositionEffect}'
           END                                                                AS openclose,
       'exec_id'                                                              as exec_id, -- identity
       '???'                                                                  as exchange_id,
       coalesce(case
                    when rep.exec_type in ('1', '2') then rep.payload ->> 'TradeLiquidityIndicator'
                    end,
                'R')                                                          AS liquidityindicator,
       null::text                                                             as secondary_order_id,
       '0'                                                                    as exch_exec_id,
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
           ELSE rep.payload ->> 'RouterExecId' END                            as secondary_exch_exec_id,

       coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination)               as last_mkt,

       (rep.payload ->> 'TransactQty')::int8                                  AS lastshares,
       case
           when rep.exec_type in ('1', '2', 'r')
               then round(coalesce(((rep.payload ->> 'LastPx2')::bigint)::numeric / 10000.0,
                                   ((rep.payload ->> 'LastPx')::bigint)::numeric) / 10000.0, 8)
           else '0'::numeric
           end                                                                as last_px,

       rp.ex_destination                                                      as ex_destination,
       'sub_strategy'                                                         as sub_strategy,
       rep.order_id                                                           as order_id,
       rep.chain_id                                                           as chain_id,
       case
           when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP')
               then coalesce(leg.ds_id_date, co.ds_id_date) end               as expiration_date,
       case
           when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP')
               then (coalesce(leg.ds_id_num, co.ds_id_num))::numeric end      as strike,
       case
           when co.instrument_type = 'O' then co.payload ->> 'OrderQty'
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'O'
               then leg.payload ->> 'LegQty' end                              as opt_qty,
       case
           when co.instrument_type = 'E' then co.payload ->> 'OrderQty'
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
               then leg.payload ->> 'LegQty'
           end                                                                as eq_qty,
       case
           when co.instrument_type = 'E' then rep_last."LeavesQty"
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
               then rep_last_exec."LeavesQty"
           end                                                                as eq_leaves_qty,
       -- order_qty is as same as street_order_qty
       case
           when (coalesce(co.payload ->> 'NoLegs', '1'))::int > 1 then 2
           else 1 end                                                         as multileg_reporting_type,
       coalesce(case
                    when co.crossing_side is null then co.payload #>> '{ClearingDetails,GiveUp}'
                    when co.crossing_side = 'O'
                        then co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'
                    when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'
                    else null::text
                    end, rep.payload ->> 'ManualBroker')                                      as exec_broker,

       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'
           WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'
           WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'
           END                                                                AS cmtafirm,
       coalesce(ltf.EDWID, tif.ID)                                            as tif,


       case
           when lfw.EDWID in (1, 25, 32, 78) then '0'
           when lfw.EDWID in (33, 26, 79) then '1'
           when lfw.EDWID in (52, 103, 20, 97) then '2'
           when lfw.EDWID in (19, 30, 38, 96) then '3'
           when lfw.EDWID in (35, 28, 4, 81) then '4'
           when lfw.EDWID in (5, 29, 36, 82) then '5'
           when lfw.EDWID IN (21, 6, 83) then '7'
           when lfw.EDWID IN (31, 23, 41, 98) then '8'
           when lfw.EDWID IN (9, 40, 50, 86) then 'J'
           end                                                                as opt_customer_firm,
       co.crossing_side,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.cross_order_id = co.cross_order_id
          AND co2.crossing_side = 'O'
        ORDER BY co2.chain_id DESC
        LIMIT 1)                                                              as cross_cl_ord_id,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId')::bigint)
        ORDER BY co2.chain_id DESC
        LIMIT 1)                                                              as orig_cl_ord_id,
       -- street_is_cross_order is as same as is_cross_order
       COALESCE(co.payload ->> 'OwnerUserName', co.payload ->> 'InitiatorUserName')          as contra_broker,
--        coalesce(comp.CompanyCode, u.Login) as client_id,
       CASE
           WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
           WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
           ELSE co.payload ->> 'Price'::text
           END                                                                AS order_price,
       '???'                                                                  as order_process_time,
       '???'                                                                  as remarks,
       null                                                                   as street_client_order_id,
       'LPEDWCOMPID'                                                          as fix_comp_id,
       rep.payload ->> 'LeavesQty'                                            as leaves_qty,
       CASE co.instrument_type
           WHEN 'M' THEN leg.payload ->> 'LegSeqNumber'
           ELSE '1'
           END                                                                AS leg_ref_id,

       CASE co.crossing_side
           WHEN 'C'::bpchar THEN (SELECT co2.cl_ord_id
                                  FROM blaze7.client_order co2
                                  WHERE co2.cross_order_id = co.cross_order_id
                                    AND co2.crossing_side = 'O'::bpchar
                                  ORDER BY co2.chain_id DESC
                                  LIMIT 1)
           ELSE (SELECT co2.cl_ord_id
                 FROM blaze7.client_order co2
                 WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId'::text)::bigint)
                 ORDER BY co2.chain_id DESC
                 LIMIT 1)
           END                                                                as orig_order_id,
       CASE co.crossing_side
           WHEN 'O'::bpchar THEN (SELECT co2.cl_ord_id
                                  FROM blaze7.client_order co2
                                  WHERE co2.cross_order_id = co.cross_order_id
                                    AND co2.crossing_side = 'C'::bpchar
                                  ORDER BY co2.chain_id DESC
                                  LIMIT 1)
           ELSE (SELECT co2.cl_ord_id
                 FROM blaze7.client_order co2
                 WHERE ((co2.payload ->> 'OriginatorOrderRefId'::text)::bigint) = co.order_id
                   AND co2.record_type = '0'::bpchar
                   AND co2.chain_id = 0
                   AND co2.db_create_time >= co.db_create_time::date
                   AND co2.db_create_time <= (co.db_create_time::date + '1 day'::interval)
                 ORDER BY co2.chain_id DESC
                 LIMIT 1)
           END                                                                as contra_order_id,
       CASE
           WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                     FROM blaze7.client_order co2
                                                     WHERE co2.order_id = co.parent_order_id
                                                     ORDER BY co2.chain_id DESC
                                                     LIMIT 1)
           ELSE NULL::character varying
           END                                                                as parent_order_id,
       (SELECT rep.payload ->> 'NoChildren'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        limit 1)                                                                 last_child_order,
       co.payload ->> 'OrderTextComment'                                      as rep_comment,
       case when co.parent_order_id is null then 'Y' else 'N' end             as is_parent,

       regexp_replace(COALESCE(leg.ds_id_2, co.ds_id_2, leg.ds_id_3, co.ds_id_3), '\.|-', '/',
                      'g')                                                    as symbol,
       round((case
                  when coalesce(co.ds_id_1, leg.ds_id_1) in ('FO', 'OP')
                      THEN coalesce(co.ds_id_num, leg.ds_id_num)::numeric END)::numeric,
             6)                                                               AS strike_price,

       CASE
           WHEN coalesce(co.ds_id_1, leg.ds_id_1) = 'EQ' THEN 'S'
           WHEN coalesce(co.ds_id_1, leg.ds_id_1) in ('FO', 'OP')
               THEN left(coalesce(co.ds_id_2, leg.ds_id_2), 1)
           END                                                                as type_code,

       -- will be transformed into maturity_year\month\day
       CASE
           WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegInstrumentType'::text
                                                 FROM blaze7.client_order_leg leg
                                                 WHERE leg.order_id = rep.order_id
                                                   AND leg.chain_id = rep.chain_id
                                                   AND leg.leg_ref_id::text = rep.leg_ref_id::text)
           ELSE rep.payload ->> 'InstrumentType'::text
           END                                                                AS securitytype,

       (SELECT rep.payload ->> 'NoChildren'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                              as child_orders,
-- ISNULL(CASE WHEN r.OrderReportSpecialType = 'M' then lt.ID ELSE r.[Handling] END,0) [Handling]
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' then lt.ID
           ELSE null
           END                                                                AS Handling,
       0                                                                      as secondary_order_id2,
-- expiration_date,
-- strike_price,
-- tl.[RootCode]
       coalesce(co.ds_id_2, leg.ds_id_2, co.ds_id_3, leg.ds_id_3)             AS rootcode,
-- tl.BaseCode
       coalesce(co.ds_id_2, leg.ds_id_2, co.ds_id_3, leg.ds_id_3)             AS basecode,
-- tl.TypeCode = ct.type_code
       CASE
           WHEN coalesce(co.ds_id_1, leg.ds_id_1) = 'EQ' THEN 'S'
           WHEN coalesce(co.ds_id_1, leg.ds_id_1) = ANY (ARRAY ['FO', 'OP'])
               THEN coalesce(co.ds_id_4, leg.ds_id_4)
           END                                                                AS typecode,
       regexp_replace(coalesce(leg.ds_id_2, leg.ds_id_3), '\.|-', '')         as display_instrument_id_2,
-- ContractDesc
       coalesce(co.payload ->> 'ProductDescription', '')::text                as ord_ContractDesc,
       COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                     as legcount,
       CASE
           WHEN (rep.payload ->> 'OrderReportSpecialType'::text) = 'M'::text THEN 'M'::text
           ELSE NULL::text
           END                                                                AS orderreportspecialtype,

       case
           when coalesce(den1.mic_code, rp.ex_destination) in ('CBOE-CRD NO BK', 'PAR', 'CBOIE')
               then 'XCBO'
           when coalesce(den1.mic_code, rp.ex_destination) in ('XPAR', 'PLAK', 'PARL') then 'LQPT'
           when coalesce(den1.mic_code, rp.ex_destination) in ('SOHO', 'KNIGHT', 'LSCI', 'NOM')
               then 'ECUT'
           when coalesce(den1.mic_code, rp.ex_destination) in ('FOGS', 'MID') then 'XCHI'
           when coalesce(den1.mic_code, rp.ex_destination) in ('C2', 'CBOE2') then 'C2OX'
           when coalesce(den1.mic_code, rp.ex_destination) = 'SMARTR' then 'COWEN'
           when coalesce(den1.mic_code, rp.ex_destination) in ('ACT', 'BOE', 'OTC', 'lp', 'VOL')
               then 'BRKPT'
           when coalesce(den1.mic_code, rp.ex_destination) in ('XPSE') then 'ARCO'
           when coalesce(den1.mic_code, rp.ex_destination) = 'TO' then 'AMXO'
           else coalesce(den1.mic_code, rp.ex_destination) end                as mic_code
        ,
       co.ds_id_1                                                             as dash_sec_2,
       co.ds_id_date                                                          as dase_sec_date,
       co.ds_id_num                                                           as dash_sec_num,
       co.ds_id_2                                                             as dash_sec_eq,
       co.ds_id_3                                                             as dase_sec_op,

       leg.ds_id_1                                                            as leg_dash_sec_2,
       leg.ds_id_date                                                         as leg_dase_sec_date,
       leg.ds_id_num                                                          as leg_dash_sec_num,
       leg.ds_id_2                                                            as leg_dash_sec_eq,
       leg.ds_id_3                                                            as leg_dase_sec_op,
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
           ELSE rep.payload ->> 'RouterExecId' END                               ExchangeTransactionID,
       co.generation,
       comp.companyname                                                       as companyname,
       clordid_to_guid(rep.cl_ord_id)                                         as orderid,
       co.parentorderid                                                       as parentorderid,
       rep.db_create_time,
--        case
--            when lag(comp.companyname, 1) over (partition by CASE
--                                                                 WHEN rep.payload ->> 'OrderReportSpecialType' = 'M'
--                                                                     THEN 'Manual Report'
--                                                                 ELSE rep.payload ->> 'RouterExecId' END order by co.generation) <>
--                 comp.companyname
--                and lag(clordid_to_guid(rep.cl_ord_id), 1) over (partition by CASE
--                                                                                  WHEN rep.payload ->> 'OrderReportSpecialType' = 'M'
--                                                                                      THEN 'Manual Report'
--                                                                                  ELSE rep.payload ->> 'RouterExecId' END order by co.generation) =
--                    co.parentorderid then 1
--            else 0
--            end as is_company_name_changed
co.payload ->> 'DashSecurityId',
leg.payload ->> 'DashSecurityId'
from blaze7.order_report rep
         join lateral (select *,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end  as ds_id_1,
                              case
                                  when co.instrument_type <> 'M' then to_date(
                                          "substring"(co.payload ->> 'DashSecurityId', '([0-9]{6})'),
                                          'YYMMDD') end                                                            as ds_id_date,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end      as ds_id_num,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end          as ds_id_2,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as ds_id_3,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', '[0-9]{6}(.)') end         as ds_id_4,
                              CASE
                                  WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
                                  WHEN co.crossing_side = 'O'::bpchar
                                      THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
                                  WHEN co.crossing_side = 'C'::bpchar
                                      THEN co.payload #>> '{ContraOrder,Generation}'::text[]
                                  END                                                                              AS generation,
                              case
                                  when co.parent_order_id is null then (SELECT co2.cl_ord_id
                                                                        FROM blaze7.client_order co2
                                                                        WHERE co2.order_id = co.parent_order_id
                                                                        ORDER BY co2.chain_id DESC
                                                                        LIMIT 1) end                               as parentorderid
                       from blaze7.client_order co
                       where co.order_id = rep.order_id
                         AND co.chain_id = rep.chain_id
                       limit 1) co on true
         LEFT JOIN lateral (select *,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end  as ds_id_1,
                                   case
                                       when co.instrument_type = 'M' then to_date(
                                               "substring"(leg.payload ->> 'DashSecurityId', '([0-9]{6})'),
                                               'YYMMDD') end                                                             as ds_id_date,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end      as ds_id_num,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end          as ds_id_2,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as ds_id_3,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', '[0-9]{6}(.)') end         as ds_id_4
                            from blaze7.client_order_leg leg
                            where leg.order_id = co.order_id
                              AND leg.chain_id = co.chain_id
                              and leg.leg_ref_id = rep.leg_ref_id) leg on true
         left join staging.TUsers users on users.ID = co.user_id
         left join lateral (select regexp_replace(rep.payload ->> 'LastMkt', 'DIRECT-| Printer', '', 'g') as ex_destination
                            from blaze7.order_report rp
                            where rp.exec_id = rep.exec_id
                            limit 1) rp on true
         left join lateral (select last_mkt
                            from staging.dash_exchange_names den
                            where den.mic_code = rp.ex_destination
                              and rep.exec_type in ('1', '2', 'r')
                              and den.real_exchange_id = den.exchange_id
                              and den.mic_code != ''
                              and den.is_active = 1
                            limit 1) den on true
         left join lateral (select last_mkt, mic_code
                            from staging.dash_exchange_names den
                            where den.exchange_id = rp.ex_destination
                              and rep.exec_type in ('1', '2', 'r')
                              and den.real_exchange_id = den.exchange_id
                              and den.mic_code != ''
                              and den.is_active = 1
                            limit 1) den1 on true

         LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text       AS "CumQty",
                                    rep.payload ->> 'AvgPx'::text        AS "AvgPx",
                                    rep.payload ->> 'LeavesQty'::text    AS "LeavesQty",
                                    rep.payload ->> 'CanceledQty'::text  AS "CanceledQty",
                                    rep.payload ->> 'TransactTime'::text AS "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                               AND COALESCE(rep.leg_ref_id::text, 'leg_ref_id'::text) =
                                   COALESCE(leg.leg_ref_id::text, 'leg_ref_id'::text)
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last_exec ON true
         LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text       AS "CumQty",
                                    rep.payload ->> 'AvgPx'::text        AS "AvgPx",
                                    rep.payload ->> 'LeavesQty'::text    AS "LeavesQty",
                                    rep.payload ->> 'CanceledQty'::text  AS "CanceledQty",
                                    rep.payload ->> 'TransactTime'::text AS "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last ON true
         Left join staging.dTimeInForce tif on tif.enum = co.payload ->> 'TimeInForce'
         Left join staging.LTimeInForce ltf on tif.ID = ltf.CODE and ltf.SystemID = 8
         LEFT JOIN staging.LForWhom lfw on lfw.ShortDesc = CASE
                                                               WHEN co.crossing_side IS NULL
                                                                   THEN co.payload #>> '{ClearingDetails,OptionRange}'
                                                               WHEN co.crossing_side = 'O'
                                                                   THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'
                                                               WHEN co.crossing_side = 'C'
                                                                   THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'
                                                               ELSE NULL::text
    END
    and lfw.SystemID = 4
--     left join staging.TCompany tc on tc.CompanyID = u.CompanyID and tc.SystemID = u.SystemID and tc.EDWActive = 1
         left join staging.TCompany comp on users.CompanyID = (CASE
                                                               WHEN co.order_class = 'F'
                                                                   THEN co.payload ->> 'InitiatorEntityId'
                                                               WHEN co.crossing_side IS NULL
                                                                   THEN co.payload ->> 'ClientEntityId'
                                                               WHEN co.crossing_side = 'O'
                                                                   THEN co.payload #>> '{OriginatorOrder,ClientEntityId}'
                                                               WHEN co.crossing_side = 'C'
                                                                   THEN co.payload #>> '{ContraOrder,ClientEntityId}'
    END)::int4
         LEft join staging.dLiquidityType lt on rep.payload ->> 'LiquidityType' = lt.enum
where true
  and rep.multileg_reporting_type <> '3'
  AND co.record_type in ('0', '2')
  AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i')
and rep.order_id = 563653227707367424;



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
from staging.v_away_trade_query ct
where date_id = 20240522
and order_id = 563653227707367424;


-- is_busted

select exec_id, payload ->> 'BustExecRefId', * from blaze7.order_report
where true
--     and payload ->> 'BustExecRefId' is not null
and exec_id = 'ih9r43tc0g08'

----------------------------------------------------------------------


drop view if exists blaze7.v_away_trade;
create or replace view blaze7.v_away_trade as
select co_main.order_id                                                                                        as order_id,
       co_main.chain_id                                                                                        as chain_id,
       rep.is_busted                                                                                           as is_busted,
       CASE
           WHEN co.order_class = 'F'::bpchar THEN co.payload ->> 'InitiatorUserId'::text
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientUserId'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClientUserId}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClientUserId}'::text[]
           ELSE NULL::text
           END                                                                                                 AS userid,
--------------
       co.dashaliasid,
       CASE
           WHEN rep.exec_type in ('e', 'd') THEN
               (SELECT CASE
                           WHEN rp.exec_type = '4'::bpchar AND (rp.payload ->> 'OriginatedBy'::text) = 'E'::text
                               THEN 'F'::bpchar
                           ELSE rp.exec_type
                           END AS exec_type
                FROM blaze7.order_report rp
                WHERE rp.exec_id::text = (rep.payload ->> 'ChildExecRefId'::text))
           WHEN rep.exec_type = '4' AND rep.payload ->> 'OriginatedBy' = 'E' THEN 'F'
           ELSE rep.exec_type
           END                                                                                                 AS status,


       rep.exec_type                                                                                           as exec_type,
       rep.payload ->> 'TransactTime'                                                                          AS trade_record_time,
       to_char((rep.payload ->> 'TransactTime')::timestamp, 'YYYYMMDD')::int4                                  AS date_id,
       'LPEDW'                                                                                                 as subsystem_id,
       co.cl_ord_id,
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'LegSide'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'
           END                                                                                                 AS side,
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'PositionEffect'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'
           WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,PositionEffect}'
           WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,PositionEffect}'
           END                                                                                                 AS openclose,
       coalesce(case when rep.exec_type in ('1', '2') then rep.payload ->> 'TradeLiquidityIndicator' end,
                'R')                                                                                           as liquidityindicator,
       null::text                                                                                              as secondary_order_id,
       '0'                                                                                                     as exch_exec_id,
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
           ELSE rep.payload ->> 'RouterExecId' END                                                             as secondary_exch_exec_id,

       (rep.payload ->> 'TransactQty')::int8                                                                   AS lastshares,
       case
           when rep.exec_type in ('1', '2', 'r')
               then round(coalesce(((rep.payload ->> 'LastPx2')::bigint)::numeric / 10000.0,
                                   ((rep.payload ->> 'LastPx')::bigint)::numeric) / 10000.0, 8)
           else '0'::numeric
           end                                                                                                 as last_px,

       case
           when rep.exec_type = ANY (ARRAY ['1', '2', 'r'])
               then
               rep.payload ->> 'LastMkt' end                                                                   as ex_destination,

       case
           when coalesce(leg.dash_sec_eq_op, co.dash_sec_eq_op) in ('FO', 'OP')
               then coalesce(leg.dash_sec_date, co.dash_sec_date) end                                          as expiration_date,
       case
           when coalesce(leg.dash_sec_eq_op, co.dash_sec_eq_op) in ('FO', 'OP')
               then (coalesce(leg.dash_sec_price, co.dash_sec_price))::numeric end                             as strike,
       case
           when co.instrument_type = 'O' then co.payload ->> 'OrderQty'
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'O'
               then leg.payload ->> 'LegQty' end                                                               as opt_qty,
       case
           when co.instrument_type = 'E' then co.payload ->> 'OrderQty'
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
               then leg.payload ->> 'LegQty'
           end                                                                                                 as eq_qty,
       case
           when co.instrument_type = 'E' then rep_last."LeavesQty"
           when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
               then rep_last_exec."LeavesQty"
           end                                                                                                 as eq_leaves_qty,
       -- order_qty is as same as street_order_qty
       case
           when (coalesce(co.payload ->> 'NoLegs', '1'))::int > 1 then 2
           else 1 end                                                                                          as multileg_reporting_type,
       coalesce(case
                    when co.crossing_side is null then co.payload #>> '{ClearingDetails,GiveUp}'
                    when co.crossing_side = 'O'
                        then co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'
                    when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'
                    else null::text
                    end, rep.payload ->>
                         'ManualBroker')                                                                       as exec_broker,

       CASE
           WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'
           WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'
           WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'
           END                                                                                                 AS cmtafirm,
       co.crossing_side,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.cross_order_id = co.cross_order_id
          AND co2.crossing_side = 'O'
        ORDER BY co2.chain_id DESC
        LIMIT 1)                                                                                               as cross_cl_ord_id,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId')::bigint)
        ORDER BY co2.chain_id DESC
        LIMIT 1)                                                                                               as orig_cl_ord_id,
       -- street_is_cross_order is as same as is_cross_order
       COALESCE(co.payload ->> 'OwnerUserName', co.payload ->>
                                                'InitiatorUserName')                                           as contra_broker,
--        coalesce(comp.CompanyCode, u.Login) as client_id,

       CASE
           WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
           WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
           ELSE co.payload ->> 'Price'::text
           END                                                                                                 AS order_price,
       null                                                                                                    as street_client_order_id,
       rep.payload ->> 'LeavesQty'                                                                             as leaves_qty,
--       CASE co.instrument_type
--           WHEN 'M' THEN leg.payload ->> 'LegSeqNumber'
--           ELSE '1'
--           END                                                                     AS leg_ref_id,
       coalesce(rep.leg_ref_id, '1')                                                                           as leg_ref_id,

       CASE co.crossing_side
           WHEN 'C'::bpchar THEN (SELECT co2.cl_ord_id
                                  FROM blaze7.client_order co2
                                  WHERE co2.cross_order_id = co.cross_order_id
                                    AND co2.crossing_side = 'O'::bpchar
                                  ORDER BY co2.chain_id DESC
                                  LIMIT 1)
           ELSE (SELECT co2.cl_ord_id
                 FROM blaze7.client_order co2
                 WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId'::text)::bigint)
                 ORDER BY co2.chain_id DESC
                 LIMIT 1)
           END                                                                                                 as orig_order_id,
       CASE co.crossing_side
           WHEN 'O'::bpchar THEN (SELECT co2.cl_ord_id
                                  FROM blaze7.client_order co2
                                  WHERE co2.cross_order_id = co.cross_order_id
                                    AND co2.crossing_side = 'C'::bpchar
                                  ORDER BY co2.chain_id DESC
                                  LIMIT 1)
           ELSE (SELECT co2.cl_ord_id
                 FROM blaze7.client_order co2
                 WHERE ((co2.payload ->> 'OriginatorOrderRefId'::text)::bigint) = co.order_id
                   AND co2.record_type = '0'::bpchar
                   AND co2.chain_id = 0
                   AND co2.db_create_time >= co.db_create_time::date
                   AND co2.db_create_time <= (co.db_create_time::date + '1 day'::interval)
                 ORDER BY co2.chain_id DESC
                 LIMIT 1)
           END                                                                                                 as contra_order_id,
       CASE
           WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                     FROM blaze7.client_order co2
                                                     WHERE co2.order_id = co.parent_order_id
                                                     ORDER BY co2.chain_id DESC
                                                     LIMIT 1)
           ELSE NULL::character varying
           END                                                                                                 as parent_order_id,
       (SELECT rep.payload ->> 'NoChildren'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        limit 1)                                                                                                  last_child_order,
       co.payload ->> 'OrderTextComment'                                                                       as rep_comment,
       case when co.parent_order_id is null then 'Y' else 'N' end                                              as is_parent,

       regexp_replace(
               COALESCE(leg.dash_sec_eq_symbol, co.dash_sec_eq_symbol, leg.dash_sec_op_symbol, co.dash_sec_op_symbol),
               '\.|-', '/',
               'g')                                                                                            as symbol,
       round((case
                  when coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) in ('FO', 'OP')
                      THEN coalesce(co.dash_sec_price, leg.dash_sec_price)::numeric END)::numeric,
             6)                                                                                                AS strike_price,

--       CASE
--           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = 'EQ' THEN 'S'
--           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) in ('FO', 'OP')
--               THEN left(coalesce(co.dash_sec_eq_symbol, leg.dash_sec_eq_symbol), 1)
--           END                                                                     as type_code,
       CASE
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = 'EQ' THEN 'S'
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = ANY (ARRAY ['FO', 'OP'])
               THEN coalesce(co.dash_sec_pc, leg.dash_sec_pc)
           END                                                                                                 AS type_code,
       -- will be transformed into maturity_year\month\day
--       rep.leg_ref_id,
       leg.leg_instrument_type,
       rep.payload ->> 'InstrumentType'                                                                           rep_instrument_type,
       CASE
           WHEN rep.leg_ref_id IS NOT NULL THEN leg.leg_instrument_type
           --           (SELECT leg.payload ->> 'LegInstrumentType'::text
--                                                 FROM blaze7.client_order_leg leg
--                                                 WHERE leg.order_id = rep.order_id
--                                                   AND leg.chain_id = rep.chain_id
--                                                   AND leg.leg_ref_id::text = rep.leg_ref_id::text)
           ELSE rep.payload ->> 'InstrumentType'::text
           END                                                                                                 AS securitytype,

       (SELECT rep.payload ->> 'NoChildren'::text
        FROM blaze7.order_report rep
        WHERE rep.cl_ord_id::text = co.cl_ord_id::text
        ORDER BY rep.exec_id DESC
        LIMIT 1)                                                                                               as child_orders,
-- ISNULL(CASE WHEN r.OrderReportSpecialType = 'M' then lt.ID ELSE r.[Handling] END,0) [Handling]
       0                                                                                                       as secondary_order_id2,

-- expiration_date,
-- strike_price,
-- tl.[RootCode]
       coalesce(co.dash_sec_eq_symbol, leg.dash_sec_eq_symbol, co.dash_sec_op_symbol,
                leg.dash_sec_op_symbol)                                                                        AS rootcode,
-- tl.BaseCode
       coalesce(co.dash_sec_eq_symbol, leg.dash_sec_eq_symbol, co.dash_sec_op_symbol,
                leg.dash_sec_op_symbol)                                                                        AS basecode,
-- tl.TypeCode = ct.type_code
       CASE
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = 'EQ' THEN 'S'
           WHEN coalesce(co.dash_sec_eq_op, leg.dash_sec_eq_op) = ANY (ARRAY ['FO', 'OP'])
               THEN coalesce(co.dash_sec_pc, leg.dash_sec_pc)
           END                                                                                                 AS typecode,


       regexp_replace(coalesce(leg.dash_sec_eq_symbol, leg.dash_sec_op_symbol), '\.|-',
                      '')                                                                                      as display_instrument_id_2,
-- ContractDesc
       coalesce(co.payload ->> 'ProductDescription', '')::text                                                 as ord_ContractDesc,
       COALESCE(co.payload ->> 'NoLegs'::text, '1'::text)                                                      as legcount,
       CASE
           WHEN (rep.payload ->> 'OrderReportSpecialType'::text) = 'M'::text THEN 'M'::text
           ELSE NULL::text
           END                                                                                                 AS orderreportspecialtype,

       co.dash_sec_eq_op                                                                                       as dash_sec_2,
       co.dash_sec_date                                                                                        as dase_sec_date,
       co.dash_sec_price                                                                                       as dash_sec_num,
       co.dash_sec_eq_symbol                                                                                   as dash_sec_eq,
       co.dash_sec_op_symbol                                                                                   as dase_sec_op,

       leg.dash_sec_eq_op                                                                                      as leg_dash_sec_2,
       leg.dash_sec_date                                                                                       as leg_dase_sec_date,
       leg.dash_sec_price                                                                                      as leg_dash_sec_num,
       leg.dash_sec_eq_symbol                                                                                  as leg_dash_sec_eq,
       leg.dash_sec_op_symbol                                                                                  as leg_dase_sec_op,
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
           ELSE rep.payload ->> 'RouterExecId' END                                                             as ExchangeTransactionID,
       co.generation,
       public.clordid_to_guid(rep.cl_ord_id)                                                                   as orderid,
       co.parentorderid                                                                                        as parentorderid,
       rep.db_create_time,
       co.payload ->> 'DashSecurityId'                                                                         as co_dash_security_id,
       leg.payload ->> 'DashSecurityId'                                                                        as leg_dash_security_id,

       -- for join to LForWhom
       case
           when co.crossing_side is null
               THEN co.payload #>> '{ClearingDetails,OptionRange}'
           WHEN co.crossing_side = 'O'
               THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'
           WHEN co.crossing_side = 'C'
               THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'
           ELSE NULL::text
           END                                                                                                 as option_range,
-- for join to staging.TCompany
       (CASE
            WHEN co.order_class = 'F' THEN co.payload ->> 'InitiatorEntityId'
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientEntityId'
            WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,ClientEntityId}'
            WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,ClientEntityId}'
           END)::int4                                                                                          as client_entity_id,
       rep.payload ->> 'LiquidityType'                                                                         as rep_liquidity_type,
       co.payload ->> 'TimeInForce'                                                                            as co_time_in_force
from blaze7.client_order co_main
         join lateral (select *,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end  as dash_sec_eq_op,
                              case
                                  when co.instrument_type <> 'M' then to_date(
                                          "substring"(co.payload ->> 'DashSecurityId', '([0-9]{6})'),
                                          'YYMMDD') end                                                            as dash_sec_date,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end      as dash_sec_price,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end          as dash_sec_eq_symbol,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as dash_sec_op_symbol,
                              case
                                  when co.instrument_type <> 'M'
                                      then "substring"(co.payload ->> 'DashSecurityId', '[0-9]{6}(.)') end         as dash_sec_pc,
                              CASE
                                  WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
                                  WHEN co.crossing_side = 'O'::bpchar
                                      THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
                                  WHEN co.crossing_side = 'C'::bpchar
                                      THEN co.payload #>> '{ContraOrder,Generation}'::text[]
                                  END                                                                              AS generation,
                              case
                                  when co.parent_order_id is null then (SELECT co2.cl_ord_id
                                                                        FROM blaze7.client_order co2
                                                                        WHERE co2.order_id = co.parent_order_id
                                                                        ORDER BY co2.chain_id DESC
                                                                        LIMIT 1) end                               as parentorderid,

                              CASE
                                  WHEN co.crossing_side IS NULL
                                      THEN co.payload #>> '{ClearingDetails,DashAliasId}'::text[]
                                  WHEN co.crossing_side = 'O'::bpchar
                                      THEN co.payload #>> '{OriginatorOrder,ClearingDetails,DashAliasId}'::text[]
                                  WHEN co.crossing_side = 'C'::bpchar
                                      THEN co.payload #>> '{ContraOrder,ClearingDetails,DashAliasId}'::text[]
                                  ELSE NULL::text
                                  END                                                                              AS dashaliasid

                       from blaze7.client_order co
                       where co.order_id = co_main.order_id
                         AND co.chain_id = co_main.chain_id
                       limit 1) co on true
         join blaze7.order_report rep on rep.order_id = co.order_id --and co.chain_id = rep.chain_id
         left join lateral (select leg.payload,
                                   leg.leg_ref_id,
                                   leg.payload ->> 'LegInstrumentType'                                                   as leg_instrument_type,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end  as dash_sec_eq_op,
                                   case
                                       when co.instrument_type = 'M' then to_date(
                                               "substring"(leg.payload ->> 'DashSecurityId', '([0-9]{6})'),
                                               'YYMMDD') end                                                             as dash_sec_date,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end      as dash_sec_price,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end          as dash_sec_eq_symbol,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as dash_sec_op_symbol,
                                   case
                                       when co.instrument_type = 'M'
                                           then "substring"(leg.payload ->> 'DashSecurityId', '[0-9]{6}(.)') end         as dash_sec_pc
                            from blaze7.client_order_leg leg
                            where leg.order_id = co.order_id
                              AND leg.chain_id = co.chain_id
                              and leg.leg_ref_id = rep.leg_ref_id
                            limit 1) leg on true

    --         left join lateral (select regexp_replace(rep.payload ->> 'LastMkt', 'DIRECT-| Printer', '', 'g') as ex_destination
--                            from blaze7.order_report rp
--                            where rp.exec_id = rep.exec_id
--                            limit 1) rp on true
         LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text       AS "CumQty",
                                    rep.payload ->> 'AvgPx'::text        AS "AvgPx",
                                    rep.payload ->> 'LeavesQty'::text    AS "LeavesQty",
                                    rep.payload ->> 'CanceledQty'::text  AS "CanceledQty",
                                    rep.payload ->> 'TransactTime'::text AS "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                               AND COALESCE(rep.leg_ref_id::text, 'leg_ref_id'::text) =
                                   COALESCE(leg.leg_ref_id::text, 'leg_ref_id'::text)
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last_exec ON true
         LEFT JOIN LATERAL ( SELECT rep.payload ->> 'CumQty'::text       AS "CumQty",
                                    rep.payload ->> 'AvgPx'::text        AS "AvgPx",
                                    rep.payload ->> 'LeavesQty'::text    AS "LeavesQty",
                                    rep.payload ->> 'CanceledQty'::text  AS "CanceledQty",
                                    rep.payload ->> 'TransactTime'::text AS "TransactTime"
                             FROM blaze7.order_report rep
                             WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                             ORDER BY rep.exec_id DESC
                             LIMIT 1) rep_last ON true


where true
  and rep.multileg_reporting_type <> '3'
  AND co_main.record_type in ('0', '2')
  AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i')
--  1_16o240626
  and co_main.cl_ord_id = '1_1q3240718'
  and co_main.order_id in (660511556445929472)
;
select *
from blaze7.v_away_trade
where true
  and cl_ord_id = '1_3vv240719' order_id in (549890105993592832, 549891100882501632)

select *
from