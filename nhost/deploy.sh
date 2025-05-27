#!/bin/bash

# APP_NAME=$1

# # Exit if not provided
# if [ -z "$APP_NAME" ]; then
#   echo "Please provide an app name"
#   exit 1
# fi


# Convert docker-compose.yml to canonical form to insert env variables
docker compose -f docker-compose.yml convert --no-path-resolution | grep -v '^name'  > docker-compose.canonical.yml

# Sync the files to the remote server using rsync
# rsync -avz --delete ./nhost/ root@91.99.128.127:/root/nhost-$APP_NAME/


# # Log in to the remote server and deploy the stack using docker
# ssh root@91.99.128.127 << EOF
#   # Navigate to the folder where the docker-compose.yml is located
#   cd /root/nhost-$APP_NAME/

#   # Deploy the stack using docker stack deploy
docker stack deploy -c docker-compose.canonical.yml nhost-$APP_NAME-stack --detach --resolve-image always
# EOF



# ORIGINAL

# APP_NAME=$1

# # Exit if not provided
# if [ -z "$APP_NAME" ]; then
#   echo "Please provide an app name"
#   exit 1
# fi


# # Convert docker-compose.yml to canonical form to insert env variables
# docker compose -f ./nhost/docker-compose.yml convert --no-path-resolution | grep -v '^name'  > ./nhost/docker-compose.canonical.yml

# # Sync the files to the remote server using rsync
# rsync -avz --delete ./nhost/ root@199.199.199.199:/root/nhost-$APP_NAME/


# # Log in to the remote server and deploy the stack using docker
# ssh root@199.199.199.199 << EOF
#   # Navigate to the folder where the docker-compose.yml is located
#   cd /root/nhost-$APP_NAME/

#   # Deploy the stack using docker stack deploy
#   docker stack deploy -c docker-compose.canonical.yml nhost-$APP_NAME-stack --detach --resolve-image always
# EOF
