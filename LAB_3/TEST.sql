call compare_schemas('DEV_USER', 'PROD_USER');
commit;
call compare_procedures('DEV_USER', 'PROD_USER');
call compare_functions('DEV_USER', 'PROD_USER');
call compare_indexes('DEV_USER', 'PROD_USER');
call compare_tables('DEV_USER', 'PROD_USER');
call CHECK_FK_CONSTRAINTS('DEV_USER', 'PROD_USER');
call SEARCH_FOR_CIRCULAR_FOREIGN_KEY_REFERENCES('DEV_USER');

call GET_ALL_TABLES_IN_SCHEMA('DEV_USER');
call DROP_ALL_TABLES_IN_SCHEMA('DEV_USER');
call DROP_ALL_TABLES_IN_SCHEMA('PROD_USER');

select * from ALL_CONSTRAINTS where (OWNER = 'DEV_USER' or OWNER = 'PROD_USER');