DO $$
BEGIN
    IF NOT EXISTS(
        SELECT
        FROM
            pg_catalog.pg_roles
        WHERE
            rolname = 'nhost_admin') THEN
    CREATE ROLE nhost_admin WITH LOGIN SUPERUSER CREATEDB CREATEROLE REPLICATION BYPASSRLS PASSWORD ':DB_PASSWORD';
END IF;
    IF NOT EXISTS(
        SELECT
        FROM
            pg_catalog.pg_roles
        WHERE
            rolname = 'nhost_hasura') THEN
    CREATE ROLE nhost_hasura WITH LOGIN PASSWORD ':DB_PASSWORD';
    GRANT postgres TO nhost_hasura;
END IF;
    IF NOT EXISTS(
        SELECT
        FROM
            pg_catalog.pg_roles
        WHERE
            rolname = 'nhost_auth_admin') THEN
    CREATE ROLE nhost_auth_admin WITH LOGIN NOINHERIT CREATEROLE PASSWORD ':DB_PASSWORD';
    ALTER ROLE nhost_auth_admin SET search_path TO public;
END IF;
    IF NOT EXISTS(
        SELECT
        FROM
            pg_catalog.pg_roles
        WHERE
            rolname = 'nhost_storage_admin') THEN
    CREATE ROLE nhost_storage_admin WITH LOGIN NOINHERIT CREATEROLE PASSWORD ':DB_PASSWORD';
    ALTER ROLE nhost_storage_admin SET search_path TO public;
END IF;
END
$$;

