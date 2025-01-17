-- Create schemas and set ownership
CREATE SCHEMA IF NOT EXISTS public AUTHORIZATION nhost_hasura;

CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION nhost_admin;

GRANT ALL PRIVILEGES ON SCHEMA auth TO nhost_auth_admin;

CREATE SCHEMA IF NOT EXISTS storage AUTHORIZATION nhost_admin;

GRANT ALL PRIVILEGES ON SCHEMA storage TO nhost_storage_admin;

CREATE SCHEMA IF NOT EXISTS hdb_catalog AUTHORIZATION nhost_hasura;

