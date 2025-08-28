create temp table t_alias as
select co.cl_ord_id, account_alias
from blaze7.client_order co
         join lateral (select leg.order_id, leg.chain_id
                       from blaze7.client_order_leg leg
                       join blaze7.client_order cl on leg.order_id = cl.order_id and leg.chain_id = cl.chain_id
                       where true
                         and leg.payload ->> 'StitchedSingleOrderId' = co.order_id::text
                       and cl.db_create_time >= co.db_create_time
                       limit 1) leg on true
         join lateral (select cl.payload->> 'AccountAlias' as account_alias
                       from blaze7.client_order cl
                       where cl.order_id = leg.order_id and cl.chain_id = leg.chain_id
                       limit 1) cl on true
where co.payload ->> 'OrderClass' = 'F'
  and co.payload ->> 'HasStitchedOrders' = 'Y'
  and co.db_create_time::date = '2025-08-25'
  and co.cl_ord_id in ('f_0_3q250821', 'f_0_3m250821');



select order_id, payload->>'OrderClass', payload->>'HasStitchedOrders',*
from blaze7.client_order co
where co.cl_ord_id in ('f_0_3q250821','f_0_3m250821');


select payload->> 'StitchedSingleOrderId', *
from blaze7.client_order_leg
where payload->> 'StitchedSingleOrderId' is not null
and payload->> 'StitchedSingleOrderId' in ('813044674737471488', '813044804358242304')

select order_id, payload->>'OrderClass', payload->>'HasStitchedOrders', co.payload ->> 'AccountAlias', *
from blaze7.client_order co
where order_id in (813044874646388736, 813045540504731648)
/*
 if blaze7.client_order.order_class = 'F' and payload ->> 'HasStitchedOrders' = 'Y', then go to:
blaze7.client_order_leg find a leg that has payload.StitchedSingleOrderId = order_id of the order in p.1, if found, then:
go to blaze7.client_order -> payload -> AccountAlias (or OriginatorOrder.AccountAlias) for the order found on step 2
*/
drop view blaze7.v_away_trade1
create or replace drop view blaze7.v_stitched_alias as
select co.order_id, co.chain_id, co.cl_ord_id, account_alias, payload ->> 'OwnerEntityId'
from blaze7.client_order co
         join lateral (select leg.order_id, leg.chain_id
                       from blaze7.client_order cl
                                join blaze7.client_order_leg leg
                                     on leg.order_id = cl.order_id and leg.chain_id = cl.chain_id
                       where true
                         and leg.payload ->> 'StitchedSingleOrderId' = co.order_id::text
                         and cl.db_create_time >= co.db_create_time
                         and cl.db_create_time >= current_date - '20 days'::interval
                       limit 1) leg on true
         join lateral (select CASE
                                  WHEN cl.crossing_side IS NULL THEN cl.payload ->> 'AccountAlias'::text
                                  WHEN cl.crossing_side = 'O'::bpchar
                                      THEN cl.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
                                  WHEN cl.crossing_side = 'C'::bpchar
                                      THEN cl.payload #>> '{ContraOrder,AccountAlias}'::text[]
                                  ELSE NULL::text
                                  END AS account_alias
                       from blaze7.client_order cl
                       where cl.order_id = leg.order_id
                         and cl.chain_id = leg.chain_id
                       limit 1) cl on true
where co.payload ->> 'OrderClass' = 'F'
  and co.payload ->> 'HasStitchedOrders' = 'Y'
  and co.payload ->> 'OwnerEntityId' = '3681'
  and co.db_create_time >= current_date - '20 days'::interval
  and co.db_create_time < current_date + '1 days'::interval;

select * from blaze7.v_stitched_alias;



-- blaze7.v_away_trade source

CREATE OR REPLACE VIEW blaze7.v_away_trade
AS SELECT rep.payload ->> 'ManualExecutionTime'::text AS manualexecutiontime,
    rep.payload ->> 'TransactTime'::text AS transactiondatetime,
        CASE
            WHEN rep.exec_type = ANY (ARRAY['e'::bpchar, 'd'::bpchar]) THEN ( SELECT
                    CASE
                        WHEN rp.exec_type = '4'::bpchar AND (rp.payload ->> 'OriginatedBy'::text) = 'E'::text THEN 'F'::bpchar
                        ELSE rp.exec_type
                    END AS exec_type
               FROM blaze7.order_report rp
              WHERE rp.exec_id::text = (rep.payload ->> 'ChildExecRefId'::text))
            WHEN rep.exec_type = '4'::bpchar AND (rep.payload ->> 'OriginatedBy'::text) = 'E'::text THEN 'F'::bpchar
            ELSE rep.exec_type
        END AS status,
        CASE
            WHEN co.order_class = 'F'::bpchar THEN co.payload ->> 'InitiatorUserId'::text
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'ClientUserId'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClientUserId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClientUserId}'::text[]
            ELSE NULL::text
        END AS userid,
    rep.payload ->> 'LiquidityType'::text AS liquiditytype,
    rep.is_busted::text AS bustreason,
        CASE
            WHEN rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar]) THEN rep.payload ->> 'TradeLiquidityIndicator'::text
            ELSE NULL::text
        END AS liquidityindicator,
    NULL::text AS exchangemappedorderid,
        CASE
            WHEN (rep.payload ->> 'OrderReportSpecialType'::text) = 'M'::text THEN 'M'::text
            ELSE NULL::text
        END AS orderreportspecialtype,
    rep.payload ->> 'RouterExecId'::text AS exchangetransactionid,
        CASE
            WHEN rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar, 'r'::bpchar]) THEN rep.payload ->> 'LastMkt'::text
            ELSE NULL::text
        END AS exdestination,
    rep.payload ->> 'TransactQty'::text AS lastshares,
    rep.payload ->> 'ManualBroker'::text AS executingbroker,
    COALESCE(co.payload ->> 'OwnerUserName'::text, co.payload ->> 'InitiatorUserName'::text) AS contrabroker,
    rep.payload ->> 'LeavesQty'::text AS leavesqty,
        CASE
            WHEN co.parent_order_id IS NOT NULL THEN ( SELECT client_order.cl_ord_id
               FROM blaze7.client_order
              WHERE client_order.order_id = co.parent_order_id
             LIMIT 1)
            ELSE NULL::character varying
        END AS parentid,
        CASE
            WHEN rep.leg_ref_id IS NOT NULL THEN ( SELECT leg_1.payload ->> 'LegInstrumentType'::text
               FROM blaze7.client_order_leg leg_1
              WHERE leg_1.order_id = rep.order_id AND leg_1.chain_id = rep.chain_id AND leg_1.leg_ref_id::text = rep.leg_ref_id::text)
            ELSE co.payload ->> 'InstrumentType'::text
        END AS securitytype,
    NULL::text AS handling,
        CASE
            WHEN rep.leg_ref_id IS NOT NULL THEN ( SELECT leg_1.payload ->> 'LegSeqNumber'::text
               FROM blaze7.client_order_leg leg_1
              WHERE leg_1.order_id = rep.order_id AND leg_1.chain_id = rep.chain_id AND leg_1.leg_ref_id::text = rep.leg_ref_id::text)
            ELSE '1'::text
        END AS legnumber,
    rep.cl_ord_id AS orderid,
    rep.exec_id AS reportid,
    COALESCE(rep.payload ->> 'ChildExecRefId'::text, rep.exec_id::text) AS childreportid,
        CASE
            WHEN rep.exec_type = ANY (ARRAY['1'::bpchar, '2'::bpchar, 'r'::bpchar]) THEN COALESCE(((rep.payload ->> 'LastPx2'::text)::bigint)::numeric / 10000.0, ((rep.payload ->> 'LastPx'::text)::bigint)::numeric / 1.0)::text
            ELSE '0'::text
        END AS lastprice,
    rep.order_id,
    rep.chain_id,
    COALESCE(co.payload ->> 'NoLegs'::text, '1'::text) AS legcount,
        CASE
            WHEN co.route_destination::text = 'VEGA'::text THEN 'VEGA'::bpchar
            WHEN (co.payload ->> 'HasStitchedOrders'::text) = 'Y'::text THEN 'StitchedSingle'::bpchar
            WHEN COALESCE(co.payload ->> 'IsStitched'::text, co.payload #>> '{OriginatorOrder,IsStitched}'::text[]) = 'Y'::text THEN 'StitchedSpread'::bpchar
            WHEN co.order_class = ANY (ARRAY['I'::bpchar, 'X'::bpchar]) THEN 'G'::bpchar
            ELSE co.order_class
        END AS systemordertypeid,
    co.payload ->> 'TimeInForce'::text AS timeinforcecode,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,OptionRange}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,OptionRange}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,OptionRange}'::text[]
            ELSE NULL::text
        END AS forwhom,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,GiveUp}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,GiveUp}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,GiveUp}'::text[]
            ELSE NULL::text
        END AS giveupfirm,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,CMTA}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,CMTA}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,CMTA}'::text[]
            ELSE NULL::text
        END AS cmtafirm,
        CASE co.crossing_side
            WHEN 'C'::bpchar THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.cross_order_id = co.cross_order_id AND co2.crossing_side = 'O'::bpchar
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = ((co.payload ->> 'OriginatorOrderRefId'::text)::bigint)
              ORDER BY co2.chain_id DESC
             LIMIT 1)
        END AS origorderid,
        CASE co.crossing_side
            WHEN 'O'::bpchar THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.cross_order_id = co.cross_order_id AND co2.crossing_side = 'C'::bpchar
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE ((co2.payload ->> 'OriginatorOrderRefId'::text)::bigint) = co.order_id AND co2.record_type = '0'::bpchar AND co2.chain_id = 0 AND co2.db_create_time >= co.db_create_time::date AND co2.db_create_time <= (co.db_create_time::date + '1 day'::interval)
              ORDER BY co2.chain_id DESC
             LIMIT 1)
        END AS contraorderid,
        CASE
            WHEN co.parent_order_id IS NOT NULL THEN ( SELECT co2.cl_ord_id
               FROM blaze7.client_order co2
              WHERE co2.order_id = co.parent_order_id
              ORDER BY co2.chain_id DESC
             LIMIT 1)
            ELSE NULL::character varying
        END AS parentorderid,
    ( SELECT rep_1.payload ->> 'NoChildren'::text
           FROM blaze7.order_report rep_1
          WHERE rep_1.cl_ord_id::text = co.cl_ord_id::text
          ORDER BY rep_1.exec_id DESC
         LIMIT 1) AS childorders,
    co.payload ->> 'OrderTextComment'::text AS comment,
    co.payload ->> 'ProductDescription'::text AS contractdesc,
        coalesce(CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'AccountAlias'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,AccountAlias}'::text[]
            ELSE NULL::text
        END, stc.account_alias) as accountalias,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'Generation'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Generation}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Generation}'::text[]
            ELSE NULL::text
        END AS generation,
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'LegSeqNumber'::text
            ELSE '1'::text
        END AS leg_legnumber,
        CASE
            WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'LegSide'::text
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'Side'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Side}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Side}'::text[]
            ELSE NULL::text
        END AS side,
        CASE
            WHEN co.instrument_type = 'M'::bpchar THEN leg.payload ->> 'PositionEffect'::text
            WHEN co.crossing_side IS NULL THEN co.payload ->> 'PositionEffect'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,PositionEffect}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,PositionEffect}'::text[]
            ELSE NULL::text
        END AS openclose,
        CASE
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN to_date("substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, '([0-9]{6})'::text), 'YYMMDD'::text)
            ELSE NULL::date
        END AS expirationdate,
        CASE
            WHEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, 'US:([FO|OP|EQ]{2})'::text) = ANY (ARRAY['FO'::text, 'OP'::text]) THEN "substring"(
            CASE co.instrument_type
                WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
                ELSE co.payload ->> 'DashSecurityId'::text
            END, '[0-9]{6}.(.+)$'::text)::numeric
            ELSE NULL::numeric
        END AS strike,
        CASE
            WHEN co.instrument_type = 'O'::bpchar THEN co.payload ->> 'OrderQty'::text
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'O'::text THEN leg.payload ->> 'LegQty'::text
            ELSE NULL::text
        END AS optionquantity,
        CASE
            WHEN co.instrument_type = 'E'::bpchar THEN co.payload ->> 'OrderQty'::text
            WHEN co.instrument_type = 'M'::bpchar AND (leg.payload ->> 'LegInstrumentType'::text) = 'E'::text THEN leg.payload ->> 'LegQty'::text
            ELSE NULL::text
        END AS stockquantity,
    COALESCE(co.payload ->> 'DashTargetVega'::text, co.payload ->> 'OrderQty'::text) AS quantity,
    COALESCE(
        CASE
            WHEN co.instrument_type <> 'M'::bpchar THEN co.payload ->> 'Price'::text
            WHEN (leg.payload ->> 'LegPrice'::text) IS NOT NULL THEN leg.payload ->> 'LegPrice'::text
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,Price}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,Price}'::text[]
            ELSE co.payload ->> 'Price'::text
        END, '0'::text) AS price,
    COALESCE("substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:EQ:(.+)'::text), "substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:[FO|OP]{2}:(.+)_'::text)) AS basecode,
        CASE
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
        END AS typecode,
    COALESCE("substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:EQ:(.+)'::text), "substring"(
        CASE co.instrument_type
            WHEN 'M'::bpchar THEN leg.payload ->> 'DashSecurityId'::text
            ELSE co.payload ->> 'DashSecurityId'::text
        END, 'US:[FO|OP]{2}:(.+)_'::text)) AS rootcode,
        CASE
            WHEN co.crossing_side IS NULL THEN co.payload #>> '{ClearingDetails,DashAliasId}'::text[]
            WHEN co.crossing_side = 'O'::bpchar THEN co.payload #>> '{OriginatorOrder,ClearingDetails,DashAliasId}'::text[]
            WHEN co.crossing_side = 'C'::bpchar THEN co.payload #>> '{ContraOrder,ClearingDetails,DashAliasId}'::text[]
            ELSE NULL::text
        END AS dashaliasid,
    rep.db_create_time AS report_db_create_time,
    co.order_trade_date AS order_trade_date_id,
    ((co.payload #>> '{ClearingDetails,Commission2}'::text[])::bigint)::numeric / 100000000.0 AS commission_rate_unit
   FROM blaze7.order_report rep
     JOIN LATERAL ( SELECT co_1.order_id,
            co_1.chain_id,
            co_1.parent_order_id,
            co_1.orig_order_id,
            co_1.record_type,
            co_1.user_id,
            co_1.entity_id,
            co_1.payload,
            co_1.db_create_time,
            co_1.cross_order_id,
            co_1.cl_ord_id,
            co_1.orig_cl_ord_id,
            co_1.crossing_side,
            co_1.instrument_type,
            co_1.order_class,
            co_1.route_type,
            co_1.creation_date_id,
            co_1.order_request_type,
            co_1.secondary_order_id,
            co_1.chain_order_id,
            co_1.order_trade_date,
            co_1.route_destination,
            co_1.underlying_request_type
           FROM blaze7.client_order co_1
          WHERE co_1.order_id = rep.order_id AND co_1.chain_id = rep.chain_id AND co_1.order_trade_date >= to_char(rep.db_create_time, 'YYYYMMDD'::text)::integer
         LIMIT 1) co ON true
     LEFT JOIN blaze7.client_order_leg leg ON leg.order_id = co.order_id AND leg.chain_id = co.chain_id AND COALESCE(rep.leg_ref_id, '0'::character varying)::text = leg.leg_ref_id::text
   left join lateral(select account_alias from blaze7.v_stitched_alias stc where stc.order_id = co.order_id and stc.chain_id = co.chain_id limit 1) stc on true
  WHERE rep.multileg_reporting_type <> '3'::bpchar AND (co.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar])) AND (rep.exec_type::text <> ALL (ARRAY['f'::text, 'w'::text, 'W'::text, 'g'::text, 'G'::text, 'I'::text, 'i'::text]));

create temp table t_01 as
select * from blaze7.v_away_trade
where reportid between 'mjf2he0s0000' and 'mjgg442o0000'
except;
create temp table t_02 as
select * from blaze7.v_away_trade1
where reportid between 'mjf2he0s0000' and 'mjgg442o0000'

create view blaze7.v_real_account_alias as
select case
           when co.crossing_side is null then co.payload ->> 'AccountAlias'::text
           when co.crossing_side = 'o'::bpchar then co.payload #>> '{OriginatorOrder,AccountAlias}'::text[]
           when co.crossing_side = 'c'::bpchar then co.payload #>> '{ContraOrder,AccountAlias}'::text[]
           else null::text
           end as accountalias,
       cl_ord_id,
       order_id,
       user_id,
       db_create_time,
       instrument_type,
       route_type
from blaze7.client_order co
where db_create_time::date >= current_date - '7 days'::interval;
and cl_ord_id in ('1_a3250821', 'f_0_3q250821')


