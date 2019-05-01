CONNECT sys/Oradoc_db1@BVAP as sysdba

ALTER SESSION set "_ORACLE_SCRIPT"=true;

CREATE USER VACOLS_DEV IDENTIFIED BY VACOLS_DEV;
GRANT UNLIMITED TABLESPACE TO VACOLS_DEV;
GRANT CREATE SESSION TO VACOLS_DEV;

CREATE USER VACOLS_TEST IDENTIFIED BY VACOLS_TEST;
GRANT UNLIMITED TABLESPACE TO VACOLS_TEST;
GRANT CREATE SESSION TO VACOLS_TEST;

@/ORCL/vacols_copy_1_tablespaces.sql
@/ORCL/vacols_copy_2_tables_dev.sql
@/ORCL/vacols_copy_2_tables_test.sql
@/ORCL/vacols_copy_3_indexes_dev.sql
@/ORCL/vacols_copy_3_indexes_test.sql
@/ORCL/vacols_copy_7_sequences_dev.sql
@/ORCL/vacols_copy_7_sequences_test.sql
@/ORCL/vacols_copy_4_triggers_dev.sql
@/ORCL/vacols_copy_4_triggers_test.sql
@/ORCL/vacols_copy_5_functions_dev.sql
@/ORCL/vacols_copy_5_functions_test.sql
@/ORCL/vacols_copy_6_procedures_dev.sql
@/ORCL/vacols_copy_6_procedures_test.sql
exit
