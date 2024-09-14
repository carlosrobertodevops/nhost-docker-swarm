#!/bin/bash

PG_CONTAINER_ID=$1
DB_NAME=$2

# First, run the CREATE DATABASE command
cat << EOF | docker exec -i $PG_CONTAINER_ID psql -U postgres

-- Try to create the database; it will error if it already exists, which is fine
CREATE DATABASE $DB_NAME;

EOF

# Now connect to the newly created database (or existing one) and run the rest of the commands
cat << EOF | docker exec -i $PG_CONTAINER_ID psql -U postgres -d $DB_NAME

-- Create schemas if they don't exist
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;

-- Enable extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS hypopg WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


-- Create a function to update the timestamp
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at() 
RETURNS trigger LANGUAGE plpgsql AS \$\$
BEGIN 
    NEW."updated_at" := now();
    RETURN NEW;
END
\$\$;

EOF
