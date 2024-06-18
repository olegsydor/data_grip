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

create function staging.get_status(in_exec_type bpchar,
                                   in_child_exec_ref_id text,
                                   in_originated_by text)
    returns bpchar
    language sql
as
$$

select case
           when in_exec_type in ('e', 'd') then
               (select case
                           when rp.exec_type = '4' and (rp.payload ->> 'OriginatedBy') = 'E' then 'F'
                           else rp.exec_type
                           end as exec_type
                from blaze7.order_report rp
                where rp.exec_id::text = in_child_exec_ref_id)
           when in_exec_type = '4'::bpchar and in_originated_by = 'e'
               then 'F'::bpchar
           else in_exec_type
           end
$$;

select rep.payload ->> 'TransactTime'                                                    AS transactiondatetime,
       to_char((rep.payload ->> 'TransactTime')::timestamp, 'YYYYMMDD')::int4            AS transactiondatetime,
       'is_busted!!!',
       'LPEDW'                                                                           as subsystem_id,
       case
           when coalesce(u.AORSUsername, u.Login) = 'BBNTRST' then 'NTRSCBOE'
           else coalesce(u.AORSUsername, Login) end                                      as account_name,
       co.cl_ord_id,
       'instrument_id',
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'LegSide'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'
           WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'
           WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'
           END                                                                           AS side,
       CASE
           WHEN co.instrument_type = 'M' THEN leg.payload ->> 'PositionEffect'
           WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'
           WHEN co.crossing_side = 'O' THEN co.payload #>> '{OriginatorOrder,PositionEffect}'
           WHEN co.crossing_side = 'C' THEN co.payload #>> '{ContraOrder,PositionEffect}'
           ELSE NULL::text
           END                                                                           AS openclose,
       'exec_id'                                                                                as exec_id, -- identity
       '???'                                                                             as exchange_id,
       CASE
           WHEN rep.exec_type in ('1', '2') THEN rep.payload ->> 'TradeLiquidityIndicator'::text
           ELSE NULL::text
           END                                                                           AS liquidityindicator,
       null::text                                                                        as secondary_order_id,
       '0'                                                                               as exch_exec_id,
       CASE
           WHEN rep.payload ->> 'OrderReportSpecialType' = 'M' THEN 'Manual Report'
           ELSE rep.payload ->> 'RouterExecId' END                                       as secondary_exch_exec_id,

       case
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in
                ('CBOE-CRD NO BK', 'PAR', 'CBOIE') then 'W'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in ('XPAR', 'PLAK', 'PARL')
               then 'LQPT'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in
                ('SOHO', 'KNIGHT', 'LSCI', 'NOM')
               then 'ECUT'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in ('FOGS', 'MID') then 'XCHI'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in ('C2', 'CBOE2') then 'C2OX'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) = 'SMARTR' then 'COWEN'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in
                ('ACT', 'BOE', 'OTC', 'lp', 'VOL')
               then 'BRKPT'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in ('XPSE') then 'N'
           when coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination) in ('TO') then '1'
           else nullif(coalesce(den.last_mkt, den1.last_mkt, rp.ex_destination), '') end as last_mkt,
(rep.payload ->> 'TransactQty')::int8 AS lastshares,
       case
           when rep.exec_type in ('1', '2', 'r')
               then round(coalesce(((rep.payload ->> 'LastPx2')::bigint)::numeric / 10000.0,
                                   ((rep.payload ->> 'LastPx')::bigint)::numeric) / 10000.0, 8)
           else '0'::numeric
           end as last_px,

       rp.ex_destination,
       'sub_strategy',
       'order_id',
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
           else coalesce(den1.mic_code, rp.ex_destination) end                           as mic_code,


       *
from blaze7.order_report rep
         join lateral (select *
                       from blaze7.client_order co
                       where co.order_id = rep.order_id
                         AND co.chain_id = rep.chain_id
                       limit 1) co on true
         LEFT JOIN blaze7.client_order_leg leg
                   ON leg.order_id = co.order_id AND leg.chain_id = co.chain_id and
                      leg.leg_ref_id = rep.leg_ref_id
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
where rep.exec_id in ('ert9gm9c0g00', 'ert9gnp80g00', 'ert9golg0g04', 'ert9gomk0g00', 'ert9goms0g02');

