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
and not exists(select null from );


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
select get_shp_data() from dual;


SELECT * FROM GENESIS2_QA_20100601.PORTAL_USER2TRADING_FIRM WHERE USER_ID=9503;

SELECT                 ui.user_id,
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
    WHERE 1=1
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
                    and t.TRADING_FIRM_ID not in ('360ba01', '360sga')
                  );

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
       listagg(tf.FIX_CONNECTION_ID, ',') within group ( order by tf.FIX_CONNECTION_ID )
from tf
where 1 = 1
   and tf.user_Id = 9505
  and not exists (select null
                  from GENESIS2_QA_20100601.TRADING_FIRM2CLIENT_CONNECTION t
                  where t.FIX_CONNECTION_ID = tf.FIX_CONNECTION_ID
                    and t.TRADING_FIRM_ID not in (SELECT tf.TRADING_FIRM_ID
                                                  from tf tfi
                                                  where tfi.user_id = tf.USER_ID))
group by tf.user_id, tf.TRADING_FIRM_ID;

-- P
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