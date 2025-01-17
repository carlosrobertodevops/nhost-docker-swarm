#!/bin/bash

PG_CONTAINER_ID=$1
DB_NAME=$2
DB_PASSWORD=$3


if [ -z "$DB_NAME" ]; then
  echo "Please provide a database name."
  exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
  echo "Please provide a database password."
  exit 1
fi

if [ -z "$PG_CONTAINER_ID" ]; then
  echo "Please provide a container ID."
  exit 1
fi


# Replace placeholders in the SQL files with environment variables
sed "s/:DB_NAME/$DB_NAME/g" db.sql | docker exec -i $PG_CONTAINER_ID psql -U postgres
echo "Executed db.sql"

# Check if the database creation was successful
if [ $? -ne 0 ]; then
  echo "Failed to create the database $DB_NAME."
  exit 1
fi

# Execute the rest of the SQL files on the new database
for sql_file in roles.sql schemas.sql extensions.sql permissions.sql functions.sql; do
  sed -e "s/:DB_PASSWORD/$DB_PASSWORD/g" -e "s/:DB_NAME/$DB_NAME/g" $sql_file | docker exec -i $PG_CONTAINER_ID psql -U postgres -d $DB_NAME
  echo "Executed $sql_file"
done

cat update-extensions.sql | docker exec -i $PG_CONTAINER_ID psql -U postgres -d $DB_NAME -X
echo "Executed update-extensions.sql"