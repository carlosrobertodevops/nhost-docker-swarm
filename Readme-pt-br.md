# Hospedagem própria do Nhost com o Docker Swarm

Execute o Nhost em seu próprio servidor. Útil se você tiver aplicativos com uso intensivo de dados que atingem rapidamente os limites do Nhost no serviço gerenciado. Você também pode ter vários aplicativos Nhost usando o mesmo banco de dados nesta configuração, caso tenha muitos projetos pequenos pelos quais não queira pagar a mais.

A hospedagem própria não é impossível, mas é mais difícil e você terá mais problemas do que usar o serviço gerenciado do Nhost. Esperamos que este modelo de configuração facilite isso.

Esta configuração foi projetada para facilitar ao máximo o uso com o fluxo normal de desenvolvimento do Nhost. Você não usa o Docker em seu computador de desenvolvimento, apenas usa a CLI do Nhost e os modelos existentes para implantar.

## Configuração

### Domínios
Configure todos os domínios com o seu domínio. Você precisa atualizar seus registros DNS com seu provedor de DNS. O Traefik nesta pilha cuidará da criação de certificados SSL.
Observe que você não pode usar proxy com o Cloudflare se usar subdomínios aninhados, por exemplo. hasura.myapp.mydomain.com. Use hasura-myapp.mydomain.com no Cloudflare.

### Senhas
Edite os arquivos .env com seu segredo JWT, segredo Hasura, etc.
Você precisa escolher uma senha forte para o banco de dados em produção. Gere uma string aleatória com `tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 64; echo`
As conexões com o banco de dados são feitas através do pgbouncer, o que requer mais configuração. Edite postgres/pgbouncer-config/pgbouncer.ini e postgres/pgbouncer-config/userlist.txt para corresponder às suas conexões com o banco de dados e usuários.
Conexões feitas internamente no servidor podem usar nomes de contêineres do Docker em vez de IPs ou nomes de domínio.
Exemplo `app1 = host=postgres port=5432 dbname=app1 user=postgres password=randompassword` o host é postgres porque esse é o nome do contêiner no Docker.
O Pgbouncer está na porta 6432 por padrão, enquanto o Postgres está na porta 5432. Nesta configuração, o Postgres não é a internet aberta, mas o pgbouncer é. Ajuste as variáveis ​​de ambiente e as redes do Docker se precisar de algo mais.
O SSL não está configurado para o Postgres, portanto, tenha cuidado ao conectar-se ao banco de dados se fizer isso do seu computador.

## Pilhas do Docker

O projeto consiste em várias "pilhas" no Docker Swarm. Elas são implantadas com um script bash. Acesse a pasta raiz do projeto e execute algo como `./traefik-proxy/deploy.sh`. Cada pilha tem algumas variáveis ​​de ambiente que você precisa definir.

### postgres

Na pasta postgres, o postgres e o pgbouncer são configurados. Eles são necessários para o Nhost, mas podem estar em seus próprios servidores. Você também pode pular esta pilha se usar o Postgres gerenciado pela Neon ou outro provedor.

Existe um script para criar um novo "banco de dados" dentro do Postgres e prepará-lo para o Nhost. Útil se você tiver vários aplicativos Nhost que usam a mesma instância do Postgres. Outro arquivo SQL cria um novo usuário monitor sem privilégios, que só pode ser usado para testar a conexão no Kuma.

### nhost

A pilha do Nhost é composta por Hasura, Autenticação do Nhost e Armazenamento do Nhost. Essa pilha não possui estado e pode ser replicada entre servidores sem problemas.
O armazenamento é opcional, pois você pode usar o Nhost sem usar o armazenamento do Nhost, mas ele está configurado corretamente. Esta configuração não inclui seu próprio Minio, então você precisa configurá-lo ou usar Amazon S3, Cloudflare R2 ou similar.
Para a autenticação do Nhost, você precisa garantir que os modelos de e-mail estejam montados corretamente. Isso é feito pelo rsync nesta configuração.
Para Hasura, você precisa fazer migrações e atualizar metadados manualmente (ou criar um script, se desejar). Basta usar o cliente Hasura e executar `hasura migrate apply --admin-secret ADMIN_SECRET --database-name default --endpoint hasura-app1.mydomain.com` e `hasura metadata apply --admin-secret ADMIN_SECRET --endpoint hasura-app1.mydomain.com`. Esteja na pasta nhost ao fazer isso, e suas alterações locais serão aplicadas à produção.

Este modelo não implementa funções do Nhost, pois já tive muitos problemas ao usá-las. Você provavelmente deve adicionar outro serviço de API, como um aplicativo Node Express ou um aplicativo Python FastAPI, para suas necessidades de computação. Como alternativa, use o AWS Lambda ou similar.

### traefik-proxy

Este é o ponto de entrada para todas as conexões http com o servidor. O Traefik é um proxy reverso que mapeia nomes de domínio para o contêiner Docker correto. Ele também configura certificados SSL automaticamente com o Let's Encrypt. O Traefik também possui outros recursos, como limitação de taxa, mas não está configurado aqui.

Você pode ver um painel do Traefik se definir o domínio como, por exemplo, traefik-nhost.mydomain.com.

Cada serviço/contêiner que deve ser acessado pela internet precisa adicionar alguns rótulos para que o Traefik os roteie automaticamente. Exemplo
```yaml
# docker-compose.yml in nhost folder for Hasura
deploy: 
    labels:
        - traefik.enable=true
        - traefik.http.routers.hasura-app1.rule=Host(`${HASURA_DOMAIN}`)
        - traefik.http.routers.hasura-app1.entrypoints=https
        - traefik.http.routers.hasura-app1.tls.certresolver=letsencrypt
        - traefik.http.services.hasura-app1.loadbalancer.server.port=8080
```

Lembre-se de atualizar o nome do roteador e do serviço nos rótulos aqui ao copiá-lo de um serviço para outro. Muitas vezes esqueço de fazer isso, e isso faz com que o Traefik não encontre meus serviços.

portainer (e kuma)
O Portainer é um painel para o seu Docker Swarm. Ele permite que você visualize contêineres, servidores, volumes etc. no navegador, sem usar o Docker diretamente com SSH no servidor.

O Kuma é um monitor de tempo de atividade. Seu uso é totalmente opcional, mas é bom ser notificado se algo der errado, mesmo que você não deva executar o monitor de tempo de atividade no mesmo servidor que está monitorando.

Servidor
Você obviamente precisa de um servidor para implantar. Ele precisa ter o Docker instalado e a chave SSH pública de um SSH que você tenha no seu computador.

Após iniciar o servidor, acesse-o via SSH e habilite o Docker Swarm com o comando docker swarm init, crie a rede docker network create --driver overlay traefik-public e o volume docker volume create postgres_data.

Você pode usar este cloud-init em servidores Hetzner, Vultr e outros que suportem cloud-init:

#cloud-config
package_update: true
package_upgrade: true
packages:
- apt-transport-https
- ca-certificates
- curl
- software-properties-common
- gnupg
- lsb-release
- fail2ban

runcmd:
- for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; concluído
- instalar -m 0755 -d /etc/apt/keyrings
- curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
- chmod a+r /etc/apt/keyrings/docker.asc
- echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") estável" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
- apt-get update
- apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
- groupadd docker
- usermod -aG docker $USER
- systemctl enable docker
- systemctl start docker
#- docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')

- curl -fsSL https://azlux.fr/repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/azlux-archive-keyring.gpg
- echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azlux.list >/dev/null

- ufw allow OpenSSH
- ufw allow 2376/tcp # Docker
- ufw allow 2377/tcp # Docker Swarm
- ufw allow 7946/tcp # Docker Swarm
- ufw allow 7946/udp # Docker Swarm
- ufw allow 4789/udp # Docker Swarm
- ufw allow 443/tcp # HTTPS
- ufw allow 80/tcp # HTTP
- ufw allow 6432/tcp # PgBouncer
- ufw allow 9001/tcp # Portainer
- ufw --force enable
- systemctl restart docker
- systemctl enable fail2ban
- systemctl start fail2ban

write_files:
- caminho: /etc/docker/daemon.json
conteúdo: |
{
"log-driver": "json-file",
"log-opts": {
"max-size": "10m",
"max-file": "3"
},
"mtu": 1450
}
- caminho: /etc/motd
conteúdo: |
Bem-vindo ao seu nó gerenciador do Docker Swarm!
- Versão do Docker: $(docker --version)
- Inicialização do Swarm: Sim

- caminho: /etc/cron.weekly/docker-cleanup
permissões: '0755'
conteúdo: |
#!/bin/bash
docker container prune -f
docker image prune -f
Adicionar mais aplicativos Nhost
Se você configurar o Traefik, o Postgres e, opcionalmente, o Portainer, poderá usá-los para muitos aplicativos Nhost. Basta configurar o conteúdo da pasta nhost com as variáveis ​​de ambiente e os rótulos de implantação corretos.

Migrar aplicativos Nhost
Você precisa instalar postgresql-client-common e postgresql-client para usar pg_dump e pg_restore. Você pode fazer isso do seu computador, mas o dump pode ser grande, então você também pode fazer isso do seu servidor.

pg_dump -h nhostsubdomain.db.eu-central-1.nhost.run -U postgres -p 5432 -d nhostsubdomain -F c -f ./mydb-backup/backup.dump

pg_restore -h your.server.ip -U postgres -p 6432 -d your_app_database_name -F c --clean ./mydb-backup-backup/backup.dump

Observe que você deve executar todas as migrações do Hasura antes de fazer isso. O banco de dados também precisa ser configurado com os usuários e proprietários de tabela corretos.

Haverá uma "lacuna" nos dados durante a migração dessa forma, portanto, programe-a para um período de inatividade caso tenha muitos usuários.

A replicação contínua é possível no Postgres, mas não temos controle suficiente sobre o banco de dados no Nhost gerenciado para isso.

Leia mais
Se não tiver certeza, leia e tente entender os diversos arquivos docker-compose e de configuração. Pergunte ao ChatGPT ou pesquise na internet para aprender informações úteis sobre hospedagem própria.
