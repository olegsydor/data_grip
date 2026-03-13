-- dash360.v_account_info_details source

CREATE OR REPLACE VIEW dash360.v_account_info_details
AS
SELECT da.account_id,
       da.account_name,
       da.account_class_id,
       da.trading_firm_id,
       da.is_auto_allocate,
       da.is_broker_dealer,
       da.broker_dealer_mpid,
       da.account_demo_mnemonic,
       da.use_new_model,
       da.account_algo_alias,
       da.account_holder_type,
       da.cat_fdid,
       da.cat_report_on_behalf_of,
       da.cat_suppress,
       da.eq_order_capacity,
       da.opt_customer_or_firm,
       da.eq_report_to_mpid,
       da.opt_report_to_mpid,
       cl_acc.eq_clearing_account_number,
       cl_acc.eq_clearing_account_type,
       cl_acc.opt_clearing_account_number,
       cl_acc.opt_clearing_account_type,
       cl_acc.is_visible_for_manual_allocation,
       i.instrument_types,
       CASE
           WHEN da.opt_report_to_mpid::text = 'MLCB'::text THEN 'Y'::text
           WHEN da.eq_report_to_mpid::text = 'MLCB'::text AND
                (COALESCE(cl_acc.eq_clearing_account_number, 'null alternative'::text) <> ALL
                 (ARRAY ['3Q800806'::text, '3Q800797'::text, '3Q800809'::text])) THEN 'Y'::text
           WHEN (EXISTS (SELECT NULL::text
                         FROM d_sg_account sg
                         WHERE sg.account_id = da.account_id
                           AND sg.is_active
--                            AND sg.sg_parent_account_id IS NULL
                              and sg.sg_is_pta_eligible = 'Y'
                         )) THEN 'Y'::text
           ELSE 'N'::text
           END AS is_pta_configured
FROM d_account da
         LEFT JOIN (SELECT account2instrument_type.account_id,
                           array_agg(account2instrument_type.instrument_type_id) AS instrument_types
                    FROM account2instrument_type
                    WHERE account2instrument_type.is_active
                    GROUP BY account2instrument_type.account_id) i ON i.account_id = da.account_id
         LEFT JOIN (SELECT max(
                                   CASE d_clearing_account.market_type
                                       WHEN 'E'::bpchar THEN d_clearing_account.clearing_account_number
                                       ELSE NULL::character varying
                                       END::text) AS eq_clearing_account_number,
                           max(
                                   CASE d_clearing_account.market_type
                                       WHEN 'E'::bpchar THEN d_clearing_account.clearing_account_type
                                       ELSE NULL::bpchar
                                       END)       AS eq_clearing_account_type,
                           d_clearing_account.is_visible_for_manual_allocation,
                           max(
                                   CASE d_clearing_account.market_type
                                       WHEN 'O'::bpchar THEN d_clearing_account.clearing_account_number
                                       ELSE NULL::character varying
                                       END::text) AS opt_clearing_account_number,
                           max(
                                   CASE d_clearing_account.market_type
                                       WHEN 'O'::bpchar THEN d_clearing_account.clearing_account_type
                                       ELSE NULL::bpchar
                                       END)       AS opt_clearing_account_type,
                           d_clearing_account.account_id
                    FROM d_clearing_account
                    WHERE d_clearing_account.is_default = 'Y'::bpchar
                      AND d_clearing_account.is_active
                    GROUP BY d_clearing_account.account_id, d_clearing_account.is_visible_for_manual_allocation) cl_acc
                   ON cl_acc.account_id = da.account_id
WHERE da.is_active;
