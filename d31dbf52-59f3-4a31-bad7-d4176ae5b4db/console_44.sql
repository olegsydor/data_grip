select * from db_management.table_partman;

select * from db_management.table_retention;

call db_management.migrate_inherit_to_partition(in_table_schema := 'external_data',
                                                in_table_name := 'activ_us_equity_option',
                                                in_partition_schema := 'external_data_partitions',
                                                in_part_field := 'load_date_id');

INSERT INTO db_management.table_partman (schema_name, table_name, part_schema_name, part_type, part_schedule, is_active,
                                         part_priority)
VALUES ('external_data', 'activ_us_equity_option', 'external_data_partitions', 'INT', 'DAY', true, 99);
--
-- INSERT INTO db_management.table_retention (schema_name,table_name,retention_period,cleanup_schedule,key_field,is_active,retention_type)
-- 	VALUES ('external_data','activ_us_equity_option',10,'DAY','load_date_id',true,'D');

call db_management.add_partitions();


select * from external_data.activ_us_equity_option