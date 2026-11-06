ANALYZE blaze7.order_report;
ANALYZE blaze7.client_order;
ANALYZE blaze7.client_order;
-- blaze7.tordermisc1_edw source
EXPLAIN (ANALYZE, BUFFERS)
select *
from blaze7.so_tordermisc1_edw x
where order_trade_date_id between 20261103 and public.get_dateid(public.get_business_date(20261103::text::date, 1))
  and db_create_time > ('2026-11-03 08:07:49.952'::timestamp at time zone 'US/Central' - interval '1 hour 10 second')
  AND (
    db_create_time::timestamp > '2026-11-03 08:07:49.952'::timestamp at time zone 'US/Central' - interval '10 second'
        or org_db_create_time::timestamp >
           '2026-11-03 08:07:49.952'::timestamp at time zone 'US/Central' - interval '10 second'
        or rep_db_create_time::timestamp >
           '2026-11-03 08:07:49.952'::timestamp at time zone 'US/Central' - interval '10 second')
;

select *
FROM blaze7.so_tordermisc1_edw as x
where order_trade_date_id between %(date_id)s and public.get_dateid(public.get_business_date(%(date_id)s::text::date, 1))
AND x.last_mod_time::timestamp >  %(max_processed_time_misc)s::timestamp at time zone 'US/Central' - interval '10 second'
 and x.db_create_time > (%(max_processed_time_misc)s::timestamp at time zone 'US/Central' - interval '1 hour 10 second')
  AND (
    x.db_create_time::timestamp > %(max_processed_time_misc)s::timestamp at time zone 'US/Central' - interval '10 second'
        or x.org_db_create_time::timestamp >
           %(max_processed_time_misc)s::timestamp at time zone 'US/Central' - interval '10 second'
        or x.rep_db_create_time::timestamp >
           %(max_processed_time_misc)s::timestamp at time zone 'US/Central' - interval '10 second')
;

-- blaze7.so_tordermisc1_edw source

CREATE OR REPLACE VIEW blaze7.so_tordermisc1_edw
AS SELECT NULL::text AS id,
    cl.cl_ord_id AS orderid,
    NULL::text AS systemid,
    NULL::text AS client,
    NULL::text AS trader,
    NULL::text AS isctboverridden,
    NULL::text AS stockquantity,
    NULL::text AS stockprice,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{ClearingDetails,Commission2}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,Commission2}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ClearingDetails,Commission2}'::text[]
            ELSE NULL::text
        END AS acctcomm,
    NULL::text AS issplitprice,
    NULL::text AS post,
    NULL::text AS station,
    cl.payload ->> 'IsCboeSPXCombo'::text AS isspxcombo,
    NULL::text AS exttts,
    NULL::text AS nocoa,
    NULL::text AS branchcode,
    NULL::text AS executionfirmoverride,
    NULL::text AS execsequence,
    NULL::text AS rejectorderid,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{ClearingDetails,FTID}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,FTID}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ClearingDetails,FTID}'::text[]
            ELSE NULL::text
        END AS ftid,
    cl.payload ->> 'ExecInst'::text AS execinst,
    NULL::text AS handling,
    COALESCE(cl.secondary_order_id, cl.order_id) AS ultransaction64,
    NULL::text AS isautoqctchild,
    NULL::text AS autoqctorderid,
    cl.payload ->> 'CrossingMechanism'::text AS crossingtypeid,
    cl.payload ->> 'StopPx'::text AS stoplimit,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload ->> 'CATOrderId'::text
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATOrderId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATOrderId}'::text[]
            ELSE NULL::text
        END AS catid,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{ClearingDetails,DashAliasId}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,DashAliasId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ClearingDetails,DashAliasId}'::text[]
            ELSE NULL::text
        END AS dashaliasid,
    cl.payload #>> '{AlgoDetails,MinQty}'::text[] AS minquantity,
    cl.payload #>> '{AlgoDetails,MinQty}'::text[] AS mindisplayqty,
    cl.payload #>> '{AlgoDetails,DashMaxFloor}'::text[] AS maxdisplayqty,
        CASE
            WHEN cl.crossing_side IS NULL AND (cl.payload ->> 'InitiatorUserId'::text) <> (cl.payload #>> '{ClearingDetails,CustomerUserId}'::text[]) THEN cl.payload #>> '{ClearingDetails,CustomerUserId}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar AND (cl.payload ->> 'InitiatorUserId'::text) <> (cl.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]) THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar AND (cl.payload ->> 'InitiatorUserId'::text) <> (cl.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]) THEN cl.payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]
            ELSE NULL::text
        END AS obouser,
    cl.payload ->> 'StockFloorBroker'::text AS stockfloorbroker,
        CASE
            WHEN cl.crossing_side IS NULL THEN lst.big_payload #>> '{CATDetails,FDID}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATDetails,FDID}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATDetails,FDID}'::text[]
            ELSE NULL::text
        END AS fdid,
        CASE
            WHEN cl.crossing_side IS NULL THEN lst.big_payload #>> '{CATDetails,IMID}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATDetails,IMID}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATDetails,IMID}'::text[]
            ELSE NULL::text
        END AS senderimid,
        CASE
            WHEN cl.crossing_side IS NULL THEN lst.big_payload #>> '{CATDetails,AffiliateFlag}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATDetails,AffiliateFlag}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATDetails,AffiliateFlag}'::text[]
            ELSE NULL::text
        END AS affiliateflag,
        CASE
            WHEN cl.crossing_side IS NULL THEN lst.big_payload #>> '{CATDetails,AccountHolderType}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATDetails,AccountHolderType}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATDetails,AccountHolderType}'::text[]
            ELSE NULL::text
        END AS accountholdertype,
        CASE
            WHEN cl.crossing_side IS NULL THEN lst.big_payload #>> '{CATDetails,BrokerDealer}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATDetails,BrokerDealer}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATDetails,BrokerDealer}'::text[]
            ELSE NULL::text
        END AS brokerdealer,
        CASE
            WHEN cl.order_class = 'F'::bpchar AND to_timestamp(lst.receivetime, 'YYYY-MM-DD"T"HH24:MI:SS'::text) = to_timestamp(cl.payload ->> 'OrderCreationTime'::text, 'YYYY-MM-DD"T"HH24:MI:SS'::text) THEN NULL::text
            ELSE lst.receivetime
        END AS receivetime,
    ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.order_id = COALESCE(
                CASE
                    WHEN cl.crossing_side IS NULL THEN cl.payload ->> 'ResendOrderId'::text
                    WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ResendOrderId}'::text[]
                    WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ResendOrderId}'::text[]
                    ELSE NULL::text
                END, '0'::text)::bigint
          ORDER BY cl.chain_id DESC
         LIMIT 1) AS resendparentid,
    COALESCE(cl.payload ->> 'IsRepresentative'::text, cl.payload #>> '{OriginatorOrder,IsRepresentative}'::text[], cl.payload #>> '{ContraOrder,IsRepresentative}'::text[], 'N'::text) AS representative,
        CASE cl.order_class
            WHEN 'F'::bpchar THEN ( SELECT co2.payload ->> 'ExtClOrdId'::text
               FROM blaze7.client_order co2
              WHERE co2.orig_order_id = cl.order_id AND co2.record_type = '1'::bpchar AND co2.order_class = 'F'::bpchar
              ORDER BY co2.order_id
             LIMIT 1)
            ELSE NULL::text
        END AS cxlclordid,
    cl.payload ->> 'OrderExpireDate'::text AS goodtilldate,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{ClearingDetails,ActionableId}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,ActionableId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ClearingDetails,ActionableId}'::text[]
            ELSE NULL::text
        END AS actionid,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{ClearingDetails,SocGenSalesTrader}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,SocGenSalesTrader}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ClearingDetails,SocGenSalesTrader}'::text[]
            ELSE NULL::text
        END AS sales_traders,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload ->> 'ExtClOrdId'::text
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ExtClOrdId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ExtClOrdId}'::text[]
            ELSE NULL::text
        END AS fixclordid,
    cl.payload #>> '{AlgoDetails,DashOptionRefPrice}'::text[] AS optionrefprice,
    cl.payload #>> '{AlgoDetails,DashStockRefPrice}'::text[] AS stockrefprice,
    COALESCE(((cl.payload #>> '{AlgoDetails,DashWorkingDelta2}'::text[])::numeric) / 10000.0, (cl.payload #>> '{AlgoDetails,DashWorkingDelta}'::text[])::numeric)::text AS workingdelta,
    cl.parent_order_id AS intparentorderid,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload ->> 'CATParentOrderId'::text
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATParentOrderId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATParentOrderId}'::text[]
            ELSE NULL::text
        END AS catparentid,
        CASE
            WHEN cl.order_class = 'F'::bpchar THEN cl.payload ->> 'OrderSource'::text
            ELSE NULL::text
        END AS ordersource,
        CASE
            WHEN cl.order_class = 'O'::bpchar AND cl.crossing_side IS NULL THEN cl.payload ->> 'OrderRefId'::text
            WHEN cl.order_class = 'O'::bpchar AND cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,OrderRefId}'::text[]
            WHEN cl.order_class = 'O'::bpchar AND cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,OrderRefId}'::text[]
            ELSE NULL::text
        END AS oboorderrefid,
    cl.payload ->> 'OwnerEntityId'::text AS ownercompanyid,
    cl.payload ->> 'CrossId'::text AS systemcrossid,
    cl.cross_order_id AS transaction64crossorderid,
    ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE cl.orig_order_id IS NULL AND co2.chain_id = 0 AND co2.order_id = COALESCE(lst.big_payload ->> 'RepresentativeOrderId'::text, lst.big_payload #>> '{OriginatorOrder,RepresentativeOrderId}'::text[], lst.big_payload #>> '{ContraOrder,RepresentativeOrderId}'::text[], '-1'::text)::bigint) AS representativeorderid,
    NULL::text AS catupdate,
        CASE
            WHEN cl.orig_order_id IS NOT NULL THEN '0'::text
            WHEN COALESCE(lst.big_payload ->> 'HasRepresentedOrders'::text, lst.big_payload #>> '{OriginatorOrder,HasRepresentedOrders}'::text[], lst.big_payload #>> '{ContraOrder,HasRepresentedOrders}'::text[]) = 'Y'::text THEN '1'::text
            ELSE '0'::text
        END AS hasrepresentedorder,
    cl.payload #>> '{AlgoDetails,CBOESessionEligibility}'::text[] AS cboesessioneligibility,
    (cl.payload #>> '{AlgoDetails,DashImpliedVolatility}'::text[])::numeric AS impliedvolatility,
    ((cl.payload ->> 'IsCabinet'::text))::character(1)::text AS cabinet,
    (cl.payload ->> 'ParentCrossOrderId'::text)::bigint AS transaction64parentcrossorderid,
        CASE
            WHEN cl.crossing_side IS NULL AND cl.orig_order_id IS NULL THEN lst.big_payload #>> '{OrderCallTime}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,OrderCallTime}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,OrderCallTime}'::text[]
            ELSE NULL::text
        END AS calltime,
        CASE
            WHEN cl.crossing_side IS NULL AND cl.orig_order_id IS NULL THEN lst.big_payload #>> '{CATDetails,CATElectronicOrderId}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATDetails,CATElectronicOrderId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATDetails,CATElectronicOrderId}'::text[]
            ELSE NULL::text
        END AS electronicorderid,
        CASE
            WHEN cl.crossing_side IS NULL AND cl.orig_order_id IS NULL THEN lst.big_payload #>> '{CATDetails,CATElectronicOrderTime}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,CATDetails,CATElectronicOrderTime}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,CATDetails,CATElectronicOrderTime}'::text[]
            ELSE NULL::text
        END AS electronicordertime,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{ClearingDetails,ClientInfo}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,ClientInfo}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ClearingDetails,ClientInfo}'::text[]
            ELSE NULL::text
        END AS clientinfo,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{OrderEventTime}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,OrderEventTime}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,OrderEventTime}'::text[]
            ELSE NULL::text
        END AS ordereventtime,
    cl.order_id,
    cl.chain_id,
    cl.db_create_time,
        CASE
            WHEN lst.is_q_time THEN staging.get_timestamp_from_date_ts(cl.order_trade_date::integer, lst.q_time)
            ELSE NULL::timestamp without time zone
        END AS boxqooannouncedtime,
        CASE
            WHEN cl.route_destination::text = 'BOX QOO'::text THEN cl.payload #>> '{BoxQOOAnnouncedTime}'::text[]
            ELSE NULL::text
        END AS boxqooannouncedtimev2,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{OrderNotes}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,OrderNotes}'::text[]
            ELSE NULL::text
        END AS ordernotes,
    cl.payload ->> 'CboeEquityBroker'::text AS cboeequitybroker,
    lst.order_trade_date_id,
    (cl.payload ->> 'AutoRouteRuleId'::text)::integer AS autorouteruleid,
    cl.payload ->> 'AutoRouteRuleName'::text AS autorouterulename,
    (cl.payload ->> 'IsAutoAccepted'::text)::bpchar AS isautoaccepted,
    (cl.payload ->> 'IsAutoRouted'::text)::bpchar AS isautorouted,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{NoLinkedOrders}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,NoLinkedOrders}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,NoLinkedOrders}'::text[]
            ELSE NULL::text
        END AS numberoflinkedorders,
    ((cl.payload ->> 'IsTiedToCombo'::text))::character(1) AS istiedtocombo,
    ((cl.payload ->> 'IsMerged'::text))::character(1) AS ismerged,
    ( SELECT co2.cl_ord_id
           FROM blaze7.client_order co2
          WHERE co2.order_id = ((cl.payload ->> 'MergedOrderId'::text)::bigint) AND (cl.payload ->> 'MergedOrderId'::text) IS NOT NULL AND co2.chain_id = 0
         LIMIT 1) AS mergedorderid,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{ClearingDetails,SocGenSubAccount}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,ClearingDetails,SocGenSubAccount}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,ClearingDetails,SocGenSubAccount}'::text[]
            ELSE NULL::text
        END AS socgensubaccount,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{SocGenRoutingChainId}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,SocGenRoutingChainId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,SocGenRoutingChainId}'::text[]
            ELSE NULL::text
        END AS sgchainid,
        CASE
            WHEN cl.crossing_side IS NULL THEN cl.payload #>> '{SocGenRoutingLinkedId}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,SocGenRoutingLinkedId}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,SocGenRoutingLinkedId}'::text[]
            ELSE NULL::text
        END AS sglinkedid,
    cl.payload ->> 'PrincipalEligibleFlag'::text AS principaleligible,
    cl.payload ->> 'IsCboeTiedHedge'::text AS iscboetiedhedge,
    cl.payload ->> 'FlexPriceType'::text AS flexpricetype,
    cl.payload ->> 'UserRoutingType'::text AS userroutingtype,
        CASE
            WHEN cl.crossing_side IS NULL THEN lst.big_payload #>> '{HasLinkedOrders}'::text[]
            WHEN cl.crossing_side = 'O'::bpchar THEN cl.payload #>> '{OriginatorOrder,HasLinkedOrders}'::text[]
            WHEN cl.crossing_side = 'C'::bpchar THEN cl.payload #>> '{ContraOrder,HasLinkedOrders}'::text[]
            ELSE NULL::text
        END AS haslinkedorders,
    cl.payload #>> '{AlgoDetails,OptionsSessionEligibility}'::text[] AS optionssessioneligibility,
    cl.payload #>> '{AlgoDetails,EquitiesSessionEligibility}'::text[] AS equitiessessioneligibility,
    rep.db_create_time AS rep_db_create_time,
    org.db_create_time AS org_db_create_time
   FROM blaze7.client_order cl
     JOIN LATERAL ( SELECT lst_1.payload AS big_payload,
                CASE
                    WHEN lst_1.route_destination::text = 'BOX QOO'::text AND (lst_1.payload ->> 'IsFlex'::text) = 'Y'::text THEN true
                    ELSE false
                END AS is_q_time,
                CASE
                    WHEN lst_1.route_destination::text = 'BOX QOO'::text AND (lst_1.payload ->> 'IsFlex'::text) = 'Y'::text THEN
                    CASE
                        WHEN lst_1.crossing_side = 'O'::bpchar THEN lst_1.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                        WHEN lst_1.crossing_side = 'C'::bpchar THEN ( SELECT co2.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                           FROM blaze7.client_order co2
                          WHERE co2.cross_order_id = lst_1.cross_order_id AND co2.crossing_side = 'O'::bpchar
                          ORDER BY co2.chain_id DESC
                         LIMIT 1)
                        ELSE NULL::text
                    END
                    ELSE NULL::text
                END AS q_time,
            lst_1.order_trade_date AS order_trade_date_id,
                CASE
                    WHEN lst_1.crossing_side IS NULL AND lst_1.orig_order_id IS NOT NULL AND lst_1.route_type = 'S'::bpchar THEN ( SELECT co2.payload ->> 'OrderReceiveTime'::text
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = lst_1.cl_ord_id::text
                      ORDER BY co2.chain_id DESC
                     LIMIT 1)
                    WHEN lst_1.crossing_side IS NULL AND lst_1.orig_order_id IS NOT NULL THEN ( SELECT co2.payload ->> 'OrderReceiveTime'::text
                       FROM blaze7.client_order co2
                      WHERE co2.cl_ord_id::text = lst_1.cl_ord_id::text AND co2.chain_id = 0
                     LIMIT 1)
                    WHEN lst_1.crossing_side IS NULL AND cl.orig_order_id IS NULL THEN lst_1.payload ->> 'OrderReceiveTime'::text
                    WHEN lst_1.crossing_side = 'O'::bpchar THEN lst_1.payload #>> '{OriginatorOrder,OrderReceiveTime}'::text[]
                    WHEN lst_1.crossing_side = 'C'::bpchar THEN lst_1.payload #>> '{ContraOrder,OrderReceiveTime}'::text[]
                    ELSE NULL::text
                END AS receivetime,
                        lst_1.cl_ord_id,
                        lst_1.chain_id
           FROM blaze7.client_order lst_1
          WHERE lst_1.cl_ord_id = cl.cl_ord_id
          ORDER BY lst_1.chain_id DESC
         LIMIT 1) lst ON true and lst.cl_ord_id = cl.cl_ord_id and lst.chain_id = cl.chain_id
     JOIN LATERAL ( SELECT rep_1.db_create_time
           FROM blaze7.order_report rep_1
          WHERE rep_1.order_id = cl.order_id AND rep_1.chain_id = cl.chain_id
         LIMIT 1) rep ON true
     LEFT JOIN LATERAL ( SELECT org_1.db_create_time
           FROM blaze7.client_order org_1
          WHERE org_1.orig_order_id IS NOT NULL AND org_1.orig_order_id = cl.order_id AND org_1.db_create_time >= cl.db_create_time
         LIMIT 1) org ON true
  WHERE true AND (cl.record_type = ANY (ARRAY['0'::bpchar, '2'::bpchar]));
