#!/bin/bash

# Convert docker-compose.yml to canonical form to insert env variables
docker compose -f ./traefik-proxy/docker-compose.yml convert --no-path-resolution | grep -v '^name'  > ./traefik-proxy/docker-compose.canonical.yml

# Replace quoted integers in the `published` port with unquoted integers
sed -i 's/published: "\(.*\)"/published: \1/' ./traefik-proxy/docker-compose.canonical.yml

# Sync the files to the remote server using rsync
rsync -avz --delete ./traefik-proxy/ root@your.server.ip:/root/traefik-proxy/

# Log in to the remote server and deploy the stack using docker
ssh root@your.server.ip << 'EOF'
  # Navigate to the folder where the docker-compose.canonical.yml is located
  cd /root/traefik-proxy/

  # Deploy the stack using docker stack deploy --resolve-image always
  docker stack deploy -c docker-compose.canonical.yml traefik-stack
EOF
