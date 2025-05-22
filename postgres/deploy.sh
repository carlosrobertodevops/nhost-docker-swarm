#!/bin/bash

# Convert docker-compose.yml to canonical form to insert env variables
docker compose -f ./postgres/docker-compose.yml convert --no-path-resolution | grep -v '^name'  > ./postgres/docker-compose.canonical.yml

# Replace quoted integers in the `published` port with unquoted integers
sed -i 's/published: "\(.*\)"/published: \1/' ./postgres/docker-compose.canonical.yml
sed -i 's/size: "\(.*\)"/size: \1/' ./postgres/docker-compose.canonical.yml

# Sync the files to the remote server using rsync
rsync -avz --delete ./postgres/ root@91.99.135.154:/root/postgres/

# Log in to the remote server and deploy the stack using docker
ssh root@91.99.135.154 << EOF
  # Navigate to the folder where the docker-compose.yml is located
  cd /root/postgres/

  # Deploy the stack using docker stack deploy
  docker stack deploy -c ./postgres/docker-compose.canonical.yml postgres-stack --resolve-image always --detach

  # Find the running PgBouncer container
  PGB_CONTAINER_ID=\$(docker ps -q --filter "name=postgres-stack_pgbouncer")

  if [ -n "\$PGB_CONTAINER_ID" ]; then
    # Send SIGHUP to PgBouncer to reload the configuration (removed -t for TTY)
    docker exec -i \$PGB_CONTAINER_ID pgbouncer -R /etc/pgbouncer/pgbouncer.ini
    echo "PgBouncer reloaded"
  else
    echo "PgBouncer container not found"
  fi
EOF