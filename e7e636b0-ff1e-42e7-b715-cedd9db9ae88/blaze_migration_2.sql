SELECT aw.order_id,
    aw.orderid AS order_id_guid,
    aw.ex_destination AS rep_ex_destination,
    aw.trade_record_time,
    aw.db_create_time,
    aw.date_id,
    aw.is_busted,
    'LPEDW'::text AS subsystem_id,
    COALESCE(aw.dashaliasid,
        CASE
            WHEN COALESCE(us.aors_user_name, us.user_login) = 'BBNTRST'::text THEN 'NTRSCBOE'::text
            ELSE COALESCE(us.aors_user_name, us.user_login)
        END) AS account_name,
    aw.cl_ord_id AS client_order_id,
    '???'::text AS instrument_id,
    aw.side,
    aw.openclose,
    '-1'::integer * public.base32_to_int8(aw.exec_id::text) AS exec_id,
    '0'::text AS exch_exec_id,
    aw.secondary_exch_exec_id,
        CASE
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['CBOE-CRD NO BK'::character varying::text, 'PAR'::character varying::text, 'CBOIE'::character varying::text]) THEN 'W'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['XPAR'::character varying::text, 'PLAK'::character varying::text, 'PARL'::character varying::text]) THEN 'LQPT'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['SOHO'::character varying::text, 'KNIGHT'::character varying::text, 'LSCI'::character varying::text, 'NOM'::character varying::text]) THEN 'ECUT'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['FOGS'::character varying::text, 'MID'::character varying::text]) THEN 'XCHI'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['C2'::character varying::text, 'CBOE2'::character varying::text]) THEN 'C2OX'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = 'SMARTR'::text THEN 'COWEN'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['ACT'::character varying::text, 'BOE'::character varying::text, 'OTC'::character varying::text, 'lp'::character varying::text, 'VOL'::character varying::text]) THEN 'BRKPT'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = 'XPSE'::text THEN 'N'::character varying
            WHEN COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)::text = 'TO'::text THEN '1'::character varying
            ELSE COALESCE(den.last_mkt, den1.last_mkt, lm.ex_destination, aw.ex_destination::character varying)
        END AS last_mkt,
    aw.lastshares AS last_qty,
    aw.last_px,
    COALESCE(lm.ex_destination, aw.ex_destination::character varying) AS ex_destination,
    '???'::text AS sub_strategy,
    COALESCE(
        CASE
            WHEN aw.expiration_date IS NOT NULL AND aw.strike_price IS NOT NULL THEN aw.opt_qty
            ELSE aw.eq_qty
        END, aw.eq_leaves_qty) AS street_order_qty,
    COALESCE(
        CASE
            WHEN aw.expiration_date IS NOT NULL AND aw.strike_price IS NOT NULL THEN aw.opt_qty
            ELSE aw.eq_qty
        END, aw.eq_leaves_qty) AS order_qty,
    aw.multileg_reporting_type,
    aw.exec_broker,
    aw.cmtafirm AS cmta,
    COALESCE(ltf.edwid::bigint, tif.id) AS tif,
        CASE
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[24::bigint, 17::bigint, 10::bigint, 1::bigint, 44::bigint]) THEN 0
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[26::bigint, 18::bigint, 3::bigint, 45::bigint, 12::bigint]) THEN 1
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[31::bigint, 8::bigint, 15::bigint, 46::bigint]) THEN 2
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[47::bigint, 28::bigint, 11::bigint, 19::bigint, 5::bigint]) THEN 3
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[48::bigint, 2::bigint, 13::bigint, 25::bigint, 20::bigint]) THEN 4
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[36::bigint, 37::bigint, 38::bigint, 49::bigint]) THEN 5
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[50::bigint, 14::bigint, 21::bigint, 33::bigint]) THEN 6
            WHEN COALESCE(ltf.edwid::bigint, tif.id) = ANY (ARRAY[32::bigint, 9::bigint, 16::bigint]) THEN 7
            ELSE NULL::integer
        END AS street_time_in_force,
        CASE
            WHEN lfw.edwid = ANY (ARRAY[1, 25, 32, 78]) THEN '0'::text
            WHEN lfw.edwid = ANY (ARRAY[33, 26, 79]) THEN '1'::text
            WHEN lfw.edwid = ANY (ARRAY[52, 103, 20, 97]) THEN '2'::text
            WHEN lfw.edwid = ANY (ARRAY[19, 30, 38, 96]) THEN '3'::text
            WHEN lfw.edwid = ANY (ARRAY[35, 28, 4, 81]) THEN '4'::text
            WHEN lfw.edwid = ANY (ARRAY[5, 29, 36, 82]) THEN '5'::text
            WHEN lfw.edwid = ANY (ARRAY[21, 6, 83]) THEN '7'::text
            WHEN lfw.edwid = ANY (ARRAY[31, 23, 41, 98]) THEN '8'::text
            WHEN lfw.edwid = ANY (ARRAY[9, 40, 50, 86]) THEN 'J'::text
            ELSE NULL::text
        END AS opt_customer_firm,
        CASE
            WHEN aw.crossing_side = 'C'::bpchar AND aw.cross_cl_ord_id IS NOT NULL THEN 'Y'::text
            WHEN aw.crossing_side <> 'C'::bpchar AND aw.orig_cl_ord_id IS NOT NULL THEN 'Y'::text
            ELSE 'N'::text
        END AS is_cross_order,
    aw.contra_broker,
    COALESCE(cmp.companycode, us.user_login::character varying) AS client_id,
    round(aw.order_price::bigint::numeric / 10000.0, 4) AS order_price,
    '???'::text AS order_process_time,
    '???'::text AS remarks,
    NULL::text AS street_client_order_id,
    'LPEDWCOMPID'::text AS fix_comp_id,
    aw.leaves_qty,
    aw.leg_ref_id,
    '???'::text AS load_batch_id,
        CASE
            WHEN aw.orig_order_id IS NOT NULL THEN 26
            WHEN aw.contra_order_id IS NOT NULL THEN 26
            WHEN aw.parent_order_id IS NOT NULL THEN 10
            WHEN aw.parent_order_id IS NULL AND aw.last_child_order <> '0'::text THEN 10
            WHEN aw.rep_comment ~~ '%OVR%'::text THEN 4
            ELSE 50
        END AS strategy_decision_reason_code,
    aw.is_parent,
    aw.symbol,
    COALESCE(aw.strike_price, 0::numeric) AS strike_price,
    aw.type_code,
        CASE aw.type_code
            WHEN 'P'::text THEN '0'::text
            WHEN 'C'::text THEN '1'::text
            ELSE NULL::text
        END AS put_or_call,
    EXTRACT(year FROM aw.expiration_date) AS maturuty_year,
    EXTRACT(month FROM aw.expiration_date) AS maturuty_month,
    EXTRACT(day FROM aw.expiration_date) AS maturuty_day,
    COALESCE(aw.securitytype, '1'::text) AS security_type,
    aw.child_orders,
    COALESCE(
        CASE
            WHEN aw.orderreportspecialtype = 'M'::text THEN lt.id
            ELSE NULL::bigint
        END, 0::bigint) AS handling,
    0 AS secondary_order_id2,
        CASE
            WHEN aw.expiration_date IS NOT NULL AND aw.strike_price IS NOT NULL THEN replace(COALESCE(((((regexp_replace(COALESCE(aw.rootcode, ''::text), '\.|-'::text, ''::text, 'g'::text) || ' '::text) || to_char(aw.expiration_date::timestamp with time zone, 'DDMonYY'::text)) || ' '::text) || staging.trailing_dot(aw.strike_price)) || "left"(aw.typecode, 8),
            CASE
                WHEN aw.ord_contractdesc !~~ (aw.basecode || ' %'::text) THEN (aw.basecode || ' '::text) || replace(aw.ord_contractdesc, aw.basecode, ''::text)
                WHEN aw.legcount::integer = 1 AND aw.typecode = 'S'::text THEN aw.ord_contractdesc || ' Stock'::text
                WHEN aw.ord_contractdesc !~~ ' %'::text THEN aw.ord_contractdesc || ' '::text
                ELSE aw.ord_contractdesc
            END), '/'::text, ''::text)
            ELSE regexp_replace(COALESCE(aw.rootcode, ''::text), '\.|-'::text, ''::text, 'g'::text)
        END AS display_instrument_id,
        CASE
            WHEN aw.expiration_date IS NOT NULL AND aw.strike_price IS NOT NULL THEN 'O'::text
            ELSE 'E'::text
        END AS instrument_type_id,
    regexp_replace(COALESCE(aw.basecode, ''::text), '\.|-'::text, ''::text, 'g'::text) AS activ_symbol,
    '???'::text AS mapping_logic,
    '???'::text AS commision_rate_unit,
        CASE
            WHEN aw.orderreportspecialtype = 'M'::text THEN 0
            ELSE 1
        END AS is_sor_routed,
        CASE
            WHEN lag(cmp.companyname, 1) OVER (PARTITION BY aw.exchangetransactionid ORDER BY aw.generation)::text <> cmp.companyname::text AND lag(aw.orderid, 1) OVER (PARTITION BY aw.exchangetransactionid ORDER BY aw.generation)::text = aw.parentorderid::text THEN 1
            ELSE 0
        END AS is_company_name_changed,
    cmp.companyname AS company_name,
    aw.generation,
    max(aw.generation) OVER (PARTITION BY aw.exchangetransactionid) AS mx_gen,
    aw.parent_order_id,
        CASE
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['CBOE-CRD NO BK'::character varying::text, 'PAR'::character varying::text, 'CBOIE'::character varying::text]) THEN 'XCBO'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['XPAR'::character varying::text, 'PLAK'::character varying::text, 'PARL'::character varying::text]) THEN 'LQPT'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['SOHO'::character varying::text, 'KNIGHT'::character varying::text, 'LSCI'::character varying::text, 'NOM'::character varying::text]) THEN 'ECUT'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['FOGS'::character varying::text, 'MID'::character varying::text]) THEN 'XCHI'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['C2'::character varying::text, 'CBOE2'::character varying::text]) THEN 'C2OX'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = 'SMARTR'::text THEN 'COWEN'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = ANY (ARRAY['ACT'::character varying::text, 'BOE'::character varying::text, 'OTC'::character varying::text, 'lp'::character varying::text, 'VOL'::character varying::text]) THEN 'BRKPT'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = 'XPSE'::text THEN 'ARCO'::character varying
            WHEN COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)::text = 'TO'::text THEN 'AMXO'::character varying
            ELSE COALESCE(den1.mic_code, lm.ex_destination, aw.ex_destination::character varying)
        END AS mic_code,
    aw.option_range,
    aw.client_entity_id,
    aw.status,
    COALESCE(NULLIF(aw.liquidityindicator, ''::text), 'R'::text) AS trade_liquidity_indicator,
    aw.order_create_time::timestamp without time zone AS order_create_time,
    aw.blaze_account_alias,
    CASE WHEN coalesce(los.EDWID, bos.ID,0) = 151 and aw.orderreportspecialtype = 'M' then 156 ELSE coalesce(los.EDWID, bos.ID,0) END as edw_status
   FROM trash.so_away_trade aw
     LEFT JOIN LATERAL ( SELECT lm_1.id,
            lm_1.mic_code,
            lm_1.security_type,
            lm_1.venue_exchange,
            lm_1.business_name,
            lm_1.ex_destination,
            lm_1.last_mkt
           FROM staging.d_blaze_exchange_codes lm_1
          WHERE COALESCE(lm_1.last_mkt, lm_1.ex_destination)::text = aw.ex_destination AND
                CASE
                    WHEN aw.securitytype = '1'::text THEN 'O'::text
                    WHEN aw.securitytype IS NULL THEN 'O'::text
                    WHEN aw.securitytype = '2'::text THEN 'E'::text
                    ELSE aw.securitytype
                END = lm_1.security_type::text
         LIMIT 1) lm ON true
     LEFT JOIN staging.t_users us ON us.user_id = aw.userid::integer
     LEFT JOIN LATERAL ( SELECT den_1.last_mkt
           FROM billing.dash_exchange_names den_1
          WHERE den_1.mic_code::text = COALESCE(lm.ex_destination, aw.ex_destination::character varying)::text AND den_1.real_exchange_id::text = den_1.exchange_id::text AND den_1.mic_code::text <> ''::text AND den_1.is_active
         LIMIT 1) den ON true
     LEFT JOIN LATERAL ( SELECT den1_1.last_mkt,
            den1_1.mic_code
           FROM billing.dash_exchange_names den1_1
          WHERE den1_1.exchange_id::text = COALESCE(lm.ex_destination, aw.ex_destination::character varying)::text AND den1_1.real_exchange_id::text = den1_1.exchange_id::text AND den1_1.mic_code::text <> ''::text AND den1_1.is_active
         LIMIT 1) den1 ON true
     LEFT JOIN staging.d_time_in_force tif ON tif.enum = aw.co_time_in_force
     LEFT JOIN billing.time_in_force ltf ON tif.id = ltf.code AND ltf.systemid = 8
     LEFT JOIN billing.lforwhom lfw ON lfw.shortdesc::text = aw.option_range AND lfw.systemid = 4
     LEFT JOIN billing.tcompany cmp ON us.company_id = cmp.companyid AND us.system_id = cmp.systemid AND cmp.edwactive = 1::bit(1)
     LEFT JOIN staging.d_liquidity_type lt ON aw.rep_liquidity_type = lt.enum::text
   left join staging.d_blaze_order_status bos on aw.status = bos.enum and bos.order_or_report_status = 2
   left join staging.l_order_status los on bos.id = los.statuscode and los.systemid = 8
   left join staging.d_order_class oc on oc.enum = aw.
  WHERE true AND (aw.status = ANY (ARRAY['1'::bpchar, '2'::bpchar]))
and aw.cl_ord_id = '1_153241014';