-- drop view select * from blaze7.tprices_edw;

CREATE OR REPLACE VIEW blaze7.tprices_edw
AS
SELECT v.exec_type                                                               AS status,
       v.exec_id                                                                 AS reportid,
       v.cl_ord_id                                                               AS orderid,
       COALESCE(((SELECT leg.payload ->> 'LegSeqNumber'::text
                  FROM blaze7.client_order_leg leg
                  WHERE leg.order_id = v.order_id
                    AND leg.chain_id = v.chain_id
                    AND leg.leg_ref_id::text = v.leg_ref_id::text))::integer, 1) AS legnumber,
       CASE
           WHEN v.leg_ref_id IS NULL THEN v.co_payload ->> 'DashSecurityId'::text
           ELSE (SELECT leg.payload ->> 'DashSecurityId'::text
                 FROM blaze7.client_order_leg leg
                 WHERE leg.order_id = v.order_id
                   AND leg.chain_id = v.chain_id
                   AND leg.leg_ref_id::text = v.leg_ref_id::text)
           END                                                                   AS dashsecurityid,
       NULL::text                                                                AS lastreportid,
       v.cl_ord_id                                                               AS systemorderid,
       NULL::text                                                                AS updatesequence,
       CASE
           WHEN v.crossing_side IS NULL THEN COALESCE(v.co_payload #>> '{ClearingDetails,CustomerUserId}'::text[],
                                                      v.co_payload ->> 'InitiatorUserId'::text)
           WHEN v.crossing_side = 'O'::bpchar THEN COALESCE(
                   v.co_payload #>> '{OriginatorOrder,ClearingDetails,CustomerUserId}'::text[],
                   v.co_payload ->> 'InitiatorUserId'::text)
           WHEN v.crossing_side = 'C'::bpchar THEN COALESCE(
                   v.co_payload #>> '{ContraOrder,ClearingDetails,CustomerUserId}'::text[],
                   v.co_payload ->> 'InitiatorUserId'::text)
           ELSE NULL::text
           END                                                                   AS userid,
       NULL::text                                                                AS companyid,
       v.route_type                                                              AS exchangeconnectionid,
       CASE
           WHEN v.exec_type = ANY (ARRAY ['1'::bpchar, '2'::bpchar]) THEN v.rep_payload ->> 'LastMkt'::text
           ELSE NULL::text
           END                                                                   AS exchangename,
       v.co_payload ->> 'ClassicRouteDestinationCode'::text                      AS destination,
       NULL::text                                                                AS routingtableid,
       NULL::text                                                                AS systemid,
       NULL::text                                                                AS orderidint,
       NULL::text                                                                AS reportidint,
       CASE
           WHEN v.crossing_side IS NULL THEN v.co_payload ->> 'Generation'::text
           WHEN v.crossing_side = 'O'::bpchar THEN v.co_payload #>> '{OriginatorOrder,Generation}'::text[]
           WHEN v.crossing_side = 'C'::bpchar THEN v.co_payload #>> '{ContraOrder,Generation}'::text[]
           ELSE NULL::text
           END                                                                   AS generation,
       CASE
           WHEN v.act_instrument_type = 'E'::text THEN v.mdr_payload #>> '{NBBOSnapshot,BidPrice}'::text[]
           ELSE v.mdr_payload #>> '{UnderlyingNBBOSnapshot,BidPrice}'::text[]
           END                                                                   AS ulbid,
       CASE
           WHEN v.act_instrument_type = 'E'::text THEN v.mdr_payload #>> '{NBBOSnapshot,AskPrice}'::text[]
           ELSE v.mdr_payload #>> '{UnderlyingNBBOSnapshot,AskPrice}'::text[]
           END                                                                   AS ulask,
       CASE
           WHEN v.act_instrument_type = 'E'::text THEN v.mdr_payload #>> '{NBBOSnapshot,BidSize}'::text[]
           ELSE v.mdr_payload #>> '{UnderlyingNBBOSnapshot,BidSize}'::text[]
           END                                                                   AS ulbidsz,
       CASE
           WHEN v.act_instrument_type = 'E'::text THEN v.mdr_payload #>> '{NBBOSnapshot,AskSize}'::text[]
           ELSE v.mdr_payload #>> '{UnderlyingNBBOSnapshot,AskSize}'::text[]
           END                                                                   AS ulasksz,
       v.mdr_payload #>> '{NBBOSnapshot,BidPrice}'::text[]                       AS nbbobid,
       v.mdr_payload #>> '{NBBOSnapshot,AskPrice}'::text[]                       AS nbboask,
       v.mdr_payload #>> '{NBBOSnapshot,BidSize}'::text[]                        AS nbbobidsz,
       v.mdr_payload #>> '{NBBOSnapshot,AskSize}'::text[]                        AS nbboasksz,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,AMXO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bida,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,AMXO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS aska,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,AMXO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidsza,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,AMXO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS asksza,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidb,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askb,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszb,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszb,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCBO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidc,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCBO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askc,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCBO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszc,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCBO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszc,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XISX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidi,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XISX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS aski,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XISX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszi,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XISX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszi,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidp,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askp,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszp,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszp,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPHO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidx,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPHO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askx,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPHO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszx,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPHO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszx,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNDQ,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidq,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNDQ,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askq,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNDQ,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszq,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNDQ,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszq,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidz,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askz,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszz,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszz,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,C2OX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidw,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,C2OX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askw,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,C2OX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszw,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,C2OX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszw,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBXO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidt,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBXO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askt,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBXO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszt,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBXO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszt,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XMIO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidm,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XMIO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askm,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XMIO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszm,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,XMIO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszm,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,GMNI,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidh,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,GMNI,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askh,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,GMNI,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszh,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,GMNI,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszh,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MCRY,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidj,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MCRY,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askj,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MCRY,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszj,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MCRY,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszj,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bide,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS aske,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidsze,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS asksze,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MPRL,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidr,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MPRL,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askr,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MPRL,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszr,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MPRL,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszr,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EMLD,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidd,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EMLD,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askd,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EMLD,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszd,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,EMLD,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszd,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXOP,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidu,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXOP,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS asku,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXOP,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszu,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXOP,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszu,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,SPHR,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bids,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,SPHR,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS asks,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,SPHR,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszs,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,SPHR,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszs,
       -- MXTO
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXTO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidg,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXTO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askg,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXTO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszg,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,MXTO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszg,
       -- IEXO
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXO,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidv,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXO,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askv,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXO,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszv,
       CASE
           WHEN v.act_instrument_type <> 'E'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXO,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszv,
       -- OPTIONS
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XASE,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidea,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XASE,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askea,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XASE,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszea,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XASE,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszea,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidep,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askep,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszep,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,ARCX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszep,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidez,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askez,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszez,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszez,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATY,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidey,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATY,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askey,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATY,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszey,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,BATY,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszey,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGA,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidej,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGA,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askej,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGA,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszej,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszej,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidek,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askek,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszek,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,EDGX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszek,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNAS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bideq,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNAS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askeq,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNAS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszeq,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNAS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszeq,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bideb,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askeb,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszeb,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XBOS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszeb,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNYS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS biden,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNYS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS asken,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNYS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszen,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XNYS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszen,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPSX,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidex,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPSX,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askex,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPSX,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszex,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XPSX,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszex,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXG,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidei,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXG,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askei,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXG,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszei,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,IEXG,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszei,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCIS,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidec,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCIS,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askec,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCIS,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszec,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCIS,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszec,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCHI,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidem,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCHI,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askem,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCHI,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszem,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XCHI,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszem,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,OTCM,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bideu,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,OTCM,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askeu,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,OTCM,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszeu,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,OTCM,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszeu,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XADF,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bided,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XADF,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS asked,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XADF,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszed,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,XADF,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszed,
-- TXSE
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,TXSE,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bidef,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,TXSE,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askef,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,TXSE,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszef,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,TXSE,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszef,
       -- 24EQ
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,24EQ,BidPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS bideg,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,24EQ,AskPrice}'::text[]
           ELSE NULL::text
           END                                                                   AS askeg,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,24EQ,BidSize}'::text[]
           ELSE NULL::text
           END                                                                   AS bidszeg,
       CASE
           WHEN v.act_instrument_type <> 'O'::text THEN v.mdr_payload #>> '{BBOSnapshot,24EQ,AskSize}'::text[]
           ELSE NULL::text
           END                                                                   AS askszeg,
       --
       v.order_id                                                                AS _order_id,
       v.chain_id                                                                AS _chain_id,
       v.db_create_time                                                          AS _db_create_time
FROM (SELECT rep.exec_id,
             mdr.payload AS mdr_payload,
             rep.leg_ref_id,
             rep.payload AS rep_payload,
             rep.exec_type,
             co.order_id,
             co.chain_id,
             co.payload  AS co_payload,
             mdr.db_create_time,
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
      FROM blaze7.market_data_report mdr
               JOIN blaze7.order_report rep ON rep.exec_id::text = mdr.exec_id::text
               JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
      WHERE co.order_class <> 'O'::bpchar
      UNION ALL
      SELECT rep.exec_id,
             mdr.payload AS mdr_payload,
             rep.leg_ref_id,
             rep.payload AS rep_payload,
             rep.exec_type,
             co.order_id,
             co.chain_id,
             co.payload  AS co_payload,
             mdr.db_create_time,
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
      FROM blaze7.market_data_report mdr
               JOIN blaze7.order_report rep ON (rep.payload ->> 'ExecRefId'::text) = mdr.exec_id::text
               JOIN blaze7.client_order co ON co.order_id = rep.order_id AND co.chain_id = rep.chain_id
      WHERE co.order_class = 'O'::bpchar) v;