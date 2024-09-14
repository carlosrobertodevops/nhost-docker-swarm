#!/bin/bash

# Convert docker-compose.yml to canonical form to insert env variables
docker compose -f ./portainer/docker-compose.yml convert --no-path-resolution | grep -v '^name'  > ./portainer/docker-compose.canonical.yml

# Sync the files to the remote server using rsync
rsync -avz --delete ./portainer/ root@your.server.ip:/root/portainer/

# Log in to the remote server and deploy the stack using docker
ssh root@your.server.ip << 'EOF'
  # Navigate to the folder where the docker-compose.canonical.yml is located
  cd /root/portainer/

  # Deploy the stack using docker stack deploy --resolve-image always
  docker stack deploy -c docker-compose.canonical.yml portainer-stack
EOF
