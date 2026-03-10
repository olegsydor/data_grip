WITH pk AS (SELECT owner, constraint_name
            FROM all_constraints
            WHERE table_name = 'INSTRUMENT'
              AND constraint_type IN ('P', 'U')
              and owner in
                  ('GENESIS2_QA_SMS_CMPLX', 'GENESIS2_QA_20100601', 'GENESIS2_UAT_SEG4_SMS0', 'GENESIS2_UAT_SEG4_SMS1',
                   'GENESIS2_UAT_SEG6_SMS0', 'GENESIS2_UAT_SEG6_SMS1', 'GENESIS2_UAT_SEG8_SMS0',
                   'GENESIS2_UAT_SEG8_SMS1', 'GENESIS2_UAT_SEG8_SMS3', 'GENESIS2_UAT_SEG9_SMS0',
                   'GENESIS2_UAT_SEG9_SMS1''GENESIS2_UAT_SEG9_SMS3', 'GENESIS2_UAT_SMS_MDS')),
     fk AS (SELECT c.owner,
                   c.table_name,
                   c.constraint_name,
                   c.delete_rule,
                   LISTAGG(col.column_name, ', ')
                           WITHIN GROUP (ORDER BY col.position) AS columns_list
            FROM all_constraints c
                     JOIN all_cons_columns col
                          ON col.owner = c.owner
                              AND col.constraint_name = c.constraint_name
            WHERE c.constraint_type = 'R'
              and c.owner in
                  ('GENESIS2_QA_SMS_CMPLX', 'GENESIS2_QA_20100601', 'GENESIS2_UAT_SEG4_SMS0', 'GENESIS2_UAT_SEG4_SMS1',
                   'GENESIS2_UAT_SEG6_SMS0', 'GENESIS2_UAT_SEG6_SMS1', 'GENESIS2_UAT_SEG8_SMS0',
                   'GENESIS2_UAT_SEG8_SMS1', 'GENESIS2_UAT_SEG8_SMS3', 'GENESIS2_UAT_SEG9_SMS0',
                   'GENESIS2_UAT_SEG9_SMS1''GENESIS2_UAT_SEG9_SMS3', 'GENESIS2_UAT_SMS_MDS')
              AND c.delete_rule = 'CASCADE'
              AND c.r_constraint_name IN (SELECT constraint_name FROM pk)
            GROUP BY c.owner, c.table_name, c.constraint_name, c.delete_rule)
        ,
     res as (SELECT fk.owner,
                    fk.table_name,
                    fk.constraint_name,
                    fk.columns_list,
                    CASE
                        WHEN EXISTS (SELECT 1
                                     FROM all_ind_columns ic
                                     WHERE ic.table_owner = fk.owner
                                       AND ic.table_name = fk.table_name
                                       AND ic.column_name IN (SELECT column_name
                                                              FROM all_cons_columns
                                                              WHERE owner = fk.owner
                                                                AND constraint_name = fk.constraint_name))
                            THEN 'INDEX EXISTS'
                        ELSE
                            'CREATE INDEX IDX_' ||
                            fk.table_name || '_' ||
                            fk.columns_list ||
                            ' ON ' ||
                            fk.owner || '.' || fk.table_name ||
                            '(' || fk.columns_list || ');' end
                        AS create_index
             FROM fk)
select *
from res
where create_index != 'INDEX EXISTS'
ORDER BY owner, table_name;


INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_SEG75_SMS3.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');


INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_QA_SMS_CMPLX.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG4_SMS0.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG4_SMS1.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG6_SMS0.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG6_SMS1.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG8_SMS0.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG8_SMS1.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG8_SMS3.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');
INSERT INTO GENESIS2_QA_20100601.TABLE_RETENTION (TABLE_NAME,RETENTION_PERIOD,CLEANUP_SCHEDULE,KEY_FIELD,IS_ACTIVE)
VALUES ('GENESIS2_UAT_SEG9_SMS0.INSTRUMENT',120,'DAY','LAST_TRADE_DATE','Y');



'GENESIS2_QA_SMS_CMPLX', 'GENESIS2_QA_20100601', 'GENESIS2_UAT_SEG4_SMS0', 'GENESIS2_UAT_SEG4_SMS1',
                   'GENESIS2_UAT_SEG6_SMS0', 'GENESIS2_UAT_SEG6_SMS1', 'GENESIS2_UAT_SEG8_SMS0',
                   'GENESIS2_UAT_SEG8_SMS1', 'GENESIS2_UAT_SEG8_SMS3', 'GENESIS2_UAT_SEG9_SMS0',
                   'GENESIS2_UAT_SEG9_SMS1''GENESIS2_UAT_SEG9_SMS3', 'GENESIS2_UAT_SMS_MDS'