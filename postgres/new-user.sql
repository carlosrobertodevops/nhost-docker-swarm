-- Create a dummy monitoring user with a password
CREATE USER monitor_user WITH PASSWORD '653zsB5KmQgrf1GqyABX2V81H7pfOtVA';

-- Grant the user permission to connect to the database (replace 'your_database' if needed)
GRANT CONNECT ON DATABASE postgres TO monitor_user;

-- Grant the user permission to use the public schema
GRANT USAGE ON SCHEMA public TO monitor_user;

-- Revoke all access to tables in the public schema
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM monitor_user;

-- Allow the user to execute trivial queries like 'SELECT 1;'
GRANT EXECUTE ON FUNCTION pg_catalog.pg_sleep TO monitor_user;
