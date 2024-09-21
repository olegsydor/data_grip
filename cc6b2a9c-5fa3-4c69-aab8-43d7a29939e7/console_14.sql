CREATE OR REPLACE FORCE VIEW "GENESIS2"."USER2ACCOUNT" ("USER_ROLE", "USER_ID", "ACCOUNT_ID", "TRADING_FIRM_ID") AS
  select ui.USER_ROLE, ui.user_id, asa.account_id, acc.trading_firm_id
        from user_identifier ui
        inner  join PORTAL_USER pu  on (ui.user_id = pu.user_id)
        inner join ACCOUNT_SET2ACCOUNT asa on (pu.account_set_id = asa.ACCOUNT_SET_ID)
        inner join account acc on (asa.account_id = acc.account_id)
        where USER_ROLE in ('A', 'P')
        and ui.is_deleted='N'
        and ((ui.USER_ROLE = 'P' and asa.account_id is not null) or ui.USER_ROLE = 'A')
        UNION
        select ui.USER_ROLE, ui.user_id,  acc.account_id, putf.trading_firm_id
        from user_identifier ui
        left join PORTAL_USER2TRADING_FIRM putf on (ui.user_id = putf.user_id)
        left join account acc on (putf.trading_firm_id = acc.trading_firm_id and acc.is_deleted='N')
        where USER_ROLE in ('A', 'P', 'T')
        and ui.is_deleted='N'
        and ((ui.USER_ROLE = 'P' and putf.trading_firm_id is not null) or ui.USER_ROLE = 'A')
union
select ui.user_role, ui.user_id, ac.account_id, tfa.trading_firm_id
from user_identifier ui
         join trading_firm_admin tfa on tfa.user_id = ui.user_id
         join account ac on ac.trading_firm_id = tfa.trading_firm_id
where user_role = 'T'
  and ui.is_deleted = 'N'
  and ac.is_deleted = 'N';
--   and ui.user_id in (15276, 15841, 15277);