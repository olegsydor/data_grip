SELECT --DISTINCT
       fc.FIX_COMP_ID,
       fc.FIX_CONNECTION_ID,
       tf.TRADING_FIRM_ID,
       fc.IS_DELETED,
       fc.*
FROM GENESIS2_QA_20100601.FIX_CONNECTION fc
         LEFT JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tf
                   ON fc.FIX_CONNECTION_ID = tf.FIX_CONNECTION_ID
WHERE fc.IS_DELETED <> 'Y'


select FIX_COMP_ID, fc.FIX_COMP_ID, fc.FIX_CONNECTION_ID, ac.TRADING_FIRM_ID
from USER_IDENTIFIER ui
         join PORTAL_USER2TRADING_FIRM ptf on ptf.USER_ID = ui.USER_ID
         JOIN TRADING_FIRM2CLIENT_CONNECTION tf on tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID
         join FIX_CONNECTION fc ON fc.FIX_CONNECTION_ID = tf.FIX_CONNECTION_ID
         left join ACCOUNT ac on ac.TRADING_FIRM_ID = tf.TRADING_FIRM_ID
WHERE fc.IS_DELETED <> 'Y'
  and ui.USER_ROLE in ('P', 'T')
  and not exists(select null from);


select ui.user_ID, ui.USER_ROLE, fc.FIX_COMP_ID, fc.FIX_CONNECTION_ID, tf.TRADING_FIRM_ID
from USER_IDENTIFIER ui
         join PORTAL_USER ps on ps.USER_ID = ui.USER_ID
         join PORTAL_USER2TRADING_FIRM ptf on ptf.USER_ID = ps.USER_ID
         JOIN TRADING_FIRM2CLIENT_CONNECTION tf on tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID
         join FIX_CONNECTION fc ON fc.FIX_CONNECTION_ID = tf.FIX_CONNECTION_ID
         join ACCOUNT ac on ac.TRADING_FIRM_ID = tf.TRADING_FIRM_ID
         join ACCOUNT_SET acs on acs.ACCOUNT_SET_ID = ps.ACCOUNT_SET_ID
         join ACCOUNT_SET2ACCOUNT asta on asta.ACCOUNT_SET_ID = acs.ACCOUNT_SET_ID
WHERE fc.IS_DELETED <> 'Y'
  and ui.USER_ROLE in ('P', 'T')
  and ui.user_id = 8851;

select ui.user_ID, ui.USER_ROLE, fc.FIX_COMP_ID, fc.FIX_CONNECTION_ID, tf.TRADING_FIRM_ID
from USER_IDENTIFIER ui

         join PORTAL_USER ps on ps.USER_ID = ui.USER_ID
         join PORTAL_USER2TRADING_FIRM ptf on ptf.USER_ID = ps.USER_ID
         join TRADING_FIRM tf on tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID

         join ACCOUNT_SET acs on acs.ACCOUNT_SET_ID = ps.ACCOUNT_SET_ID
         join ACCOUNT_SET2ACCOUNT asta on asta.ACCOUNT_SET_ID = acs.ACCOUNT_SET_ID
         join ACCOUNT ac on ac.ACCOUNT_ID = asta.ACCOUNT_ID and ac.TRADING_FIRM_ID = tf.TRADING_FIRM_ID

         JOIN TRADING_FIRM2CLIENT_CONNECTION tf on tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID
         join FIX_CONNECTION fc ON fc.FIX_CONNECTION_ID = tf.FIX_CONNECTION_ID

WHERE fc.IS_DELETED <> 'Y'
  and ui.USER_ROLE in ('P', 'T')
  and ui.user_id = 8851;


create or replace type user_fix_comp_id as object
(
    user_id     number(13),
    user_role   char,
    fix_comp_id varchar
);

create or replace type type_user_fix_comp_id as table of user_fix_comp_id;

-- create or replace function get_shp_data()
return type_user_fix_comp_id as
    CURSOR CURSEUR_ETAPE
        IS
select user_ID,
       USER_ROLE,
       listagg(FIX_COMP_ID, ', ') within group ( order by FIX_COMP_ID )--, fc.FIX_CONNECTION_ID, tf.TRADING_FIRM_ID
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
        and fc.IS_DELETED <> 'Y'
        and ui.USER_ROLE in ('P', 'T')) x
group by user_ID, USER_ROLE;
VAR type_user_fix_comp_id := type_user_fix_comp_id();
BEGIN
    OPEN CURSEUR_ETAPE;

    LOOP
        FETCH CURSEUR_ETAPE
            BULK COLLECT INTO VAR LIMIT 100;

        EXIT WHEN CURSEUR_ETAPE%NOTFOUND;
    END LOOP;

    CLOSE CURSEUR_ETAPE;

    RETURN VAR;
END;
commit
select get_shp_data()
from dual;


SELECT *
FROM GENESIS2_QA_20100601.PORTAL_USER2TRADING_FIRM
WHERE USER_ID = 9503;

SELECT ui.user_id,
       ui.user_role
        ,
       fc.fix_comp_id

FROM GENESIS2_QA_20100601.USER_IDENTIFIER ui
         JOIN GENESIS2_QA_20100601.PORTAL_USER2TRADING_FIRM ptf
              ON ptf.USER_ID = ui.USER_ID
         JOIN GENESIS2_QA_20100601.PORTAL_USER ps
              ON ps.USER_ID = ui.USER_ID
         JOIN GENESIS2_QA_20100601.TRADING_FIRM tf
              ON tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID
         JOIN GENESIS2_QA_20100601.ACCOUNT_SET acs
              ON acs.ACCOUNT_SET_ID = ps.ACCOUNT_SET_ID
         JOIN GENESIS2_QA_20100601.ACCOUNT_SET2ACCOUNT asta
              ON asta.ACCOUNT_SET_ID = acs.ACCOUNT_SET_ID
         JOIN GENESIS2_QA_20100601.ACCOUNT ac
              ON ac.ACCOUNT_ID = asta.ACCOUNT_ID
                  AND ac.TRADING_FIRM_ID = tf.TRADING_FIRM_ID
         JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tfcc
              ON tfcc.TRADING_FIRM_ID = tf.TRADING_FIRM_ID
         JOIN GENESIS2_QA_20100601.FIX_CONNECTION fc
              ON fc.FIX_CONNECTION_ID = tfcc.FIX_CONNECTION_ID
WHERE 1 = 1
--     and fc.IS_DELETED <> 'Y'
  AND ui.USER_ROLE IN ('P', 'T')
  and ui.USER_ID = 9503;


-- user 1
SELECT ui.user_id,
       ui.user_role,
       taf.TRADING_FIRM_ID,
       tfcc.FIX_CONNECTION_ID
from GENESIS2_QA_20100601.USER_IDENTIFIER ui
         JOIN GENESIS2_QA_20100601.TRADING_FIRM_ADMIN2FIRM taf ON taf.USER_ID = ui.USER_ID
         JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tfcc ON tfcc.TRADING_FIRM_ID = taf.TRADING_FIRM_ID
--          JOIN GENESIS2_QA_20100601.FIX_CONNECTION fc
--            ON fc.FIX_CONNECTION_ID = tfcc.FIX_CONNECTION_ID
where ui.user_id = 9505
  and not exists (select null
                  from GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION t
                  where t.FIX_CONNECTION_ID = tfcc.FIX_CONNECTION_ID
                    and t.TRADING_FIRM_ID not in ('360ba01', '360sga'));

-- user 1
SELECT ui.user_id,
       taf.TRADING_FIRM_ID,
       listagg(tfcc.FIX_CONNECTION_ID, ',') within group ( order by tfcc.FIX_CONNECTION_ID )
from GENESIS2_QA_20100601.USER_IDENTIFIER ui
         JOIN GENESIS2_QA_20100601.TRADING_FIRM_ADMIN2FIRM taf ON taf.USER_ID = ui.USER_ID
         JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tfcc ON tfcc.TRADING_FIRM_ID = taf.TRADING_FIRM_ID
where ui.user_id = 9505
--   and not exists (select null
--                   from GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION t
--                   where t.FIX_CONNECTION_ID = tfcc.FIX_CONNECTION_ID
--                     and t.TRADING_FIRM_ID not in ('360ba01', '360sga')
--                   )
group by ui.user_id,
         taf.TRADING_FIRM_ID;

SELECT ui.user_id,
       taf.TRADING_FIRM_ID,
       listagg(tfcc.FIX_CONNECTION_ID, ',') within group ( order by tfcc.FIX_CONNECTION_ID )
from GENESIS2_QA_20100601.USER_IDENTIFIER ui
         JOIN GENESIS2_QA_20100601.TRADING_FIRM_ADMIN2FIRM taf ON taf.USER_ID = ui.USER_ID
         JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tfcc ON tfcc.TRADING_FIRM_ID = taf.TRADING_FIRM_ID
where 1 = 1
  and ui.user_id = 9505
  and ui.USER_ROLE = 'T'
  and not exists (select null
                  from GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION t
                  where t.FIX_CONNECTION_ID = tfcc.FIX_CONNECTION_ID
                    and t.TRADING_FIRM_ID not in (SELECT ta.TRADING_FIRM_ID
                                                  from GENESIS2_QA_20100601.USER_IDENTIFIER u
                                                           JOIN GENESIS2_QA_20100601.TRADING_FIRM_ADMIN2FIRM ta
                                                                ON ta.USER_ID = u.USER_ID
                                                           JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tf
                                                                ON tf.TRADING_FIRM_ID = ta.TRADING_FIRM_ID
                                                  where u.user_id = ui.USER_ID))
group by ui.user_id, taf.TRADING_FIRM_ID;

-- T
with tf as (select u.USER_ID, tf.TRADING_FIRM_ID, FIX_CONNECTION_ID
            from GENESIS2_QA_20100601.USER_IDENTIFIER u
                     JOIN GENESIS2_QA_20100601.TRADING_FIRM_ADMIN2FIRM ta
                          ON ta.USER_ID = u.USER_ID
                     JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tf
                          ON tf.TRADING_FIRM_ID = ta.TRADING_FIRM_ID
            where u.USER_ROLE = 'T')
SELECT tf.user_id,
       tf.TRADING_FIRM_ID,
       tf.FIX_CONNECTION_ID,
       'T'
from tf
where 1 = 1
  and tf.user_Id = 9505
  and not exists (select null
                  from GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION t
                  where t.FIX_CONNECTION_ID = tf.FIX_CONNECTION_ID
                    and t.TRADING_FIRM_ID not in (SELECT tf.TRADING_FIRM_ID
                                                  from tf tfi
                                                  where tfi.user_id = tf.USER_ID));
-- P
select ui.USER_ID,
       tf.TRADING_FIRM_ID,
       tf.FIX_CONNECTION_ID,
       'P' as "ROLE"
FROM GENESIS2_QA_20100601.USER_IDENTIFIER ui
         JOIN GENESIS2_QA_20100601.PORTAL_USER2TRADING_FIRM ptf ON ptf.USER_ID = ui.USER_ID
         JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tf
              ON tf.TRADING_FIRM_ID = ptf.TRADING_FIRM_ID
where ui.USER_ID in (9503, 9504)
union
select ui.USER_ID,
       tf.TRADING_FIRM_ID,
       tf.FIX_CONNECTION_ID,
       'P' as "ROLE"
FROM GENESIS2_QA_20100601.USER_IDENTIFIER ui
         JOIN GENESIS2_QA_20100601.PORTAL_USER ps
              ON ps.USER_ID = ui.USER_ID
         JOIN GENESIS2_QA_20100601.ACCOUNT_SET acs
              ON acs.ACCOUNT_SET_ID = ps.ACCOUNT_SET_ID
         JOIN GENESIS2_QA_20100601.ACCOUNT_SET2ACCOUNT asta
              ON asta.ACCOUNT_SET_ID = acs.ACCOUNT_SET_ID
         JOIN GENESIS2_QA_20100601.ACCOUNT ac
              ON ac.ACCOUNT_ID = asta.ACCOUNT_ID
         JOIN GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION tf
              ON tf.TRADING_FIRM_ID = ac.TRADING_FIRM_ID
where ui.USER_ROLE = 'P'
  and ui.user_ID in (9503, 9504);

CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.get_user_fix_comp_id_2
    RETURN GENESIS2_QA_20100601.type_user_fix_comp_id
AS
    l_result GENESIS2_QA_20100601.type_user_fix_comp_id;
BEGIN
    WITH tf AS (SELECT u.user_id,
                       ta.trading_firm_id,
                       tfc.fix_connection_id
                FROM GENESIS2_QA_20100601.user_identifier u
                         JOIN GENESIS2_QA_20100601.trading_firm_admin2firm ta
                              ON ta.user_id = u.user_id
                         JOIN GENESIS2_QA_20100601.trading_firm2client_connection tfc
                              ON tfc.trading_firm_id = ta.trading_firm_id
                WHERE u.user_role = 'T'),
         p AS (SELECT ui.user_id,
                      tfc.trading_firm_id,
                      tfc.fix_connection_id,
                      'P' AS user_role
               FROM GENESIS2_QA_20100601.user_identifier ui
                        JOIN GENESIS2_QA_20100601.portal_user2trading_firm ptf
                             ON ptf.user_id = ui.user_id
                        JOIN GENESIS2_QA_20100601.trading_firm2client_connection tfc
                             ON tfc.trading_firm_id = ptf.trading_firm_id
               WHERE ui.user_id IN (9503, 9504)

               UNION

               SELECT ui.user_id,
                      tfc.trading_firm_id,
                      tfc.fix_connection_id,
                      'P' AS user_role
               FROM GENESIS2_QA_20100601.user_identifier ui
                        JOIN GENESIS2_QA_20100601.portal_user ps
                             ON ps.user_id = ui.user_id
                        JOIN GENESIS2_QA_20100601.account_set acs
                             ON acs.account_set_id = ps.account_set_id
                        JOIN GENESIS2_QA_20100601.account_set2account asta
                             ON asta.account_set_id = acs.account_set_id
                        JOIN GENESIS2_QA_20100601.account ac
                             ON ac.account_id = asta.account_id
                        JOIN GENESIS2_QA_20100601.trading_firm2client_connection tfc
                             ON tfc.trading_firm_id = ac.trading_firm_id
               WHERE ui.user_role = 'P'
                 AND ui.user_id IN (9503, 9504)),
         t AS (SELECT tf.user_id,
                      tf.trading_firm_id,
                      tf.fix_connection_id,
                      'T' AS user_role
               FROM tf
               WHERE tf.user_id = 9505
                 AND NOT EXISTS (SELECT 1
                                 FROM GENESIS2_QA_20100601.trading_firm2client_connection x
                                 WHERE x.fix_connection_id = tf.fix_connection_id
                                   AND x.trading_firm_id NOT IN (SELECT tfi.trading_firm_id
                                                                 FROM tf tfi
                                                                 WHERE tfi.user_id = tf.user_id))),
         total AS (SELECT *
                   FROM p
                   UNION ALL
                   SELECT *
                   FROM t)
    SELECT CAST(
                   COLLECT(
                           GENESIS2_QA_20100601.user_fix_comp_id(
                                   total.user_id,
                                   total.user_role,
                                   LISTAGG(fc.fix_comp_id, ', ')
                                           WITHIN GROUP (ORDER BY fc.fix_comp_id)
                           )
                   )
               AS GENESIS2_QA_20100601.type_user_fix_comp_id
           )
    INTO l_result
    FROM total
             JOIN GENESIS2_QA_20100601.fix_connection fc
                  ON fc.fix_connection_id = total.fix_connection_id
    GROUP BY total.user_id, total.user_role;

    RETURN l_result;
END;
/
drop FUNCTION GENESIS2_QA_20100601.get_user_fix_comp_id_2;
CREATE OR REPLACE FUNCTION GENESIS2_QA_20100601.get_user_fix_comp_id_2
    RETURN GENESIS2_QA_20100601.type_user_fix_comp_id
    PIPELINED
AS
BEGIN
    FOR r IN (
        WITH tf AS (SELECT u.user_id,
                           ta.trading_firm_id,
                           tfc.fix_connection_id
                    FROM user_identifier u
                             JOIN trading_firm_admin2firm ta
                                  ON ta.user_id = u.user_id
                             JOIN trading_firm2client_connection tfc
                                  ON tfc.trading_firm_id = ta.trading_firm_id
                    WHERE u.user_role = 'T'),
             p AS (SELECT ui.user_id,
                          tfc.trading_firm_id,
                          tfc.fix_connection_id,
                          'P' AS user_role
                   FROM user_identifier ui
                            JOIN portal_user2trading_firm ptf
                                 ON ptf.user_id = ui.user_id
                            JOIN trading_firm2client_connection tfc
                                 ON tfc.trading_firm_id = ptf.trading_firm_id
                   WHERE ui.user_role = 'P'
--                 and ui.user_id IN (9503, 9504)

                   UNION

                   SELECT ui.user_id,
                          tfc.trading_firm_id,
                          tfc.fix_connection_id,
                          'P' AS user_role
                   FROM user_identifier ui
                            JOIN portal_user ps
                                 ON ps.user_id = ui.user_id
                            JOIN account_set acs
                                 ON acs.account_set_id = ps.account_set_id
                            JOIN account_set2account asta
                                 ON asta.account_set_id = acs.account_set_id
                            JOIN account ac
                                 ON ac.account_id = asta.account_id
                            JOIN trading_firm2client_connection tfc
                                 ON tfc.trading_firm_id = ac.trading_firm_id
                   WHERE ui.user_role = 'P'
--               AND ui.user_id IN (9503, 9504)
             ),
             t AS (SELECT tf.user_id,
                          tf.trading_firm_id,
                          tf.fix_connection_id,
                          'T' AS user_role
                   FROM tf
                   WHERE 1 = 1
--                 and tf.user_id = 9505
                     AND NOT EXISTS (SELECT 1
                                     FROM trading_firm2client_connection x
                                     WHERE x.fix_connection_id = tf.fix_connection_id
                                       AND x.trading_firm_id NOT IN (SELECT tfi.trading_firm_id
                                                                     FROM tf tfi
                                                                     WHERE tfi.user_id = tf.user_id))),
             total AS (SELECT *
                       FROM p
                       UNION ALL
                       SELECT *
                       FROM t)
        SELECT total.user_id,
               total.user_role,
               LISTAGG(fc.fix_comp_id, ', ')
                       WITHIN GROUP (ORDER BY fc.fix_comp_id) AS fix_comp_id
        FROM total
                 JOIN fix_connection fc
                      ON fc.fix_connection_id = total.fix_connection_id
        GROUP BY total.user_id, total.user_role
        )
        LOOP
            PIPE ROW (
                GENESIS2_QA_20100601.user_fix_comp_id(
                        r.user_id,
                        r.user_role,
                        r.fix_comp_id
                )
                );
        END LOOP;

    RETURN;
END;
/
commit;



drop FUNCTION GENESIS2_QA_20100601.get_user_fix_comp_id_3;
CREATE OR REPLACE procedure GENESIS2_QA_20100601.get_user_fix_comp_id_3
AS
BEGIN

    EXECUTE IMMEDIATE
        'TRUNCATE TABLE GENESIS2_QA_20100601.user_fix_comp_ids';

    insert into GENESIS2_QA_20100601.user_fix_comp_ids(user_id, user_role, fix_comp_id)
    WITH tf AS (SELECT u.user_id,
                       ta.trading_firm_id,
                       tfc.fix_connection_id
                FROM user_identifier u
                         JOIN trading_firm_admin2firm ta
                              ON ta.user_id = u.user_id
                         JOIN trading_firm2client_connection tfc
                              ON tfc.trading_firm_id = ta.trading_firm_id
                WHERE u.user_role = 'T'
--                 and u.user_id IN (9503, 9504, 9505)
                )
            ,
         total AS (SELECT tf.user_id,
                          tf.trading_firm_id,
                          tf.fix_connection_id,
                          'T' AS user_role
                   FROM tf
                   WHERE 1 = 1
--                 and tf.user_id = 9505
                     AND NOT EXISTS (SELECT 1
                                     FROM trading_firm2client_connection x
                                     WHERE x.fix_connection_id = tf.fix_connection_id
                                       AND x.trading_firm_id NOT IN (SELECT tfi.trading_firm_id
                                                                     FROM tf tfi
                                                                     WHERE tfi.user_id = tf.user_id)))
    SELECT total.user_id,
           total.user_role,
           fc.fix_comp_id
    FROM total
             JOIN fix_connection fc
                  ON fc.fix_connection_id = total.fix_connection_id;


--     insert into GENESIS2_QA_20100601.user_fix_comp_ids(user_id, user_role, fix_comp_id)
    WITH tf AS (SELECT  u.user_id,
                       ptf.trading_firm_id,
                       tfc.fix_connection_id
                FROM user_identifier u
                         JOIN portal_user2trading_firm ptf
                              ON ptf.user_id = u.user_id
                         JOIN trading_firm2client_connection tfc
                              ON tfc.trading_firm_id = ptf.trading_firm_id
                WHERE u.user_role = 'P')
-- ,    popal AS (
    SELECT tf.user_id,
           tf.trading_firm_id,
           tf.fix_connection_id,
           'P' AS user_role
    FROM tf
    where 1 = 1
      and tf.user_id IN (9503, 9504, 9505)
      AND NOT EXISTS (SELECT 1
                      FROM trading_firm2client_connection x
                      WHERE x.fix_connection_id = tf.fix_connection_id
                        AND x.trading_firm_id NOT IN (SELECT tfi.trading_firm_id
                                                      FROM tf tfi
                                                      WHERE tfi.user_id = tf.user_id));

    with tf as (SELECT
                    /* materialize */
                    distinct ui.user_id,
                             tfc.trading_firm_id,
                             tfc.fix_connection_id,
                             'P' AS user_role
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
                  and ui.IS_DELETED = 'N'
                  and ui.IS_LOCKED = 'N'
                order by trading_firm_id)
    SELECT tf.user_id,
           tf.trading_firm_id,
           tf.fix_connection_id,
           'P' AS user_role
    FROM tf
    where 1 = 1
--       AND tf.user_id IN (9503, 9504, 9505)
      AND NOT EXISTS (SELECT 1
                      FROM trading_firm2client_connection x
                      WHERE x.fix_connection_id = tf.fix_connection_id
                        AND x.trading_firm_id NOT IN (SELECT tfi.trading_firm_id
                                                      FROM tf tfi
                                                      WHERE tfi.user_id = tf.user_id));
END;
/
commit

create table GENESIS2_QA_20100601.user_fix_comp_ids
(
    user_id     number(13),
    user_role   char,
    fix_comp_id varchar(4000)
)

select count(*)
FROM user_identifier ui
                         JOIN portal_user ps
                              ON ps.user_id = ui.user_id
                         JOIN account_set acs
                              ON acs.account_set_id = ps.account_set_id
                         JOIN account_set2account asta
                              ON asta.account_set_id = acs.account_set_id
                         JOIN account ac
                              ON ac.account_id = asta.account_id
                         JOIN trading_firm2client_connection tfc
                              ON tfc.trading_firm_id = ac.trading_firm_id
                WHERE ui.user_role = 'P';


    WITH tf AS (SELECT  u.user_id,
                       ptf.trading_firm_id,
                       tfc.fix_connection_id
                FROM user_identifier u
                         JOIN portal_user2trading_firm ptf
                              ON ptf.user_id = u.user_id
                         JOIN trading_firm2client_connection tfc
                              ON tfc.trading_firm_id = ptf.trading_firm_id
                WHERE u.user_role = 'P')
-- ,    popal AS (
    SELECT tf.user_id,
           tf.trading_firm_id,
           tf.fix_connection_id,
           'P' AS user_role
    FROM tf
    where 1 = 1
      and tf.user_id IN (9503, 9504, 9505)
      AND NOT EXISTS (SELECT 1
                      FROM trading_firm2client_connection x
                      WHERE x.fix_connection_id = tf.fix_connection_id
                        AND x.trading_firm_id NOT IN (SELECT tfi.trading_firm_id
                                                      FROM tf tfi
                                                      WHERE tfi.user_id = tf.user_id));


WITH tf_u AS (SELECT u.user_id,
                     ptf.trading_firm_id,
                     tfc.fix_connection_id
              FROM user_identifier u
                       JOIN portal_user2trading_firm ptf
                            ON ptf.user_id = u.user_id
                       JOIN trading_firm2client_connection tfc
                            ON tfc.trading_firm_id = ptf.trading_firm_id
              WHERE u.user_role = 'P'
                AND u.is_deleted = 'N'
                AND u.is_locked = 'N'
--      AND u.user_id IN (9503, 9504, 9505)
)
SELECT tf_u.user_id,
       tf_u.trading_firm_id,
       tf_u.fix_connection_id,
       'P' AS user_role
FROM tf_u
where not exists
          (SELECT null
           FROM trading_firm2client_connection x
                    LEFT JOIN tf_u ok ON (ok.user_id = tf_u.user_id
               AND ok.fix_connection_id = tf_u.fix_connection_id
               AND ok.trading_firm_id = x.trading_firm_id
                        and x.user_id = tf_u.user_id)
           WHERE ok.trading_firm_id IS null
             and x.fix_connection_id = tf_u.fix_connection_id

             and t.fix_connection_id = tf_u.fix_connection_id);



SELECT ui.user_id,
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
              AND ui.is_locked = 'N'




drop materialized view GENESIS2_QA_20100601.user2trading_firm_mv;
create materialized view GENESIS2_QA_20100601.user2trading_firm_mv as
SELECT ui.user_id,
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

SELECT u.user_id,
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

select u.USER_ID,
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
  AND u.is_locked = 'N';
commit;

create index utfmv_USER_ID_idx on GENESIS2_QA_20100601.user2trading_firm_mv (USER_ID)
create index utfmv_TRADING_FIRM_ID_idx on GENESIS2_QA_20100601.user2trading_firm_mv (TRADING_FIRM_ID)
create index utfmv_FIX_CONNECTION_ID_idx on GENESIS2_QA_20100601.user2trading_firm_mv (FIX_CONNECTION_ID)
create index utfmv_tp_idx on GENESIS2_QA_20100601.user2trading_firm_mv (tp);

select * from GENESIS2_QA_20100601.user2trading_firm_v
where user_id = 9164

refresh materialized view GENESIS2_QA_20100601.user2trading_firm_mv

EXEC DBMS_MVIEW.REFRESH('user2trading_firm_mv', 'C');

BEGIN
DBMS_SNAPSHOT.REFRESH('user2trading_firm_mv');
END;

BEGIN
DBMS_SNAPSHOT.REFRESH( 'user2trading_firm_mv','c');
END;

create view ptuser2fixcompid_v as
SELECT u.user_id,
       u.trading_firm_id,
       u.fix_connection_id,
       fc.FIX_COMP_ID,
       u.tp AS type
from GENESIS2_QA_20100601.user2trading_firm_mv u
         join FIX_CONNECTION fc on fc.FIX_CONNECTION_ID = u.FIX_CONNECTION_ID
where 1 = 1
--     and user_id in (9503, 9504, 9505)
  and not exists (select null
                  from GENESIS2_QA_20100601.user2trading_firm_mv iu
                  where iu.tp = u.tp
                    and iu.fix_connection_id = u.fix_connection_id
                    and iu.trading_firm_id not in (select trading_firm_id
                                                   from GENESIS2_QA_20100601.user2trading_firm_mv s
                                                   where 1 = 1
                                                     and s.tp = u.tp
                                                     and s.user_id = u.user_id));
commit