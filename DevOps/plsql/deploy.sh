#!/bin/bash

# Load configuration JSON
config_file=".github/config/config.yaml"
release_version=$(jq -r '.release_version' "$config_file")
projects=$(jq -c '.projects[]' "$config_file")

# Set up the environment variables
export JAVA_HOME=/usr/bin/java
export PATH=$JAVA_HOME/bin:$PATH
alias sql=/opt/oracle/sqlcl/bin/sql
today=$(date +%Y-%m-%d-%H-%M-%S)
export WORKSPACE=$WORKSPACE
export SCRIPT_DIR=$SCRIPT_DIR
export WNAME=$WNAME
export ENV=$ENV
export DB_USERNAME=$DB_USERNAME
export DB_PASSWORD=$DB_PASSWORD
export VERSIONID=$DEPLOY_VERSION
export PROJECT_DIR=$PROJECT_NAME


# Start deployment
echo "Starting deployment for release version: $release_version"

# Loop through each project schema in the JSON
for project in $projects; do
  schema_name=$(echo "$project" | jq -r '.name')
  internal_path=$(echo "$project" | jq -r '.paths.internal')
  external_path=$(echo "$project" | jq -r '.paths.external')

  echo "Deploying for schema: $schema_name"
  echo "Internal path: $internal_path"
  echo "External path: $external_path"

  # Fetch and format SQL scripts
  internal_sql_files=$(find "$internal_path" -type f -name '*.sql')
  external_sql_files=$(find "$external_path" -type f -name '*.sql')

  # Create deployment SQL file for the schema
  main_sql_file="main_${schema_name}_${release_version}.sql"
  printf "spool ${main_sql_file}.log\n" > $main_sql_file

  # Loop through and add internal SQL files
  for sql_file in $internal_sql_files; do
    echo "Adding internal SQL: $sql_file"
    printf "@%s;\n" "$sql_file" >> $main_sql_file
  done

  # Loop through and add external SQL files
  for sql_file in $external_sql_files; do
    echo "Adding external SQL: $sql_file"
    printf "@%s;\n" "$sql_file" >> $main_sql_file
  done

  # Finalize the main SQL file with compilation commands
  printf "COMMIT;\nspool off;\n" >> $main_sql_file

  # Execute the deployment SQL
  echo "Executing SQL deployment for schema: $schema_name"
  sql -cloudconfig $WNAME $DB_USERNAME/$DB_PASSWORD@$ENV <<EOF
    set echo off;
    set heading off;
    @$main_sql_file;
    exit;
EOF
done

echo "Deployment completed for release version: $release_version"
