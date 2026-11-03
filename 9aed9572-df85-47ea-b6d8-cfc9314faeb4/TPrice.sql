create view blaze7.so_tprice as
SELECT rep.exec_type                                                               AS status,
       mdr.exec_id                                                                 AS reportid,
       rep.cl_ord_id                                                               AS orderid,
       COALESCE(((SELECT leg.payload ->> 'LegSeqNumber'::text
                  FROM blaze7.client_order_leg leg
                  WHERE leg.order_id = rep.order_id
                    AND leg.chain_id = rep.chain_id
                    AND leg.leg_ref_id::text = rep.leg_ref_id::text))::integer, 1) AS legnumber,
       CASE
           WHEN rep.leg_ref_id IS NULL THEN rep.co_payload ->> 'DashSecurityId'::text
           ELSE (SELECT leg.payload ->> 'DashSecurityId'::text
                 FROM blaze7.client_order_leg leg
                 WHERE leg.order_id = rep.order_id
                   AND leg.chain_id = rep.chain_id
                   AND leg.leg_ref_id::text = rep.leg_ref_id::text)
           END                                                                     AS dashsecurityid,
       NULL::text                                                                  AS lastreportid,
       rep.cl_ord_id                                                               AS systemorderid,
       NULL::text                                                                  AS updatesequence,
       CASE
           WHEN rep.crossing_side IS NULL THEN COALESCE(rep.co_payload #>> '{ClearingDetails,CustomerUserId}'::text[],
                                                        rep.co_payload ->> 'InitiatorUserId'::text)
           WHEN rep.crossing_side = 'O'::bpchar THEN COALESCE(
                   rep.co_payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[],
                   rep.co_payload ->> 'InitiatorUserId'::text)
           WHEN rep.crossing_side = 'C'::bpchar THEN COALESCE(
                   rep.co_payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[],
                   rep.co_payload ->> 'InitiatorUserId'::text)
           ELSE NULL::text
           END                                                                     AS userid,
       NULL::text                                                                  AS companyid,
       rep.route_type                                                              AS exchangeconnectionid,
       CASE
           WHEN rep.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar, '!'::bpchar]) THEN rep.rep_payload ->> 'LastMkt'::text
           ELSE NULL::text
           END                                                                     AS exchangename,
       rep.co_payload ->> 'ClassicRouteDestinationCode'::text                      AS destination,
       NULL::text                                                                  AS routingtableid,
       NULL::text                                                                  AS systemid,
       NULL::text                                                                  AS orderidint,
       NULL::text                                                                  AS reportidint,
       CASE
           WHEN rep.crossing_side IS NULL THEN rep.co_payload ->> 'Generation'::text
           WHEN rep.crossing_side = 'O'::bpchar THEN rep.co_payload #>> '{OriginatorOrder,Generation}'::text[]
           WHEN rep.crossing_side = 'C'::bpchar THEN rep.co_payload #>> '{ContraOrder,Generation}'::text[]
           ELSE NULL::text
           END                                                                     AS generation,
       CASE
           WHEN rep.act_instrument_type = 'E'::text THEN mdr.payload #>> '{NBBOSnapshot,BidPrice}'::text[]
           ELSE mdr.payload #>> '{UnderlyingNBBOSnapshot,BidPrice}'::text[]
           END                                                                     AS ulbid,
       CASE
           WHEN rep.act_instrument_type = 'E'::text THEN mdr.payload #>> '{NBBOSnapshot,AskPrice}'::text[]
           ELSE mdr.payload #>> '{UnderlyingNBBOSnapshot,AskPrice}'::text[]
           END                                                                     AS ulask,
       CASE
           WHEN rep.act_instrument_type = 'E'::text THEN mdr.payload #>> '{NBBOSnapshot,BidSize}'::text[]
           ELSE mdr.payload #>> '{UnderlyingNBBOSnapshot,BidSize}'::text[]
           END                                                                     AS ulbidsz,
       CASE
           WHEN rep.act_instrument_type = 'E'::text THEN mdr.payload #>> '{NBBOSnapshot,AskSize}'::text[]
           ELSE mdr.payload #>> '{UnderlyingNBBOSnapshot,AskSize}'::text[]
           END                                                                     AS ulasksz,
       mdr.payload #>> '{NBBOSnapshot,BidPrice}'::text[]                           AS nbbobid,
       mdr.payload #>> '{NBBOSnapshot,AskPrice}'::text[]                           AS nbboask,
       mdr.payload #>> '{NBBOSnapshot,BidSize}'::text[]                            AS nbbobidsz,
       mdr.payload #>> '{NBBOSnapshot,AskSize}'::text[]                            AS nbboasksz,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,AMXO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bida,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,AMXO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS aska,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,AMXO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidsza,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,AMXO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS asksza,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBOX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidb,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBOX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askb,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBOX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszb,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBOX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszb,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XCBO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidc,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XCBO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askc,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XCBO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszc,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XCBO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszc,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XISX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidi,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XISX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS aski,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XISX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszi,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XISX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszi,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,ARCO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidp,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,ARCO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askp,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,ARCO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszp,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,ARCO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszp,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XPHO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidx,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XPHO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askx,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XPHO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszx,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XPHO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszx,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XNDQ,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidq,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XNDQ,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askq,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XNDQ,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszq,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XNDQ,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszq,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,BATO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidz,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,BATO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askz,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,BATO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszz,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,BATO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszz,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,C2OX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidw,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,C2OX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askw,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,C2OX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszw,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,C2OX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszw,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBXO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidt,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBXO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askt,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBXO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszt,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XBXO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszt,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XMIO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidm,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XMIO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askm,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XMIO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszm,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,XMIO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszm,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,GMNI,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidh,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,GMNI,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askh,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,GMNI,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszh,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,GMNI,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszh,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MCRY,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidj,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MCRY,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askj,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MCRY,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszj,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MCRY,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszj,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EDGO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bide,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EDGO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS aske,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EDGO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidsze,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EDGO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS asksze,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MPRL,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidr,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MPRL,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askr,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MPRL,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszr,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MPRL,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszr,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EMLD,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidd,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EMLD,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askd,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EMLD,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszd,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,EMLD,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszd,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXOP,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidu,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXOP,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS asku,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXOP,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszu,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXOP,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszu,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,SPHR,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bids,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,SPHR,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS asks,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,SPHR,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszs,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,SPHR,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszs,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXTO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidg,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXTO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askg,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXTO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszg,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,MXTO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszg,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,IEXO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidv,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,IEXO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askv,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,IEXO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszv,
       CASE
           WHEN rep.act_instrument_type <> 'E'::text THEN mdr.payload #>> '{BBOSnapshot,IEXO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszv,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XASE,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidea,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XASE,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askea,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XASE,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszea,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XASE,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszea,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,ARCX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidep,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,ARCX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askep,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,ARCX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszep,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,ARCX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszep,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidez,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askez,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszez,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszez,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATY,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidey,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATY,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askey,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATY,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszey,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,BATY,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszey,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGA,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidej,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGA,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askej,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGA,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszej,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszej,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidek,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askek,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszek,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,EDGX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszek,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNAS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bideq,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNAS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askeq,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNAS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszeq,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNAS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszeq,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XBOS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bideb,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XBOS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askeb,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XBOS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszeb,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XBOS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszeb,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNYS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS biden,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNYS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS asken,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNYS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszen,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XNYS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszen,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XPSX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidex,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XPSX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askex,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XPSX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszex,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XPSX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszex,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,IEXG,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidei,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,IEXG,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askei,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,IEXG,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszei,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,IEXG,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszei,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCIS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidec,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCIS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askec,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCIS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszec,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCIS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszec,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCHI,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidem,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCHI,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askem,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCHI,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszem,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XCHI,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszem,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,OTCM,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bideu,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,OTCM,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askeu,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,OTCM,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszeu,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,OTCM,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszeu,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XADF,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bided,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XADF,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS asked,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XADF,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszed,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,XADF,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszed,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,TXSE,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bidef,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,TXSE,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askef,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,TXSE,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszef,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,TXSE,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszef,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,24EQ,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS bideg,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,24EQ,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                     AS askeg,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,24EQ,BidSize}'::text[]
           ELSE NULL::text
           END                                                                     AS bidszeg,
       CASE
           WHEN rep.act_instrument_type <> 'O'::text THEN mdr.payload #>> '{BBOSnapshot,24EQ,AskSize}'::text[]
           ELSE NULL::text
           END                                                                     AS askszeg,
       rep.order_id                                                                AS _order_id,
       rep.chain_id                                                                AS _chain_id,
       mdr.db_create_time                                                          AS _db_create_time
FROM blaze7.market_data_report mdr
         join lateral (
    SELECT rep.leg_ref_id,
           rep.payload AS rep_payload,
           rep.exec_type,
           co.order_id,
           co.chain_id,
           co.payload  AS co_payload,
           co.cl_ord_id,
           co.crossing_side,
           co.route_type,
           CASE
               WHEN rep.leg_ref_id IS NULL THEN co.instrument_type::text
               ELSE (SELECT leg.payload ->> 'LegInstrumentType'::text
                     FROM blaze7.client_order_leg leg
                     WHERE leg.order_id = co.order_id
                       AND leg.chain_id = co.chain_id
                       AND leg.leg_ref_id::text = rep.leg_ref_id::text)
               END     AS act_instrument_type
    FROM blaze7.order_report rep
             join blaze7.client_order co
                  on co.order_id = rep.order_id
                      AND co.chain_id = rep.chain_id
                      AND co.order_class <> 'O'::bpchar
    WHERE rep.exec_id = mdr.exec_id

    union all
    SELECT rep.leg_ref_id,
           rep.payload AS rep_payload,
           rep.exec_type,
           co.order_id,
           co.chain_id,
           co.payload  AS co_payload,
           co.cl_ord_id,
           co.crossing_side,
           co.route_type,
           CASE
               WHEN rep.leg_ref_id IS NULL THEN co.instrument_type::text
               ELSE (SELECT leg.payload ->> 'LegInstrumentType'::text
                     FROM blaze7.client_order_leg leg
                     WHERE leg.order_id = co.order_id
                       AND leg.chain_id = co.chain_id
                       AND leg.leg_ref_id::text = rep.leg_ref_id::text)
               END     AS act_instrument_type
    FROM blaze7.order_report rep
             join blaze7.client_order co
                  on co.order_id = rep.order_id
                      AND co.chain_id = rep.chain_id
                      AND co.order_class = 'O'::bpchar
    WHERE rep.payload ->> 'ExecRefId' = mdr.exec_id::text

    ) rep on true



WHERE (mdr.exec_id > :in_min_exec_id
      AND mdr.exec_id < :max_exec_id
    )
      or
      (mdr.exec_id <= :in_min_exec_id
      AND mdr.exec_id < :max_exec_id
      AND mdr.db_create_time >
          (:in_max_time::timestamp AT TIME ZONE 'US/Central')
          - INTERVAL '1 hour'
      AND date_trunc('milliseconds', mdr.db_create_time::timestamp) >
          (:in_max_time::timestamp AT TIME ZONE 'US/Central'))