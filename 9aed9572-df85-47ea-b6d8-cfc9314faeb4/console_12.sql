/*
FROM [LiquidPoint_EDW].[dbo].[TReports_EDW_daily] tr with (nolock)
inner join  [LiquidPoint_EDW].[dbo].[TOrder_EDW_daily] tor with (nolock)   on tor.[OrderID]=tr.[OrderID]
inner join [LiquidPoint_EDW].[dbo].[TOrderMisc1_EDW_daily] torm with (nolock) on tor.[OrderID]=torm.[OrderID] and tor.[SystemID]=torm.[SystemID]
left join [LiquidPoint_EDW].[dbo].[TLegs_EDW_daily] tl with (nolock) on tl.[OrderID]=tr.[OrderID] and tl.[LegNumber]=tr.[LegNumber]
  */
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

create or replace function staging.get_order_qty(in_co_instrument_type bpchar, in_co_dashsecurity_id text,
                                      in_leg_dashsecurity_id text, in_leg_instrument_type bpchar, in_co_order_qty text,
                                      in_leg_qty text, in_rep_last_leaves_qty text, in_rep_exec_leaves_qty text)
    returns text
    language plpgsql
as
$fx$
declare
    ret_val text;
begin

select case
      when case
               when "substring"(case in_co_instrument_type when 'M' then in_leg_dashsecurity_id else in_co_dashsecurity_id end, 'US:([FO|OP|EQ]{2})') in ('FO', 'OP')
                         then to_date("substring"(case in_co_instrument_type when 'M' then in_leg_dashsecurity_id else in_co_dashsecurity_id end, '([0-9]{6})'), 'YYMMDD')
                         end <> '1900-01-01'::date
                   and
                    case when "substring"(case in_co_instrument_type when 'M' then in_leg_dashsecurity_id else in_co_dashsecurity_id end, 'US:([FO|OP|EQ]{2})') in ('FO', 'OP')
                        then "substring"(case in_co_instrument_type when 'M' then in_leg_dashsecurity_id else in_co_dashsecurity_id end, '[0-9]{6}.(.+)$')::numeric
                    end <> 0.00
          then
                   case
                       when in_co_instrument_type = 'O' then in_co_order_qty
                       when in_co_instrument_type = 'M' and in_leg_instrument_type = 'O' then in_leg_qty end
          else case
                        when in_co_instrument_type = 'E' then in_co_order_qty
                        when in_co_instrument_type = 'M' and in_leg_instrument_type = 'E' then in_leg_qty
          end end
into ret_val;
if ret_val is not null then
    return ret_val;
end if;

select case
          when in_co_instrument_type = 'E' then in_rep_last_leaves_qty
          when in_co_instrument_type = 'M' and in_leg_instrument_type
              then in_rep_exec_leaves_qty
          end
into ret_val;
return ret_val;

end;
$fx$;

with ct as (
select rep.payload ->> 'TransactTime'                                                            AS trade_record_time,
                   to_char((rep.payload ->> 'TransactTime')::timestamp, 'YYYYMMDD')::int4                    AS date_id,
                   case
                       when exists (select null
                                    From blaze7.order_report r2
                                    where r2.payload ->> 'BustExecRefId' = rep.exec_id
                                      and rep.cl_ord_id = r2.cl_ord_id
                                      and staging.get_status(rep.exec_type, rep.payload ->> 'ChildExecRefId',
                                                             rep.payload ->> 'OriginatedBy',
                                                             rep.payload ->> 'OrderReportSpecialType') in
                                          (149, 194, 152)) then 'Y'
                       else 'N' end                                                                          as is_busted,

                   'LPEDW'                                                                                   as subsystem_id,
                   case
                       when coalesce(u.AORSUsername, u.Login) = 'BBNTRST' then 'NTRSCBOE'
                       else coalesce(u.AORSUsername, Login) end                                              as account_name,
                   co.cl_ord_id,
                   'instrument_id' as instrument_id,
                   CASE
                       WHEN co.instrument_type = 'M' THEN leg.payload ->> 'LegSide'
                       WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'
                       WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'
                       WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'
                       END                                                                                   AS side,
                   CASE
                       WHEN co.instrument_type = 'M' THEN leg.payload ->> 'PositionEffect'
                       WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'
                       WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,PositionEffect}'
                       WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,PositionEffect}'
                       END                                                                                   AS openclose,
                   'exec_id'                                                                                 as exec_id, -- identity
                   '???'                                                                                     as exchange_id,
                   coalesce(case
                                when rep.exec_type in ('1', '2') then rep.payload ->> 'TradeLiquidityIndicator'
                                end,
                            'R')                                                                             AS liquidityindicator,
                   null::text                                                                                as secondary_order_id,
                   '0'                                                                                       as exch_exec_id,
                   CASE
                       WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
                       ELSE rep.payload ->> 'RouterExecId' END                                               as secondary_exch_exec_id,

    coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) as last_mkt,

                   (rep.payload ->> 'TransactQty')::int8                                                     AS lastshares,
                   case
                       when rep.exec_type in ('1', '2', 'r')
                           then round(coalesce(((rep.payload ->> 'LastPx2')::bigint)::numeric / 10000.0,
                                               ((rep.payload ->> 'LastPx')::bigint)::numeric) / 10000.0, 8)
                       else '0'::numeric
                       end                                                                                   as last_px,

                   rp.ex_destination,
                   'sub_strategy' as sub_strategy,
                   'order_id' as order_id,
                   coalesce(
                           case
                               when
                                   -- [ExpirationDate] <> '1900-01-01'
                                   case
                                       when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP')
                                           then coalesce(leg.ds_id_date, co.ds_id_date) end <> '1900-01-01'::date
                                       and
                                       -- tl.[Strike] <> 0.00
                                   case
                                       when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP')
                                           then coalesce(leg.ds_id_num, co.ds_id_num) end <> 0.00
                                   then
                                   -- tl.OptionQuantity
                                   case
                                       when co.instrument_type = 'O' then co.payload ->> 'OrderQty'
                                       when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'O'
                                           then leg.payload ->> 'LegQty' end
                               else
                                   -- tl.StockQuantity
                                   case
                                       when co.instrument_type = 'E' then co.payload ->> 'OrderQty'
                                       when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
                                           then leg.payload ->> 'LegQty'
                                       end end,
                       -- tl.Quantity
                           case
                               when co.instrument_type = 'E' then rep_last."LeavesQty"
                               when co.instrument_type = 'M' and leg.payload ->> 'LegInstrumentType' = 'E'
                                   then rep_last_exec."LeavesQty"
                               end
                   )                                                                                         as street_order_qty,
                   -- order_qty is as same as street_order_qty
                   case
                       when (coalesce(co.payload ->> 'NoLegs', '1'))::int > 1 then 2
                       else 1 end                                                                            as multileg_reporting_type,
                   coalesce(case
                                when co.crossing_side is null then co.payload #>> '{ClearingDetails,GiveUp}'
                                when co.crossing_side = 'O'
                                    then co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'
                                when co.crossing_side = 'C' then co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'
                                else null::text
                                end, rep.payload ->>
                                     'ManualBroker')                                                         as exec_broker,

                   CASE
                       WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'
                       WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'
                       WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'
                       ELSE NULL::text
                       END                                                                                   AS cmtafirm,

                   case
                       when coalesce(ltf.EDWID, tif.ID) in (24, 17, 10, 1, 44) then 0
                       when coalesce(ltf.EDWID, tif.ID) in (26, 18, 3, 45, 12) then 1
                       when coalesce(ltf.EDWID, tif.ID) in (31, 8, 15, 46) then 2
                       when coalesce(ltf.EDWID, tif.ID) in (47, 28, 11, 19, 5) then 3
                       when coalesce(ltf.EDWID, tif.ID) in (48, 2, 13, 25, 20) then 4
                       when coalesce(ltf.EDWID, tif.ID) in (36, 37, 38, 49) then 5
                       when coalesce(ltf.EDWID, tif.ID) in (50, 14, 21, 33) then 6
                       when coalesce(ltf.EDWID, tif.ID) in (32, 9, 16) then 7
                       end                                                                                   as street_time_in_force,

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
                       end                                                                                   as opt_customer_firm,


                   CASE
                       when co.crossing_side = 'C' and (SELECT co2.cl_ord_id
                                                        FROM blaze7.client_order co2
                                                        WHERE co2.cross_order_id = co.cross_order_id
                                                          AND co2.crossing_side = 'O'
                                                        ORDER BY co2.chain_id DESC
                                                        LIMIT 1) is not null then 'Y'
                       when co.crossing_side <> 'C' and (SELECT co2.cl_ord_id
                                                         FROM blaze7.client_order co2
                                                         WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId')::bigint)
                                                         ORDER BY co2.chain_id DESC
                                                         LIMIT 1) is not null then 'Y'
                       else 'N'
                       END                                                                                   as is_cross_order,
                   -- street_is_cross_order is as same as is_cross_order
                   COALESCE(co.payload ->> 'OwnerUserName', co.payload ->>
                                                            'InitiatorUserName')                             as contra_broker,
--        coalesce(comp.CompanyCode, u.Login) as client_id,
                   CASE
                       WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
                       WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
                       WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
                       WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
                       ELSE co.payload ->> 'Price'::text
                       END                                                                                   AS order_price,
                   '???'                                                                                     as order_process_time,
                   '???'                                                                                     as remarks,
                   null                                                                                      as street_client_order_id,
                   'LPEDWCOMPID'                                                                             as fix_comp_id,
                   rep.payload ->> 'LeavesQty',
                   CASE co.instrument_type
                       WHEN 'M' THEN leg.payload ->> 'LegSeqNumber'
                       ELSE '1'
                       END                                                                                   AS leg_ref_id,
                   CASE
                       -- ORIGOrderID <> '00000000-0000-0000-0000-000000000000'
                       WHEN CASE co.crossing_side
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
                           END is not null then 26
--                 tor.ContraOrderID <> '00000000-0000-0000-0000-000000000000' then 26
                       when CASE co.crossing_side
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
                           END is not null then 26
-- tor.ParentOrderID <> '00000000-0000-0000-0000-000000000000'
                       WHEN CASE
                                WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                                          FROM blaze7.client_order co2
                                                                          WHERE co2.order_id = co.parent_order_id
                                                                          ORDER BY co2.chain_id DESC
                                                                          LIMIT 1)
                                ELSE NULL::character varying
                           END is not null then 10
                       when
                           -- (tor.ParentOrderID = '00000000-0000-0000-0000-000000000000' and tor.ChildOrders != 0)
                           (CASE
                                WHEN co.parent_order_id IS NOT NULL THEN (SELECT co2.cl_ord_id
                                                                          FROM blaze7.client_order co2
                                                                          WHERE co2.order_id = co.parent_order_id
                                                                          ORDER BY co2.chain_id DESC
                                                                          LIMIT 1)
                                ELSE NULL::character varying
                                END is null
                               and exists (SELECT rep.payload ->> 'NoChildren'::text
                                           FROM blaze7.order_report rep
                                           WHERE rep.cl_ord_id::text = co.cl_ord_id::text
                                           ORDER BY rep.exec_id DESC)) then 10
                       WHEN co.payload ->> 'OrderTextComment' like '%OVR%' then 4
                       ELSE 50 end                                                                           as strategy_decision_reason_code,
                   case when co.parent_order_id is null then 'Y' else 'N' end                                as is_parent,

                   regexp_replace(COALESCE(leg.ds_id_2, co.ds_id_2, leg.ds_id_3, co.ds_id_3), '\.|-', '/', 'g') as symbol,

        round((CASE
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'
                ELSE co.payload ->> 'DashSecurityId'
            END, 'US:([FO|OP|EQ]{2})') = ANY (ARRAY['FO', 'OP']) THEN "substring"(
            CASE co.instrument_type
                WHEN 'M' THEN leg.payload ->> 'DashSecurityId'
                ELSE co.payload ->> 'DashSecurityId'
            END, '[0-9]{6}.(.+)$'::text)::numeric
        END)::numeric, 6) AS strike_price,

	case (CASE
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = 'EQ'::text THEN 'S'::text
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, '[0-9]{6}(.)'::text)
            ELSE NULL::text
        END)
		when 'P' then '0'
		when 'C' then '1'
	end as put_or_call,

                   CASE
                       WHEN "substring"(
                                    CASE co.instrument_type
                                        WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                                        ELSE co.payload ->> 'DashSecurityId'::text
                                        END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY ['FO'::text, 'OP'::text])
                           THEN to_date("substring"(
                                                CASE co.instrument_type
                                                    WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                                                    ELSE co.payload ->> 'DashSecurityId'::text
                                                    END, '([0-9]{6})'::text), 'YYMMDD'::text)
                       ELSE NULL::date
                       END as expiration_date,                                                                           -- will be transformed into maturity_year\month\day
                   CASE
                       WHEN rep.leg_ref_id IS NOT NULL THEN (SELECT leg.payload ->> 'LegInstrumentType'::text
                                                             FROM blaze7.client_order_leg leg
                                                             WHERE leg.order_id = rep.order_id
                                                               AND leg.chain_id = rep.chain_id
                                                               AND leg.leg_ref_id::text = rep.leg_ref_id::text)
                       ELSE rep.payload ->> 'InstrumentType'::text
                       END AS securitytype,

( SELECT rep.payload ->> 'NoChildren'::text
           FROM blaze7.order_report rep
          WHERE rep.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep.exec_id DESC
         LIMIT 1) as child_orders,
-- ISNULL(CASE WHEN r.OrderReportSpecialType = 'M' then lt.ID ELSE r.[Handling] END,0) [Handling]
 CASE
            WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' then lt.ID
            ELSE null
        END AS Handling,
                0 as secondary_order_id2,

   case when
			case when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP') then coalesce(leg.ds_id_date, co.ds_id_date) end <> '1900-01-01'::date
            and case when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP') then coalesce(leg.ds_id_num, co.ds_id_num) end <> 0.00 then

       replace(case
                        when
                            regexp_replace(coalesce(leg.ds_id_2, leg.ds_id_3), '\.|-', '') || ' '
                                || staging.get_exp_date(in_date := :in_date) || ' '
                                || case
                                       when case when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP') then coalesce(leg.ds_id_num, co.ds_id_num) end > 0
                                           and case when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP') then coalesce(leg.ds_id_num, co.ds_id_num) end < 1
                                           then to_char(case when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP') then coalesce(leg.ds_id_num, co.ds_id_num) end, 'FM999.999999')
                                       else staging.custom_format(case when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP') then coalesce(leg.ds_id_num, co.ds_id_num) end, 8)
                                end
                                || case when coalesce(leg.ds_id_1, co.ds_id_1) = 'EQ' then 'S' when coalesce(leg.ds_id_1, co.ds_id_1) in ('FO', 'OP') then left(coalesce(leg.ds_id_num, co.ds_id_num), 1) end
                                = 'ContractDesc'
                            then null end, '/', '')
				else regexp_replace(coalesce(leg.ds_id_2, leg.ds_id_3),'\.|-','')
		end  as display_instrument_id,


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
                       else coalesce(den1.mic_code, rp.ex_destination) end                                   as mic_code
--             , *
            from blaze7.order_report rep
                     join lateral (select *, case when co.instrument_type <> 'M' then "substring"(co.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end as ds_id_1,
                                          case when co.instrument_type <> 'M' then to_date("substring"(co.payload ->> 'DashSecurityId', '([0-9]{6})'), 'YYMMDD') end as ds_id_date,
                                          case when co.instrument_type <> 'M' then "substring"(co.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end as ds_id_num,
                                          case when co.instrument_type <> 'M' then "substring"(co.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end as ds_id_2,
                                          case when co.instrument_type <> 'M' then "substring"(co.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as ds_id_3
                                   from blaze7.client_order co
                                   where co.order_id = rep.order_id
                                     AND co.chain_id = rep.chain_id
                                   limit 1) co on true
                     LEFT JOIN lateral (select *, case when co.instrument_type = 'M' then "substring"(leg.payload ->> 'DashSecurityId', 'US:([FO|OP|EQ]{2})') end as ds_id_1,
                                               case when co.instrument_type = 'M' then to_date("substring"(leg.payload ->> 'DashSecurityId', '([0-9]{6})'), 'YYMMDD') end as ds_id_date,
                                               case when co.instrument_type = 'M' then "substring"(leg.payload ->> 'DashSecurityId', '[0-9]{6}.(.+)$') end as ds_id_num,
                                               case when co.instrument_type = 'M' then "substring"(leg.payload ->> 'DashSecurityId', 'US:EQ:(.+)') end as ds_id_2,
                                               case when co.instrument_type = 'M' then "substring"(leg.payload ->> 'DashSecurityId', 'US:[FO|OP]{2}:(.+)_') end as ds_id_3
                                        from blaze7.client_order_leg leg
                               where leg.order_id = co.order_id AND leg.chain_id = co.chain_id and
                                  leg.leg_ref_id = rep.leg_ref_id) leg on true
                     left join staging.TUsers u on u.ID = co.user_id
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
                     left join staging.TCompany comp on u.CompanyID = (CASE
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
            where rep.multileg_reporting_type <> '3'
              AND co.record_type in ('0', '2')
              AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i')
            and rep.db_create_time::date = '2024-06-10'::date
            )
select transactiondatetime,
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

       is_busted




from ct where is_busted = 'Y'
                   limit 5

  and co.cl_ord_id in ('1_kh240610','1_qv240610','b_1_qv240610')
    and rep.exec_id in ('ert9gm9c0g00', 'ert9gnp80g00', 'ert9golg0g04', 'ert9gomk0g00', 'ert9goms0g02');

select regexp_replace('abcd/\.-', '\.|-', '/', 'g') as symbol;

create function staging.get_exp_date(in_date date default null)
    returns text
    language plpgsql
as
$$
declare
begin
    if in_date is null then
        return null;
    end if;
    return lpad(extract(day from in_date)::text, 2, '0') ||
           to_char(in_date, 'Mon') ||
           to_char(in_date, 'YY');
end;
$$;

create or replace function staging.custom_format(in_numb numeric default null, in_len int default 8)
    returns text
    language plpgsql
as
$$
    -- the function works like the select cast(cast(in_numb as float) as varchar(in_len)) in T-sql
declare
    l_int_part     int;
    l_int_part_len int;
    l_adj          int := 2; -- adjustment keeping in mind decimal point and\or something else
begin
    if in_numb is null then
        return null;
    end if;

    select floor(in_numb) into l_int_part;
    select char_length(l_int_part::text) into l_int_part_len;
    return round(in_numb, in_len - l_int_part_len - l_adj);
end;
$$;


select lpad(extract(day from :in_date)::text, 2, '0')
select to_char(:in_date, 'Mon')
select to_char(:in_date, 'YY')


select * from staging.get_exp_date(in_date := :in_date)

select to_char(:in_numb,'FM999999999'), to_char(:in_numb,'FM99999.99999999');
select floor(:in_numb)

select staging.custom_format(12.1239456789, 8)