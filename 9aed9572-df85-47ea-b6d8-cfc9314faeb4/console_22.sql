

ALTER TABLE IF EXISTS blaze7_settings.manual_ticket_entity_broker
    ALTER COLUMN broker TYPE varchar(255);

ALTER TABLE IF EXISTS blaze7_settings.manual_ticket_entity_custom_exchange
    ALTER COLUMN exchange_name TYPE varchar(255);

ALTER TABLE IF EXISTS blaze7_settings.manual_ticket_user_custom_exchange
    ALTER COLUMN exchange_name TYPE varchar(255);

ALTER TABLE IF EXISTS blaze7_settings.user_layout
    ALTER COLUMN layout_name TYPE varchar(255);

ALTER TABLE IF EXISTS blaze7_settings.user_window_preset
    ALTER COLUMN preset_name TYPE varchar(255);



ALTER TABLE IF EXISTS blaze7_settings.user_account_alias_backup
    ALTER COLUMN account_alias TYPE varchar(255),
    ALTER COLUMN account TYPE varchar(255),
    ALTER COLUMN mpid TYPE varchar(255),
    ALTER COLUMN ftid TYPE varchar(255),
    ALTER COLUMN locate_id TYPE varchar(255),
    ALTER COLUMN sub_acct_1 TYPE varchar(255),
    ALTER COLUMN sub_acct_2 TYPE varchar(255),
    ALTER COLUMN sub_acct_3 TYPE varchar(255),
    ALTER COLUMN soc_gen_salestrader TYPE varchar(255),
    ALTER COLUMN fdid TYPE varchar(255),
    ALTER COLUMN client_info TYPE varchar(255);

---
drop view if exists blaze7.tdash_oms_aliases;
ALTER TABLE IF EXISTS blaze7_settings.entity_actionable_id
    ALTER COLUMN actionable_id TYPE varchar(255);

ALTER TABLE IF EXISTS blaze7_settings.user_account_alias
    ALTER COLUMN account_alias TYPE varchar(255),
    ALTER COLUMN account TYPE varchar(255),
    ALTER COLUMN mpid TYPE varchar(255),
    ALTER COLUMN ftid TYPE varchar(255),
    ALTER COLUMN locate_id TYPE varchar(255),
    ALTER COLUMN sub_acct_1 TYPE varchar(255),
    ALTER COLUMN sub_acct_2 TYPE varchar(255),
    ALTER COLUMN sub_acct_3 TYPE varchar(255),
    ALTER COLUMN soc_gen_salestrader TYPE varchar(255),
    ALTER COLUMN fdid TYPE varchar(255),
    ALTER COLUMN client_info TYPE varchar(255);


CREATE OR REPLACE VIEW blaze7.tdash_oms_aliases
AS
SELECT ua.user_id,
       ua.alias_id,
       ua.account_alias,
       ua.manual_create_time,
       ua.migrate_time,
       ua.update_time,
       CASE
           WHEN ua.is_deleted THEN 1
           ELSE 0
           END                   AS is_deleted,
       ua.deleted_time,
       ua.reference_alias_id,
       ua.account,
       ua.option_range,
       ua.equity_range,
       ua.cmta,
       ua.give_up,
       ua.mpid,
       ua.ftid,
       ua.client_info,
       ua.customer_user_id,
       ua.dash_alias_id,
       ua.locate_id,
       ua.sub_acct_1,
       ua.sub_acct_2,
       ua.sub_acct_3,
       ua.commission,
       ua.soc_gen_salestrader,
       ua.soc_gen_capacity,
       gup.portfolio_name        AS soc_gen_portfolio,
       ua.broker_dealer,
       ua.fdid,
       ua.account_holder_type,
       ua.imid,
       ua.affiliate_flag,
       ua.is_representative,
       ea.actionable_id,
       ua.soc_gen_sub_acct::text AS soc_gen_sub_acct
FROM blaze7_settings.user_account_alias ua
         LEFT JOIN LATERAL ( SELECT ea_1.actionable_id
                             FROM blaze7_settings.entity_actionable_id ea_1
                             WHERE ea_1.id = COALESCE(ua.actionable_id_ref, '-1'::integer)
                             LIMIT 1) ea ON true
         LEFT JOIN LATERAL ( SELECT gu.portfolio_name
                             FROM blaze7_settings.soc_gen_user_portfolio gu
                             WHERE gu.portfolio_id = COALESCE(ua.soc_gen_portfolio_id, '-1'::integer)
                             LIMIT 1) gup ON true;