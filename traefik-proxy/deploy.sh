#!/bin/bash

# Convert docker-compose.yml to canonical form to insert env variables
# docker compose -f docker-compose.yml convert --no-path-resolution | grep -v '^name'  > docker-compose.canonical.yml

# Replace quoted integers in the `published` port with unquoted integers
# sed -i 's/published: "\(.*\)"/published: \1/' docker-compose.canonical.yml

# Sync the files to the remote server using rsync
# rsync -avz --delete ./traefik-proxy/ root@91.99.128.127:/root/nhost-docker-swarm/traefik-proxy

# # Log in to the remote server and deploy the stack using docker
# ssh root@91.99.128.127 << 'EOF'
#   # Navigate to the folder where the docker-compose.canonical.yml is located
#   cd /root/nhost-docker-swarm/traefik-proxy

#   # Deploy the stack using docker stack deploy --resolve-image always
docker stack deploy -c docker-compose.canonical.yml traefik-stack --resolve-image always --detach
#EOF


# ORIGINAL

# # Convert docker-compose.yml to canonical form to insert env variables
# docker compose -f ./traefik-proxy/docker-compose.yml convert --no-path-resolution | grep -v '^name'  > ./traefik-proxy/docker-compose.canonical.yml

# # Replace quoted integers in the `published` port with unquoted integers
# sed -i 's/published: "\(.*\)"/published: \1/' ./traefik-proxy/docker-compose.canonical.yml

# # Sync the files to the remote server using rsync
# rsync -avz --delete ./traefik-proxy/ root@199.199.199.199:/root/traefik-proxy/

# # Log in to the remote server and deploy the stack using docker
# ssh root@199.199.199.199 << 'EOF'
#   # Navigate to the folder where the docker-compose.canonical.yml is located
#   cd /root/traefik-proxy/

#   # Deploy the stack using docker stack deploy --resolve-image always
#   docker stack deploy -c docker-compose.canonical.yml traefik-stack --resolve-image always --detach
# EOF
