-- blaze7.tordermisc1_edw source
select * from blaze7.so_tordermisc1_edw x
         where order_trade_date_id between 20261103 and public.get_dateid(public.get_business_date(20261103::text::date, 1))
AND (_db_create_time::timestamp > '2026-11-03 08:07:49.952'::timestamp at time zone 'US/Central' - interval '10 second'
or org_db_create_time
;


CREATE OR REPLACE VIEW blaze7.so_tordermisc1_edw
AS
SELECT NULL::text                                                                      AS id,
       cl_ord_id                                                                       AS orderid,
       NULL::text                                                                      AS systemid,
       NULL::text                                                                      AS client,
       NULL::text                                                                      AS trader,
       NULL::text                                                                      AS isctboverridden,
       NULL::text                                                                      AS stockquantity,
       NULL::text                                                                      AS stockprice,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{ClearingDetails,Commission2}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,ClearingDetails,Commission2}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ClearingDetails,Commission2}'::text[]
           ELSE NULL::text
           END                                                                         AS acctcomm,
       NULL::text                                                                      AS issplitprice,
       NULL::text                                                                      AS post,
       NULL::text                                                                      AS station,
       payload ->> 'IsCboeSPXCombo'::text                                              AS isspxcombo,
       NULL::text                                                                      AS exttts,
       NULL::text                                                                      AS nocoa,
       NULL::text                                                                      AS branchcode,
       NULL::text                                                                      AS executionfirmoverride,
       NULL::text                                                                      AS execsequence,
       NULL::text                                                                      AS rejectorderid,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{ClearingDetails,FTID}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,ClearingDetails,FTID}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ClearingDetails,FTID}'::text[]
           ELSE NULL::text
           END                                                                         AS ftid,
       payload ->> 'ExecInst'::text                                                    AS execinst,
       NULL::text                                                                      AS handling,
       COALESCE(secondary_order_id, order_id)                                          AS ultransaction64,
       NULL::text                                                                      AS isautoqctchild,
       NULL::text                                                                      AS autoqctorderid,
       payload ->> 'CrossingMechanism'::text                                           AS crossingtypeid,
       payload ->> 'StopPx'::text                                                      AS stoplimit,
       CASE
           WHEN crossing_side IS NULL THEN payload ->> 'CATOrderId'::text
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATOrderId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATOrderId}'::text[]
           ELSE NULL::text
           END                                                                         AS catid,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{ClearingDetails,DashAliasId}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,ClearingDetails,DashAliasId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ClearingDetails,DashAliasId}'::text[]
           ELSE NULL::text
           END                                                                         AS dashaliasid,
       payload #>> '{AlgoDetails,MinQty}'::text[]                                      AS minquantity,
       payload #>> '{AlgoDetails,MinQty}'::text[]                                      AS mindisplayqty,
       payload #>> '{AlgoDetails,DashMaxFloor}'::text[]                                AS maxdisplayqty,
       CASE
           WHEN crossing_side IS NULL AND
                (payload ->> 'InitiatorUserId'::text) <> (payload #>> '{ClearingDetails,CustomerUserId}'::text[])
               THEN payload #>> '{ClearingDetails,CustomerUserId}'::text[]
           WHEN crossing_side = 'O'::bpchar AND (payload ->> 'InitiatorUserId'::text) <>
                                                (payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[])
               THEN payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[]
           WHEN crossing_side = 'C'::bpchar AND (payload ->> 'InitiatorUserId'::text) <>
                                                (payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[])
               THEN payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[]
           ELSE NULL::text
           END                                                                         AS obouser,
       payload ->> 'StockFloorBroker'::text                                            AS stockfloorbroker,
       CASE
           WHEN crossing_side IS NULL THEN big_payload #>> '{CATDetails,FDID}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATDetails,FDID}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATDetails,FDID}'::text[]
           ELSE NULL::text
           END                                                                         AS fdid,
       CASE
           WHEN crossing_side IS NULL THEN big_payload #>> '{CATDetails,IMID}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATDetails,IMID}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATDetails,IMID}'::text[]
           ELSE NULL::text
           END                                                                         AS senderimid,
       CASE
           WHEN crossing_side IS NULL THEN big_payload #>> '{CATDetails,AffiliateFlag}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATDetails,AffiliateFlag}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATDetails,AffiliateFlag}'::text[]
           ELSE NULL::text
           END                                                                         AS affiliateflag,
       CASE
           WHEN crossing_side IS NULL THEN big_payload #>> '{CATDetails,AccountHolderType}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATDetails,AccountHolderType}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATDetails,AccountHolderType}'::text[]
           ELSE NULL::text
           END                                                                         AS accountholdertype,
       CASE
           WHEN crossing_side IS NULL THEN big_payload #>> '{CATDetails,BrokerDealer}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATDetails,BrokerDealer}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATDetails,BrokerDealer}'::text[]
           ELSE NULL::text
           END                                                                         AS brokerdealer,
       CASE
           WHEN order_class = 'F'::bpchar AND to_timestamp(receivetime, 'YYYY-MM-DD"T"HH24:MI:SS'::text) =
                                              to_timestamp(payload ->> 'OrderCreationTime'::text,
                                                           'YYYY-MM-DD"T"HH24:MI:SS'::text) THEN NULL::text
           ELSE receivetime
           END                                                                         AS receivetime,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.order_id = COALESCE(
                CASE
                    WHEN crossing_side IS NULL THEN payload ->> 'ResendOrderId'::text
                    WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,ResendOrderId}'::text[]
                    WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ResendOrderId}'::text[]
                    ELSE NULL::text
                    END, '0'::text)::bigint
        ORDER BY chain_id DESC
        LIMIT 1)                                                                       AS resendparentid,
       COALESCE(payload ->> 'IsRepresentative'::text, payload #>> '{OriginatorOrder,IsRepresentative}'::text[],
                payload #>> '{ContraOrder,IsRepresentative}'::text[], 'N'::text)       AS representative,
       CASE order_class
           WHEN 'F'::bpchar THEN (SELECT co2.payload ->> 'ExtClOrdId'::text
                                  FROM blaze7.client_order co2
                                  WHERE co2.orig_order_id = order_id
                                    AND co2.record_type = '1'::bpchar
                                    AND co2.order_class = 'F'::bpchar
                                  ORDER BY co2.order_id
                                  LIMIT 1)
           ELSE NULL::text
           END                                                                         AS cxlclordid,
       payload ->> 'OrderExpireDate'::text                                             AS goodtilldate,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{ClearingDetails,ActionableId}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,ClearingDetails,ActionableId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ClearingDetails,ActionableId}'::text[]
           ELSE NULL::text
           END                                                                         AS actionid,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{ClearingDetails,SocGenSalesTrader}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>>
                                                 '{OriginatorOrder,ClearingDetails,SocGenSalesTrader}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ClearingDetails,SocGenSalesTrader}'::text[]
           ELSE NULL::text
           END                                                                         AS sales_traders,
       CASE
           WHEN crossing_side IS NULL THEN payload ->> 'ExtClOrdId'::text
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,ExtClOrdId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ExtClOrdId}'::text[]
           ELSE NULL::text
           END                                                                         AS fixclordid,
       payload #>> '{AlgoDetails,DashOptionRefPrice}'::text[]                          AS optionrefprice,
       payload #>> '{AlgoDetails,DashStockRefPrice}'::text[]                           AS stockrefprice,
       COALESCE(((payload #>> '{AlgoDetails,DashWorkingDelta2}'::text[])::numeric) / 10000.0,
                (payload #>> '{AlgoDetails,DashWorkingDelta}'::text[])::numeric)::text AS workingdelta,
       parent_order_id                                                                 AS intparentorderid,
       CASE
           WHEN crossing_side IS NULL THEN payload ->> 'CATParentOrderId'::text
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATParentOrderId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATParentOrderId}'::text[]
           ELSE NULL::text
           END                                                                         AS catparentid,
       CASE
           WHEN order_class = 'F'::bpchar THEN payload ->> 'OrderSource'::text
           ELSE NULL::text
           END                                                                         AS ordersource,
       CASE
           WHEN order_class = 'O'::bpchar AND crossing_side IS NULL THEN payload ->> 'OrderRefId'::text
           WHEN order_class = 'O'::bpchar AND crossing_side = 'O'::bpchar
               THEN payload #>> '{OriginatorOrder,OrderRefId}'::text[]
           WHEN order_class = 'O'::bpchar AND crossing_side = 'C'::bpchar
               THEN payload #>> '{ContraOrder,OrderRefId}'::text[]
           ELSE NULL::text
           END                                                                         AS oboorderrefid,
       payload ->> 'OwnerEntityId'::text                                               AS ownercompanyid,
       payload ->> 'CrossId'::text                                                     AS systemcrossid,
       cross_order_id                                                                  AS transaction64crossorderid,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE orig_order_id IS NULL
          AND co2.chain_id = 0
          AND co2.order_id = COALESCE(big_payload ->> 'RepresentativeOrderId'::text,
                                      big_payload #>> '{OriginatorOrder,RepresentativeOrderId}'::text[],
                                      big_payload #>> '{ContraOrder,RepresentativeOrderId}'::text[],
                                      '-1'::text)::bigint)                             AS representativeorderid,
       NULL::text                                                                      AS catupdate,
       CASE
           WHEN orig_order_id IS NOT NULL THEN '0'::text
           WHEN COALESCE(big_payload ->> 'HasRepresentedOrders'::text,
                         big_payload #>> '{OriginatorOrder,HasRepresentedOrders}'::text[],
                         big_payload #>> '{ContraOrder,HasRepresentedOrders}'::text[]) = 'Y'::text THEN '1'::text
           ELSE '0'::text
           END                                                                         AS hasrepresentedorder,
       payload #>> '{AlgoDetails,CBOESessionEligibility}'::text[]                      AS cboesessioneligibility,
       (payload #>> '{AlgoDetails,DashImpliedVolatility}'::text[])::numeric            AS impliedvolatility,
       ((payload ->> 'IsCabinet'::text))::character(1)::text                           AS cabinet,
       (payload ->> 'ParentCrossOrderId'::text)::bigint                                AS transaction64parentcrossorderid,
       CASE
           WHEN crossing_side IS NULL AND orig_order_id IS NULL THEN big_payload #>> '{OrderCallTime}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,OrderCallTime}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,OrderCallTime}'::text[]
           ELSE NULL::text
           END                                                                         AS calltime,
       CASE
           WHEN crossing_side IS NULL AND orig_order_id IS NULL
               THEN big_payload #>> '{CATDetails,CATElectronicOrderId}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,CATDetails,CATElectronicOrderId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATDetails,CATElectronicOrderId}'::text[]
           ELSE NULL::text
           END                                                                         AS electronicorderid,
       CASE
           WHEN crossing_side IS NULL AND orig_order_id IS NULL
               THEN big_payload #>> '{CATDetails,CATElectronicOrderTime}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>>
                                                 '{OriginatorOrder,CATDetails,CATElectronicOrderTime}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,CATDetails,CATElectronicOrderTime}'::text[]
           ELSE NULL::text
           END                                                                         AS electronicordertime,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{ClearingDetails,ClientInfo}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,ClearingDetails,ClientInfo}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ClearingDetails,ClientInfo}'::text[]
           ELSE NULL::text
           END                                                                         AS clientinfo,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{OrderEventTime}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,OrderEventTime}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,OrderEventTime}'::text[]
           ELSE NULL::text
           END                                                                         AS ordereventtime,
       order_id                                                                        AS _order_id,
       chain_id                                                                        AS _chain_id,
       cl.db_create_time                                                               AS _db_create_time,
--        staging.get_max_db_create_time(order_id, db_create_time::date, chain_id)        AS _last_mod_time,
       CASE
           WHEN is_q_time THEN staging.get_timestamp_from_date_ts(order_trade_date::int4, q_time)
           ELSE NULL::timestamp without time zone
           END                                                                         AS boxqooannouncedtime,
       CASE
           WHEN route_destination::text = 'BOX QOO'::text THEN payload #>> '{BoxQOOAnnouncedTime}'::text[]
           ELSE NULL::text
           END                                                                         AS boxqooannouncedtimev2,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{OrderNotes}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,OrderNotes}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,OrderNotes}'::text[]
           ELSE NULL::text
           END                                                                         AS ordernotes,
       payload ->> 'CboeEquityBroker'::text                                            AS cboeequitybroker,
       order_trade_date_id,
       (payload ->> 'AutoRouteRuleId'::text)::integer                                  AS autorouteruleid,
       payload ->> 'AutoRouteRuleName'::text                                           AS autorouterulename,
       (payload ->> 'IsAutoAccepted'::text)::bpchar                                    AS isautoaccepted,
       (payload ->> 'IsAutoRouted'::text)::bpchar                                      AS isautorouted,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{NoLinkedOrders}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,NoLinkedOrders}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,NoLinkedOrders}'::text[]
           ELSE NULL::text
           END                                                                         AS numberoflinkedorders,
       ((payload ->> 'IsTiedToCombo'::text))::character(1)                             AS istiedtocombo,
       ((payload ->> 'IsMerged'::text))::character(1)                                  AS ismerged,
       (SELECT co2.cl_ord_id
        FROM blaze7.client_order co2
        WHERE co2.order_id = ((payload ->> 'MergedOrderId'::text)::bigint)
          AND (payload ->> 'MergedOrderId'::text) IS NOT NULL
          AND co2.chain_id = 0
        LIMIT 1)                                                                       AS mergedorderid,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{ClearingDetails,SocGenSubAccount}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>>
                                                 '{OriginatorOrder,ClearingDetails,SocGenSubAccount}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,ClearingDetails,SocGenSubAccount}'::text[]
           ELSE NULL::text
           END                                                                         AS socgensubaccount,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{SocGenRoutingChainId}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,SocGenRoutingChainId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,SocGenRoutingChainId}'::text[]
           ELSE NULL::text
           END                                                                         AS sgchainid,
       CASE
           WHEN crossing_side IS NULL THEN payload #>> '{SocGenRoutingLinkedId}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,SocGenRoutingLinkedId}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,SocGenRoutingLinkedId}'::text[]
           ELSE NULL::text
           END                                                                         AS sglinkedid,
       payload ->> 'PrincipalEligibleFlag'::text                                       AS principaleligible,
       payload ->> 'IsCboeTiedHedge'::text                                             AS iscboetiedhedge,
       payload ->> 'FlexPriceType'::text                                               AS flexpricetype,
       payload ->> 'UserRoutingType'::text                                             AS userroutingtype,
       CASE
           WHEN crossing_side IS NULL THEN big_payload #>> '{HasLinkedOrders}'::text[]
           WHEN crossing_side = 'O'::bpchar THEN payload #>> '{OriginatorOrder,HasLinkedOrders}'::text[]
           WHEN crossing_side = 'C'::bpchar THEN payload #>> '{ContraOrder,HasLinkedOrders}'::text[]
           ELSE NULL::text
           END                                                                         AS haslinkedorders,
       payload #>> '{AlgoDetails,OptionsSessionEligibility}'::text[]                   AS optionssessioneligibility,
       payload #>> '{AlgoDetails,EquitiesSessionEligibility}'::text[]                  AS equitiessessioneligibility,
       rep.db_create_time                                                              as rep_db_create_time,
       org.db_create_time                                                              as org_db_create_time
FROM blaze7.client_order cl
         join lateral (select lst.payload          as big_payload,
                              CASE
                                  WHEN lst.route_destination::text = 'BOX QOO'::text AND
                                       (lst.payload ->> 'IsFlex'::text) = 'Y'::text THEN true
                                  ELSE false
                                  END              AS is_q_time,
                              CASE
                                  WHEN lst.route_destination::text = 'BOX QOO'::text AND
                                       (lst.payload ->> 'IsFlex'::text) = 'Y'::text THEN
                                      CASE
                                          WHEN lst.crossing_side = 'O'::bpchar
                                              THEN lst.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                                          WHEN lst.crossing_side = 'C'::bpchar
                                              THEN (SELECT co2.payload #>> '{OriginatorOrder,OrderNotes}'::text[]
                                                    FROM blaze7.client_order co2
                                                    WHERE co2.cross_order_id = lst.cross_order_id
                                                      AND co2.crossing_side = 'O'::bpchar
                                                    ORDER BY co2.chain_id DESC
                                                    LIMIT 1)
                                          ELSE NULL::text
                                          END
                                  ELSE NULL::text
                                  END              AS q_time,
                              lst.order_trade_date AS order_trade_date_id,
                              CASE
                                  WHEN lst.crossing_side IS NULL AND lst.orig_order_id IS NOT NULL AND
                                       lst.route_type = 'S'::bpchar
                                      THEN (SELECT co2.payload ->> 'OrderReceiveTime'::text
                                            FROM blaze7.client_order co2
                                            WHERE co2.cl_ord_id::text = lst.cl_ord_id::text
                                            ORDER BY co2.chain_id DESC
                                            LIMIT 1)
                                  WHEN lst.crossing_side IS NULL AND lst.orig_order_id IS NOT NULL
                                      THEN (SELECT co2.payload ->> 'OrderReceiveTime'::text
                                            FROM blaze7.client_order co2
                                            WHERE co2.cl_ord_id::text = lst.cl_ord_id::text
                                              AND co2.chain_id = 0
                                            LIMIT 1)
                                  WHEN lst.crossing_side IS NULL AND cl.orig_order_id IS NULL
                                      THEN lst.payload ->> 'OrderReceiveTime'::text
                                  WHEN lst.crossing_side = 'O'::bpchar
                                      THEN lst.payload #>> '{OriginatorOrder,OrderReceiveTime}'::text[]
                                  WHEN lst.crossing_side = 'C'::bpchar
                                      THEN lst.payload #>> '{ContraOrder,OrderReceiveTime}'::text[]
                                  ELSE NULL::text
                                  END              AS receivetime
                       from blaze7.client_order lst
                       where lst.order_id = cl.order_id
                       order by lst.chain_id desc
                       limit 1) lst on true
         join lateral ( select rep.db_create_time
                        from blaze7.order_report rep
                        where rep.order_id = cl.order_id
                          and case when cl.chain_id is null then true else rep.chain_id = cl.chain_id end
                        limit 1) rep on true

         left join lateral (select org.db_create_time
                            from blaze7.client_order org
                            where org.orig_order_id is not null
                              and org.orig_order_id = cl.order_id
                              and org.db_create_time >= cl.db_create_time
                            limit 1) org on true
WHERE true
  AND (cl.record_type = ANY (ARRAY ['0'::bpchar, '2'::bpchar]))
