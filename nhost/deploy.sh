#!/bin/bash

APP_NAME=$1

# Exit if not provided
if [ -z "$APP_NAME" ]; then
  echo "Please provide an app name"
  exit 1
fi


# Convert docker-compose.yml to canonical form to insert env variables
docker compose -f ./nhost/docker-compose.yml convert --no-path-resolution | grep -v '^name'  > ./nhost/docker-compose.canonical.yml

# Sync the files to the remote server using rsync
rsync -avz --delete ./nhost/ root@your.server.ip:/root/nhost-$APP_NAME/


# Log in to the remote server and deploy the stack using docker
ssh root@your.server.ip << EOF
  # Navigate to the folder where the docker-compose.yml is located
  cd /root/nhost-$APP_NAME/

  # Deploy the stack using docker stack deploy
  docker stack deploy -c docker-compose.canonical.yml nhost-$APP_NAME-stack --resolve-image always
EOF
