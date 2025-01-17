#!/bin/sh

# /bin/init.sh from nhost/postgres:16.4-20240909-1

set -euo pipefail

function init_db() {
    DATABASE_INITALIZED=false
    if [ ! -f $PGDATA/PG_VERSION ]; then
        echo "Initializing database"
        eval 'initdb --username="$POSTGRES_USER" --pwfile=<(printf "%s\n" "$POSTGRES_PASSWORD")'
        DATABASE_INITALIZED=true
    fi
    export DATABASE_INITALIZED
}

function resolve_config() {
    echo "Resolving pg_hba.conf and postgresql.conf"
    POSTGRES_DEV_INSECURE=${POSTGRES_DEV_INSECURE:-}
    if [[ -n "$POSTGRES_DEV_INSECURE" ]]; then
        PG_HBA_CONF_TMPL=/etc/pg_hba_insecure.conf.tmpl
    else
        PG_HBA_CONF_TMPL=/etc/pg_hba.conf.tmpl
    fi
    envsubst < "$PG_HBA_CONF_TMPL" > $PGDATA/pg_hba.conf
    envsubst < /etc/postgresql.conf.tmpl > $PGDATA/postgresql.conf
}

function start_postgres() {
    echo "Starting postgres"
    chmod u=rwx,g=rx $PGDATA
    postgres \
        -h 0.0.0.0 \
        -p 5432 \
        -c config_file="$PGDATA/postgresql.conf" \
        -c hba_file="$PGDATA/pg_hba.conf" &

    echo "Waiting for postgres to start"
    # wait for postgres to start
    while ! pg_isready -q -h localhost -p 5432 -U postgres; do
      sleep 0.1
    done
}

function delete_core_dumps() {
    while true; do
        find "$PGDATA" -type f -name "core.*" -exec rm -f {} \;
        sleep 60
    done
}

function run_init_scripts() {
    echo "Running init scripts"
    psql --dbname postgres -c "CREATE DATABASE $POSTGRES_DB;"

    mkdir -p /tmp/postgresql/initdb.d
    for f in /initdb.d/*; do
        envsubst < "$f" > /tmp/postgresql/initdb.d/$(basename $f)
        psql -q -b -U postgres -d $POSTGRES_DB --no-psqlrc -f /tmp/postgresql/initdb.d/$(basename $f)
    done
}

function run_nhost_scripts() {
    echo "Running nhost's scripts"

    mkdir -p /tmp/postgresql/nhost.d
    for f in /nhost.d/*; do
        envsubst < "$f" > /tmp/postgresql/nhost.d/$(basename $f)
        psql -q -b -U postgres -d $POSTGRES_DB --no-psqlrc -f /tmp/postgresql/nhost.d/$(basename $f)
    done
}



function main() {
    init_db
    resolve_config
    start_postgres

    if [ "$DATABASE_INITALIZED" = true ]; then
        run_init_scripts
    fi
    run_nhost_scripts

    delete_core_dumps &

    sleep infinity
}

main
