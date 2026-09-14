USE Blaze7_DEV
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE dbo.TDashOmsAliases;

    INSERT INTO dbo.TDashOmsAliases ( [user_id]
                                    , [alias_id]
                                    , [account_alias]
                                    , [manual_create_time]
                                    , [migrate_time]
                                    , [update_time]
                                    , [is_deleted]
                                    , [deleted_time]
                                    , [reference_alias_id]
                                    , [account]
                                    , [option_range]
                                    , [equity_range]
                                    , [cmta]
                                    , [give_up]
                                    , [mpid]
                                    , [ftid]
                                    , [customer_user_id]
                                    , [dash_alias_id]
                                    , [locate_id]
                                    , [sub_acct_1]
                                    , [sub_acct_2]
                                    , [sub_acct_3]
                                    , [commission]
                                    , [soc_gen_salestrader]
                                    , [soc_gen_capacity]
                                    , [soc_gen_portfolio]
                                    , [broker_dealer]
                                    , [fdid]
                                    , [account_holder_type]
                                    , [imid]
                                    , [affiliate_flag]
                                    , [is_representative]
                                    , [actionable_id]
                                    , [date_id]
                                    , [pg_entity]
                                    , [client_info]
                                    , [soc_gen_sub_acct])
    SELECT [user_id]
         , [alias_id]
         , [account_alias]
         , [manual_create_time]
         , [migrate_time]
         , [update_time]
         , [is_deleted]
         , [deleted_time]
         , [reference_alias_id]
         , [account]
         , [option_range]
         , [equity_range]
         , [cmta]
         , [give_up]
         , [mpid]
         , [ftid]
         , [customer_user_id]
         , [dash_alias_id]
         , [locate_id]
         , [sub_acct_1]
         , [sub_acct_2]
         , [sub_acct_3]
         , [commission]
         , [soc_gen_salestrader]
         , [soc_gen_capacity]
         , [soc_gen_portfolio]
         , [broker_dealer]
         , [fdid]
         , [account_holder_type]
         , [imid]
         , [affiliate_flag]
         , [is_representative]
         , [actionable_id]
         , [date_id]
         , [pg_entity]
         , [client_info]
         , [soc_gen_sub_acct]
    FROM dbo.TDashOmsAliases_STAGE;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;