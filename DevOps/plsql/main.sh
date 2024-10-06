#!/bin/bash

today=$(date +%Y-%m-%d-%H-%M-%S)

# Define environment variables
export WORKSPACE=$WORKSPACE
export SCRIPT_DIR=$SCRIPT_DIR
export WNAME=$WNAME
export ENV=$ENV
export DB_USERNAME=$DB_USERNAME
export DB_PASSWORD=$DB_PASSWORD
export VERSIONID=$DEPLOY_VERSION
alias sql=/opt/oracle/sqlcl/bin/sql
export JAVA_HOME=/usr/bin/java
export PATH=$JAVA_HOME/bin:$PATH
export PROJECT_DIR=$PROJECT_NAME

# Log environment variables
echo "WORKSPACE: $WORKSPACE"
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "ENV: $ENV"
echo "WNAME: $WNAME"
echo "DB_USERNAME: $DB_USERNAME"
echo "DB_PASSWORD: [PROTECTED]"
echo "Release environment name selected is: $ENV"
echo "Database User id entered is: $DB_USERNAME"
echo "Version IDS that need to deplpy: $VERSIONID"

# Clean up previous files (suppress errors if files do not exist)
rm -f $WORKSPACE/*.txt $WORKSPACE/*.sql 

echo $VERSIONID | tr "," "\n" > $WORKSPACE/versionid_list.txt

# Copy the main script
cp $SCRIPT_DIR/main.sh $WORKSPACE/

# Extract SQL scripts and sequences for each VERSIONID
for i in $(cat $WORKSPACE/versionid_list.txt); do
    find $WORKSPACE/$i/$PROJECT_DIR/tables/internal -type f -name '*.sql' -print >> $WORKSPACE/internal_sql.txt
    find $WORKSPACE/$i/$PROJECT_DIR/tables/external -type f -name '*.sql' -print >> $WORKSPACE/external_sql.txt
    find $WORKSPACE/$i/$PROJECT_DIR/tables -type f -name 'internal_sequence.txt' -print >> $WORKSPACE/internal_sequence.txt
    find $WORKSPACE/$i/$PROJECT_DIR/tables -type f -name 'external_sequence.txt' -print >> $WORKSPACE/external_sequence.txt
done

echo 'VERSIONIDs for deployment and the Complete SQL scripts extracted for those VERSIONIDs'

# Collect selected internal SQL scripts based on VERSIONIDs
for i in $(cat $WORKSPACE/versionid_list.txt); do
    grep -w $i $WORKSPACE/internal_sql.txt | grep -v main.sql >> $WORKSPACE/internal_selected_sql_prop.txt
    grep -w $i $WORKSPACE/external_sql.txt | grep -v main.sql >> $WORKSPACE/external_selected_sql_prop.txt
done

# Format internal SQL scripts for deployment
for i in $(cat $WORKSPACE/internal_selected_sql_prop.txt); do
    echo $i
    printf '@%s;\n' "$i" >> $WORKSPACE/internal_formatted_sql_prop.txt
done

# Format External SQL scripts for deployment
for i in $(cat $WORKSPACE/external_selected_sql_prop.txt); do
    echo $i
    printf '@%s;\n' "$i" >> $WORKSPACE/external_formatted_sql_prop.txt
done

# Collect selected internal sequence scripts
for i in $(cat $WORKSPACE/versionid_list.txt); do
    grep -w $i $WORKSPACE/internal_sequence.txt >> $WORKSPACE/internal_selected_seq_prop.txt
done

# Collect selected external sequence scripts
for i in $(cat $WORKSPACE/versionid_list.txt); do
    grep -w $i $WORKSPACE/external_sequence.txt >> $WORKSPACE/external_selected_seq_prop.txt
done

# Process internal sequence scripts
for i in $(cat $WORKSPACE/internal_selected_seq_prop.txt); do
    cat $i | grep -v '^--' >> $WORKSPACE/sql_raw.txt
done

# Process external sequence scripts
for i in $(cat $WORKSPACE/external_selected_seq_prop.txt); do
    cat $i | grep -v '^--' >> $WORKSPACE/sql_raw.txt
done

# Remove carriage return characters from sql_raw.txt
tr -d '\r' < $WORKSPACE/sql_raw.txt > $WORKSPACE/sql_raw_cleaned.txt
mv $WORKSPACE/sql_raw_cleaned.txt $WORKSPACE/sql_raw.txt

# Prepare SQL collection for deployment
for i in $(cat $WORKSPACE/sql_raw.txt); do
    printf "PROMPT 'Deploying......%s';\n" "$i" >> $WORKSPACE/sql_collection.txt
    grep -w "$i" $WORKSPACE/internal_formatted_sql_prop.txt >> $WORKSPACE/sql_collection.txt
    grep -w "$i" $WORKSPACE/external_formatted_sql_prop.txt >> $WORKSPACE/sql_collection.txt
done

echo 'SQL Scripts to be deployed.....'
grep -v '^PROMPT' $WORKSPACE/sql_collection.txt

# Create main.sql
printf '%s\n spool main_'$today'.log' >> $WORKSPACE/main.sql
printf '%s\n set linesize 132;' >> $WORKSPACE/main.sql
printf '%s\n set serveroutput on;' >> $WORKSPACE/main.sql
printf '%s\n select * from global_name;' >> $WORKSPACE/main.sql
printf "%s\n select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from dual;%s\n" >> $WORKSPACE/main.sql
printf '%s\n set heading on;' >> $WORKSPACE/main.sql
printf '%s\n set define off;' >> $WORKSPACE/main.sql
printf "%s\n select count(1),object_type,status status_before_deployment from user_objects group by object_type,status order by 2;%s\n" >> $WORKSPACE/main.sql
printf "%s\n column invalid_obj_name format a40; %s\n" >> $WORKSPACE/main.sql
printf "%s\n column last_ddl_bef_deply format a30; %s\n" >> $WORKSPACE/main.sql
printf "%s\n select object_name invalid_obj_name ,object_type,to_char(last_ddl_time,'YYYY-MM-DD HH24:MI:SS') last_ddl_bef_deply from user_objects where status<>'VALID' order by 3;%s\n" >> $WORKSPACE/main.sql

cat $WORKSPACE/sql_collection.txt >> $WORKSPACE/main.sql

printf '%s\n set heading on;' >> $WORKSPACE/main.sql
printf '%s\n set linesize 132;' >> $WORKSPACE/main.sql
printf "%s\n set serveroutput on;" >> $WORKSPACE/main.sql
printf "%s\n
DECLARE
  CURSOR c1
      IS SELECT sys_context('USERENV', 'CURRENT_USER') cur_schema from dual;
BEGIN
  FOR c1_rec IN c1
  LOOP
    dbms_output.put_line( 'Compiling Invalid objects in schema => '||c1_rec.cur_schema );
        dbms_utility.compile_schema(c1_rec.cur_schema,FALSE);
        END LOOP;
END;
/
" >> $WORKSPACE/main.sql

printf "%s\n select count(1),object_type,status status_after_deployment from user_objects group by object_type,status order by 2;%s\n" >> $WORKSPACE/main.sql
printf "%s\n select object_name invalid_obj_name ,object_type,to_char(last_ddl_time,'YYYY-MM-DD HH24:MI:SS') last_ddl_aft_deply from user_objects where status<>'VALID' order by 3;%s\n" >> $WORKSPACE/main.sql
printf "%s\n spool off;" >> $WORKSPACE/main.sql

cp $WORKSPACE/main.sql $WORKSPACE/main_$today.sql

# Ensure sql is executed in the right directory & Execute main.sql
sql -cloudconfig $WNAME $DB_USERNAME/$DB_PASSWORD@$ENV <<EOF
set echo off
set heading off
whenever sqlerror exit sql.sqlcode;
show user;
alter session set current_schema=$PROJECT_DIR;
@$WORKSPACE/main.sql
set feedback on;
exit;
EOF
