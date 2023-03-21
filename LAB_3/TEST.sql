call compare_schemas('C##DEV_USER', 'C##PROD_USER');
commit;
call compare_procedures('C##DEV_USER', 'C##PROD_USER');
call compare_functions('C##DEV_USER', 'C##PROD_USER');
call compare_indexes('C##DEV_USER', 'C##PROD_USER');
call compare_tables('C##DEV_USER', 'C##PROD_USER');
call CHECK_FK_CONSTRAINTS('C##DEV_USER', 'C##PROD_USER');
call SEARCH_FOR_CIRCULAR_FOREIGN_KEY_REFERENCES('C##DEV_USER');

call GET_ALL_TABLES_IN_SCHEMA('C##DEV_USER');
call DROP_ALL_TABLES_IN_SCHEMA('C##DEV_USER');
call DROP_ALL_TABLES_IN_SCHEMA('C##PROD_USER');

select * from ALL_CONSTRAINTS where (OWNER = 'C##DEV_USER' or OWNER = 'C##PROD_USER');