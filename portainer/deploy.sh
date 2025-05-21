#!/bin/bash

# Convert docker-compose.yml to canonical form to insert env variables
docker compose -f ./portainer/docker-compose.yml convert --no-path-resolution | grep -v '^name'  > ./portainer/docker-compose.canonical.yml

# Replace quoted integers in the `published` port with unquoted integers
sed -i 's/published: "\(.*\)"/published: \1/' ./portainer/docker-compose.canonical.yml

# # Sync the files to the remote server using rsync
# rsync -avz --delete ./portainer/ root@199.199.199.199:/root/portainer/

# # Log in to the remote server and deploy the stack using docker
# ssh root@199.199.199.199 << 'EOF'
#   # Navigate to the folder where the docker-compose.canonical.yml is located
#   cd /root/portainer/

#   # Loki user needs to be the owner of these folders
#   chown -R 10001:10001 ./loki_data
#   chmod -R 755 ./loki_data

#   # Deploy the stack using docker stack deploy --resolve-image always 
#   docker stack deploy -c docker-compose.canonical.yml portainer-stack --resolve-image always --detach
# EOF
