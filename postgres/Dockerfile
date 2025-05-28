FROM nhost/postgres:16.4-20240909-1

COPY init.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/init.sh