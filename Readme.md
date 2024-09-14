# Self host Nhost with Docker Swarm

Run Nhost on your own server. Useful if you have data-intensive apps that quickly reach Nhost's limits in the managed service. You can also have several Nhost apps using the same database in this setup, if you have many small projects you don't wanna pay extra for.

Self-hosting is not impossible, but it is harder and you will have more problems than using Nhost's managed service. Hopefully this setup template will make it easier.

This setup is designed to make it as easy as possible to use with normal Nhost development flow. You don't use docker on your development computer, only use the nhost cli, and the existing templates to deploy.

## Config


### Domains
Set up all the domains with your domain. You need to update your DNS records with your DNS provider. Traefik in this stack will handle making SSL certificates.
Note that you cannot proxy with Cloudflare if you use nested subdomains, e.g. hasura.myapp.mydomain.com. Use hasura-myapp.mydomain.com on Cloudflare.

### Passwords
Edit the .env files with your JWT secret, Hasura secret etc.
You need to choose a strong db password for production. Generate a random string with `tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 64; echo`
Database connections are done through pgbouncer which requires more setup. Edit postgres/pgbouncer-config/pgbouncer.ini and postgres/pgbouncer-config/userlist.txt to match your database connections and users.
Connections done internally on the server can use Docker container names instead of ips or domain names.
Example `app1 = host=postgres port=5432 dbname=app1 user=postgres password=randompassword` the host is postgres because that's the container name in Docker. 
Pgbouncer is on port 6432 by default while Postgres is on port 5432. In this setup, Postgres is not the open internet, but pgbouncer is. Adjust env variables and docker networks if you need something else.
SSL is not setup for Postgres, so connect to the db with caution if you do it from your computer.


## Docker Stacks

The project consists of several "stacks" in Docker Swarm. They are deployed with a bash script. Be in the project root folder and run something like `./traefik-proxy/deploy.sh`. Each stack has some env variables you need to set.

### postgres

In the postgres folder postgres and pgbouncer are configured. These are necessary for Nhost, but could live on their own server. You can also skip this stack if you use managed Postgres by Neon or other provider.

There is one script for creating a new "database" within postgres and makes it ready for Nhost. Useful if you have several Nhost apps that use the same Postgres instance. Another sql file makes a new monitor with no privileges, that can only be used to test the connection in Kuma.


### nhost

The nhost stack is Hasura, Nhost Auth and Nhost Storage. This stack is stateless and can be replicated across servers without any issue.
Storage is optional, as you can use Nhost without using Nhost storage, but it is correctly configured. This setup does not include its own Minio, so you need to set that up or use Amazon S3, Cloudflare R2 or similar.
For Nhost auth, you need to make sure the email templates are mounted correctly. This is done by rsync in this setup.
For Hasura, you need to do migrations and update metadata manually (or make a script if you want). Just use the Hasura client and do `hasura migrate apply --admin-secret ADMIN_SECRET --database-name default --endpoint hasura-app1.mydomain.com` and `hasura metadata apply --admin-secret ADMIN_SECRET --endpoint hasura-app1.mydomain.com`. Be in the nhost folder when you do this, and it will apply your local changes to production.

This template does not implement Nhost functions as I've had many problems using them before. You should probably just add another api service like a Node Express app or Python FastAPI app for your computing needs. Alternatively use AWS Lambda or similar.


### traefik-proxy

This is the entrypoint for all http connections to the server. Traefik is a reverse proxy that maps domain names to the correct Docker container. It also automatically sets up SSL certificates with Let's Encrypt. Traefik also has other features like rate limiting, but it's not configured here.
You can see a Traefik dashboard if you set the domain to for example traefik-nhost.mydomain.com.

Each service/container that should be reached from the internet needs to add some labels for Traefik to automatically route them. Example
```yaml
# docker-compose.yml in nhost folder for Hasura
deploy: 
    labels:
        - traefik.enable=true
        - traefik.http.routers.hasura.rule=Host(`${HASURA_DOMAIN}`)
        - traefik.http.routers.hasura.entrypoints=https
        - traefik.http.routers.hasura.tls.certresolver=letsencrypt
        - traefik.http.services.hasura.loadbalancer.server.port=8080
```


### portainer (and kuma)

Portainer is a dashboard for your Docker Swarm. It allows you to see containers, servers, volumes etc in the browser, without using Docker directly with ssh on the server.

Kuma is an uptime monitor. It's completely optional to use it, but it's good to be notified if anything goes wrong, even though you're maybe not supposed to run the uptime monitor on the same server as what you're monitoring.


## Server

You obviously need a server to deploy to. It needs to have docker installed and the public ssh key of a ssh you have on your computer.

After you start the server, ssh into it and enable docker swarm with `docker swarm init`, create the network `docker network create traefik-public` and volume `docker volume create postgres_data`.


You can use this cloud-init on Hetzner, Vultr and other server providers that supports cloud-init:

```yaml
#cloud-config
package_update: true
package_upgrade: true

runcmd:
  # 1. Install necessary packages and Docker dependencies
  - apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg-agent \
    lsb-release

  # 2. Add Docker's official GPG key and repository
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  - add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -cs) stable"

  # 3. Install Docker CE, Docker CLI, and containerd
  - apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

  # 4. Add the 'docker' group and current user to the group (if using non-root user)
  - usermod -aG docker $USER

  # 5. Enable and start Docker service
  - systemctl enable docker
  - systemctl start docker

  # 6. Set up Docker Swarm (initiate manager node)
  - docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')

  # 7. Configure UFW firewall to allow necessary ports for Docker Swarm
  - ufw allow OpenSSH
  - ufw allow 2376/tcp  # Docker daemon
  - ufw allow 2377/tcp  # Docker Swarm cluster management
  - ufw allow 7946/tcp  # Docker Swarm node communication
  - ufw allow 7946/udp  # Docker Swarm node communication
  - ufw allow 4789/udp  # Docker Swarm overlay network
  - ufw allow 443/tcp   # HTTPS traffic (optional, if using Traefik or another proxy)
  - ufw allow 80/tcp    # HTTP traffic (optional, if using Traefik or another proxy)
  - ufw allow 6432/tcp    # If you want to connect to pgbouncer from the internet
  - ufw --force enable

  # 8. Enable Docker Swarm configuration and logging (create default directory for persistent logs)
  - mkdir -p /var/log/docker
  - touch /var/log/docker/docker.log
  - echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m", "max-file": "3"}}' > /etc/docker/daemon.json

  # 9. Restart Docker to apply logging configuration
  - systemctl restart docker

  # 10. Install and configure fail2ban for SSH security
  - apt-get install -y fail2ban
  - systemctl enable fail2ban
  - systemctl start fail2ban

# 11. Add a MOTD for Docker Swarm
write_files:
  - path: /etc/motd
    content: |
      Welcome to your Docker Swarm manager node!
      - Docker version: $(docker --version)
      - Swarm initialized: Yes

# 12. (Optional) Automatically clean up unused Docker resources weekly
  - path: /etc/cron.weekly/docker-cleanup
    permissions: '0755'
    content: |
      #!/bin/bash
      docker system prune -af

```


## Add more Nhost apps

If you set up Traefik, the Postgres and optionally portainer, you can use these for many Nhost apps. Just set up what's inside the nhost folder with the correct env variables and deploy labels.


## Migrate Nhost apps 
Coming


## Read more

If you're uncertain, read and try to understand the various docker-compose files and config files. Ask ChatGPT or read on the internet to learn useful stuff about self hosting.
