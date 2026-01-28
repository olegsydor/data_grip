select user_ID, USER_ROLE, listagg(FIX_COMP_ID, ', ') within group ( order by FIX_COMP_ID )--, fc.FIX_CONNECTION_ID, tf.TRADING_FIRM_ID
from (select distinct ui.user_ID, ui.USER_ROLE, fc.FIX_COMP_ID
      from USER_IDENTIFIER ui
               join PORTAL_USER ps on ps.USER_ID = ui.USER_ID
               join PORTAL_USER2TRADING_FIRM ptf on ptf.USER_ID = ps.USER_ID
               join TRADING_FIRM tf on tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID

               join ACCOUNT_SET acs on acs.ACCOUNT_SET_ID = ps.ACCOUNT_SET_ID
               join ACCOUNT_SET2ACCOUNT asta on asta.ACCOUNT_SET_ID = acs.ACCOUNT_SET_ID
               join ACCOUNT ac on ac.ACCOUNT_ID = asta.ACCOUNT_ID and ac.TRADING_FIRM_ID = tf.TRADING_FIRM_ID

               JOIN TRADING_FIRM2CLIENT_CONNECTION tf on tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID
               join FIX_CONNECTION fc ON fc.FIX_CONNECTION_ID = tf.FIX_CONNECTION_ID

      WHERE 1 = 1
--     and fc.IS_DELETED <> 'Y'
        and ui.USER_ROLE in ('P', 'T')) x
group by user_ID, USER_ROLE

