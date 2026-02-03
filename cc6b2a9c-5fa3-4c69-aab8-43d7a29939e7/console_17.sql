-- P 2
WITH tf AS (SELECT ui.user_id,
                   ac.trading_firm_id,
                   tfc.fix_connection_id
            FROM user_identifier ui
                     JOIN portal_user ps
                          ON ps.user_id = ui.user_id
                     JOIN account_set2account asta
                          ON asta.account_set_id = ps.account_set_id
                     JOIN account ac
                          ON ac.account_id = asta.account_id
                     JOIN trading_firm2client_connection tfc
                          ON tfc.trading_firm_id = ac.trading_firm_id
            WHERE ui.user_role = 'P'
              AND ui.is_deleted = 'N'
              AND ui.is_locked = 'N')
   , tf_u AS (SELECT user_id,
                     fix_connection_id,
                     trading_firm_id
              FROM tf
              GROUP BY user_id, fix_connection_id, trading_firm_id)
   , bad_pairs AS (
    -- пари (user_id, fix_connection_id), де є хоча б один firm_id в TFC,
    -- який НЕ входить в перелік firm_id цього user для цього fix_connection
    SELECT /*+ MATERIALIZE */
        t.user_id,
        t.fix_connection_id
    FROM (SELECT DISTINCT user_id, fix_connection_id FROM tf_u) t
             JOIN trading_firm2client_connection x
                  ON x.fix_connection_id = t.fix_connection_id
             LEFT JOIN tf_u ok
                       ON ok.user_id = t.user_id
                           AND ok.fix_connection_id = t.fix_connection_id
                           AND ok.trading_firm_id = x.trading_firm_id
    WHERE ok.trading_firm_id IS NULL
    GROUP BY t.user_id, t.fix_connection_id)
SELECT u.user_id,
       u.trading_firm_id,
       u.fix_connection_id,
       'P' AS user_role
FROM tf_u u
         LEFT JOIN bad_pairs b
                   ON b.user_id = u.user_id
                       AND b.fix_connection_id = u.fix_connection_id
WHERE b.user_id IS NULL;


with base as (SELECT distinct ui.user_id,
                              ac.trading_firm_id,
                              tfc.fix_connection_id,
                              'P1' as TP
              FROM user_identifier ui
                       JOIN portal_user ps
                            ON ps.user_id = ui.user_id
                       JOIN account_set2account asta
                            ON asta.account_set_id = ps.account_set_id
                       JOIN account ac
                            ON ac.account_id = asta.account_id
                       JOIN trading_firm2client_connection tfc
                            ON tfc.trading_firm_id = ac.trading_firm_id
              WHERE ui.user_role = 'P'
                AND ui.is_deleted = 'N'
                AND ui.is_locked = 'N'

              union all

              SELECT distinct u.user_id,
                              ptf.trading_firm_id,
                              tfc.fix_connection_id,
                              'P2' as tp
              FROM user_identifier u
                       JOIN portal_user2trading_firm ptf
                            ON ptf.user_id = u.user_id
                       JOIN trading_firm2client_connection tfc
                            ON tfc.trading_firm_id = ptf.trading_firm_id
              WHERE u.user_role = 'P'
                AND u.is_deleted = 'N'
                AND u.is_locked = 'N'

              union all

              select distinct u.USER_ID,
                              tf.TRADING_FIRM_ID,
                              FIX_CONNECTION_ID,
                              'T' as tp
              from USER_IDENTIFIER u
                       JOIN TRADING_FIRM_ADMIN2FIRM ta
                            ON ta.USER_ID = u.USER_ID
                       JOIN TRADING_FIRM2CLIENT_CONNECTION tf
                            ON tf.TRADING_FIRM_ID = ta.TRADING_FIRM_ID
              where u.USER_ROLE = 'T'
                AND u.is_deleted = 'N'
                AND u.is_locked = 'N')
   , tf_u AS (SELECT user_id,
                     fix_connection_id,
                     trading_firm_id,
                     tp
              FROM base u)
   , bad_pairs AS (
    -- пари (user_id, fix_connection_id), де є хоча б один firm_id в TFC,
    -- який НЕ входить в перелік firm_id цього user для цього fix_connection
    SELECT /*+ MATERIALIZE */
        t.user_id,
        t.fix_connection_id,
        t.tp
    FROM (SELECT DISTINCT user_id, fix_connection_id, tp FROM tf_u) t
             JOIN trading_firm2client_connection x
                  ON x.fix_connection_id = t.fix_connection_id
             LEFT JOIN tf_u ok
                       ON ok.user_id = t.user_id
                           and ok.tp = t.tp
                           AND ok.fix_connection_id = t.fix_connection_id
                           AND ok.trading_firm_id = x.trading_firm_id
    WHERE ok.trading_firm_id IS NULL
    GROUP BY t.user_id, t.fix_connection_id, t.tp)
SELECT u.user_id,
       u.trading_firm_id,
       u.fix_connection_id,
       fc.FIX_COMP_ID,
       u.tp
FROM tf_u u
         join FIX_CONNECTION fc on fc.FIX_CONNECTION_ID = u.FIX_CONNECTION_ID
         LEFT JOIN bad_pairs b
                   ON b.user_id = u.user_id
                       AND b.fix_connection_id = u.fix_connection_id
                       and b.tp = u.tp
WHERE b.user_id IS NULL;

