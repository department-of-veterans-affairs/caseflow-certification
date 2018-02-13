
  CREATE TABLESPACE "SYSTEM" DATAFILE
  '/u01/app/oracle/oradata/BVAP/system01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 10485760 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT MANUAL;
   ALTER DATABASE DATAFILE
  '/u01/app/oracle/oradata/BVAP/system01.dbf' RESIZE 2000000;


  CREATE TABLESPACE "SYSAUX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/sysaux01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 10485760 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;
   ALTER DATABASE DATAFILE
  '/u01/app/oracle/oradata/BVAP/sysaux01.dbf' RESIZE 2000000;


  CREATE UNDO TABLESPACE "UNDOTBS1" DATAFILE
  '/u01/app/oracle/oradata/BVAP/undotbs01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 5242880 MAXSIZE 32767M
  BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE;
   ALTER DATABASE DATAFILE
  '/u01/app/oracle/oradata/BVAP/undotbs01.dbf' RESIZE 2000000;


  CREATE TEMPORARY TABLESPACE "TEMP" TEMPFILE
  '/u01/app/oracle/oradata/BVAP/temp01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 655360 MAXSIZE 32767M
  EXTENT MANAGEMENT LOCAL UNIFORM SIZE 2000000;


  CREATE TABLESPACE "USERS" DATAFILE
  '/u01/app/oracle/oradata/BVAP/users01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 1310720 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;
   ALTER DATABASE DATAFILE
  '/u01/app/oracle/oradata/BVAP/users01.dbf' RESIZE 2000000;


  CREATE TABLESPACE "AUDITOR" DATAFILE
  '/u01/app/oracle/oradata/BVAP/auditor.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "BIGROLL" DATAFILE
  '/u01/app/oracle/oradata/BVAP/bigroll.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "BVA_EMPLOYEE" DATAFILE
  '/u01/app/oracle/oradata/BVAP/employee.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;
   ALTER DATABASE DATAFILE
  '/u01/app/oracle/oradata/BVAP/employee.dbf' RESIZE 2000000;


  CREATE TABLESPACE "BVA_PHOTO" DATAFILE
  '/u01/app/oracle/oradata/BVAP/photo.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "DECISION_REV" DATAFILE
  '/u01/app/oracle/oradata/BVAP/decrev.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "PLATINUM" DATAFILE
  '/u01/app/oracle/oradata/BVAP/platinum.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_ASSIGN" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_assign01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_ASSIGN_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_assign_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_ATTACH" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_attach.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_ATTACH_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_attach_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_ATTYTIME" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_attytime.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_BFCORLID_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_bfcorlid_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_BRIEFF" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_brieff.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_BRIEFF_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_brieff_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_CORRES" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_corres01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_CORRES_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_corres_ndx1.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_CORRTYPS" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_corrtyps.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_DEATHS" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_death.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_DEATHS_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_death_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_DECASS" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_decass.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_FOLDER" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_folder01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_FOLDER_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_folder_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_HEARSCHED" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_hearsched.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_INDEXES" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_ISSUES" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_issues.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_OTHDOCS" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_othdocs.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_OTHDOCS_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_othdocs_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_PRIORLOC" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_priorloc01.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_PRIORLOC_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_priorlc_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_RMDREA" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_rmdrea.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_TABLES" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_tables.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_TINUM_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_tinum_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_TITRNUM_NDX" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_titrnum_ndx.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;


  CREATE TABLESPACE "VACOLS_MAIL" DATAFILE
  '/u01/app/oracle/oradata/BVAP/vcl_mail.dbf' SIZE 2000000
  AUTOEXTEND ON NEXT 8192 MAXSIZE 32767M
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO;

