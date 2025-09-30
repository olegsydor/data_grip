-- dash360.report_surveillance_socgen_acct_mgr_capacity_change(in_start_date_id, in_end_date_id, in_trading_firm_ids, in_account_ids)


create or replace function dash360.report_surveillance_socgen_acct_mgr_capacity_change(in_start_date_id int4,
                                                                            in_end_date_id int4,
                                                                            in_trading_firm_ids character varying(9)[] default '{"socgenpsc","socgeneqd"}',
                                                                            in_account_ids int4[] default '{}'::int4[])
    returns table
            (
                "Trading Firm"              character varying(60),
                "Account"                   character varying(30),
                "Sub Account"               character varying(10),
                "Original Account Capacity" character varying(255),
                "Modified Account Capacity" character varying(255),
                "Modification Date"         text
            )
    language plpgsql
AS
$function$
-- 20250929 SO https://dashfinancial.atlassian.net/browse/DEVREQ-6730
declare
    l_load_id int;
    l_row_cnt int;
    l_step_id int;
    l_start_date date := in_start_date_id::text::date;
    l_end_date date := in_end_date_id::text::date;

begin

    select nextval('public.load_timing_seq') into l_load_id;
    l_step_id := 1;

    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_acct_mgr_capacity_change for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' STARTED===',
                           0, 'O')
    into l_step_id;

    return query
        with cte_sa1 as (select sa.account_id, sa.opt_customer_or_firm, cf.customer_or_firm_name
                         from dwh.d_sg_account sa
                                  join dwh.d_account a on (a.account_id = sa.account_id)
                             --join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                                  left join dwh.d_customer_or_firm cf
                                            on (cf.customer_or_firm_id = sa.opt_customer_or_firm)
                         where sa.date_start::date between l_start_date and l_end_date
                           and case
                                   when coalesce(in_trading_firm_ids, '{}'::character varying(9)[]) =
                                        '{}'::character varying(9)[] then true
                                   else a.trading_firm_id = any (in_trading_firm_ids) end
                           and case
                                   when coalesce(in_account_ids, '{}'::int4[]) = '{}'::int4[] then true
                                   else sa.account_id = any (in_account_ids) end
                           and not sa.is_active),
             cte_sa2 as (select sa.account_id,
                                a.trading_firm_id,
                                tf.trading_firm_name,
                                a.account_name,
                                sa.sg_sub_account,
                                sa.opt_customer_or_firm,
                                cf.customer_or_firm_name,
                                sa.date_start
                         from dwh.d_sg_account sa
                                  join dwh.d_account a on (a.account_id = sa.account_id)
                                  join dwh.d_trading_firm tf on (tf.trading_firm_unq_id = a.trading_firm_unq_id)
                                  left join dwh.d_customer_or_firm cf
                                            on (cf.customer_or_firm_id = sa.opt_customer_or_firm)
                         where sa.date_start::date between l_start_date and l_end_date
                           and case
                                   when coalesce(in_trading_firm_ids, '{}'::character varying(9)[]) =
                                        '{}'::character varying(9)[] then true
                                   else a.trading_firm_id = any (in_trading_firm_ids) end
                           and case
                                   when coalesce(in_account_ids, '{}'::int4[]) = '{}'::int4[] then true
                                   else sa.account_id = any (in_account_ids) end
                           and sa.is_active)
        select sa2.trading_firm_name                 as "Trading Firm",
               sa2.account_name                      as "Account",
               sa2.sg_sub_account                    as "Sub Account",
               sa1.customer_or_firm_name             as "Original Account Capacity",
               sa2.customer_or_firm_name             as "Modified Account Capacity",
               to_char(sa2.date_start, 'MM/DD/YYYY') as "Modification Date"
        from cte_sa1 sa1
                 join cte_sa2 sa2 on (sa2.account_id = sa1.account_id)
        where sa1.opt_customer_or_firm is distinct from sa2.opt_customer_or_firm
        order by sa2.trading_firm_id, sa2.account_id;
    get diagnostics l_row_cnt = row_count;
    select public.load_log(l_load_id, l_step_id,
                           'report_surveillance_socgen_acct_mgr_capacity_change for ' || in_start_date_id::text ||
                           '-' || in_end_date_id::text || ' COMPLETED ===',
                           l_row_cnt, 'C')
    into l_step_id;

end ;
$function$;

select * from dash360.report_surveillance_socgen_acct_mgr_capacity_change(20250901, 20250930)