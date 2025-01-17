-- Grant privileges on the database
GRANT ALL PRIVILEGES ON DATABASE :DB_NAME TO nhost_hasura;

-- Grant usage on schemas to nhost_hasura
GRANT USAGE ON SCHEMA public TO nhost_hasura;

GRANT USAGE ON SCHEMA auth TO nhost_hasura;

GRANT USAGE ON SCHEMA storage TO nhost_hasura;

-- Grant select on system schemas
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO nhost_hasura;

GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO nhost_hasura;

-- Grant all on public schema to nhost_hasura
GRANT ALL ON ALL TABLES IN SCHEMA public TO nhost_hasura;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO nhost_hasura;

GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO nhost_hasura;

-- Set default privileges for nhost_auth_admin
ALTER DEFAULT PRIVILEGES FOR ROLE nhost_auth_admin IN SCHEMA auth GRANT ALL ON TABLES TO nhost_hasura;

ALTER DEFAULT PRIVILEGES FOR ROLE nhost_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES TO nhost_hasura;

ALTER DEFAULT PRIVILEGES FOR ROLE nhost_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS TO nhost_hasura;

-- Set default privileges for nhost_storage_admin
ALTER DEFAULT PRIVILEGES FOR ROLE nhost_storage_admin IN SCHEMA storage GRANT ALL ON TABLES TO nhost_hasura;

ALTER DEFAULT PRIVILEGES FOR ROLE nhost_storage_admin IN SCHEMA storage GRANT ALL ON SEQUENCES TO nhost_hasura;

ALTER DEFAULT PRIVILEGES FOR ROLE nhost_storage_admin IN SCHEMA storage GRANT ALL ON FUNCTIONS TO nhost_hasura;

-- Grant usage and create on hdb_catalog
GRANT USAGE, CREATE ON SCHEMA hdb_catalog TO nhost_auth_admin, nhost_storage_admin;

GRANT ALL ON ALL TABLES IN SCHEMA hdb_catalog TO nhost_auth_admin, nhost_storage_admin;

GRANT ALL ON ALL SEQUENCES IN SCHEMA hdb_catalog TO nhost_auth_admin, nhost_storage_admin;

GRANT ALL ON ALL FUNCTIONS IN SCHEMA hdb_catalog TO nhost_auth_admin, nhost_storage_admin;

-- Set default privileges in hdb_catalog
ALTER DEFAULT PRIVILEGES IN SCHEMA hdb_catalog GRANT ALL ON TABLES TO nhost_auth_admin, nhost_storage_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA hdb_catalog GRANT ALL ON SEQUENCES TO nhost_auth_admin, nhost_storage_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA hdb_catalog GRANT ALL ON FUNCTIONS TO nhost_auth_admin, nhost_storage_admin;

