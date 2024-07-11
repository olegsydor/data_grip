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
           when coalesce(u.AORSUsername, u.Login) = 'BBNTRST' then 'NTRSCBOE'
           else coalesce(u.AORSUsername, Login) end                           as account_name,
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
       'order_id'                                                             as order_id,
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
                    end, rep.payload ->>
                         'ManualBroker')                                      as exec_broker,

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
       COALESCE(co.payload ->> 'OwnerUserName', co.payload ->>
                                                'InitiatorUserName')          as contra_broker,
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
       rep.db_create_time
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
where true
  and rep.multileg_reporting_type <> '3'
  AND co.record_type in ('0', '2')
  AND rep.exec_type not in ('f', 'w', 'W', 'g', 'G', 'I', 'i')

select *
from staging.v_away_trade_query
where true
  and db_create_time >= '2024-06-10'::date
  and db_create_time < '2024-06-11'::date
  and cl_ord_id = '3_32240610'