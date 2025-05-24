# Guia Passo a Passo para Hospedagem Própria do Nhost com Docker Swarm na Hetzner

## Pré-requisitos
- Conta na Hetzner Cloud
- Domínio registrado com acesso ao painel DNS
- Conhecimento básico de Docker e linha de comando

## Passo 1: Configurar o Servidor na Hetzner

1. **Criar um novo servidor**:
   - Escolha uma instância adequada (recomendado pelo menos CX31 para produção)
   - Selecione Ubuntu 22.04 LTS como sistema operacional
   - Na seção "Cloud-init", cole o script fornecido no artigo

2. **Configurar segurança**:
   - Adicione sua chave SSH
   - Habilite o firewall na Hetzner (opcional, já que o cloud-init configura UFW)

3. **Iniciar o servidor** e aguardar a conclusão da instalação

## Passo 2: Configuração Inicial via SSH

1. Conecte-se ao servidor via SSH:
   ```bash
   ssh root@seu-ip
   ```

2. Inicialize o Docker Swarm:
   ```bash
   docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
   ```

3. Crie a rede necessária:
   ```bash
   docker network create --driver overlay traefik-public
   ```

4. Crie o volume para PostgreSQL:
   ```bash
   docker volume create postgres_data
   ```

## Passo 3: Configurar DNS

1. Para cada subdomínio necessário (hasura, auth, storage, etc.):
   - Crie um registro A apontando para o IP do seu servidor
   - Desative o proxy do Cloudflare se estiver usando subdomínios aninhados

## Passo 4: Preparar Arquivos de Configuração

1. Clone o repositório com os arquivos de configuração ou crie a estrutura de pastas:
   ```
   /traefik-proxy/
   /postgres/
   /nhost/
   ```

2. **Gerar senhas seguras**:
   ```bash
   tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 64; echo
   ```

3. Edite os arquivos `.env` em cada pasta com suas configurações:
   - `JWT_SECRET`
   - `HASURA_GRAPHQL_ADMIN_SECRET`
   - Senhas do banco de dados

4. Configure o PgBouncer:
   - Edite `postgres/pgbouncer-config/pgbouncer.ini`
   - Edite `postgres/pgbouncer-config/userlist.txt`

## Passo 5: Implantar as Pilhas Docker

1. **Traefik Proxy**:
   ```bash
   cd traefik-proxy
   ./deploy.sh
   ```

2. **PostgreSQL**:
   ```bash
   cd ../postgres
   ./deploy.sh
   ```

3. **Nhost**:
   ```bash
   cd ../nhost
   ./deploy.sh
   ```

## Passo 6: Configurar Aplicativos Nhost

1. Para cada aplicativo:
   - Crie um novo banco de dados usando o script fornecido
   - Configure as variáveis de ambiente no arquivo `.env` do Nhost
   - Atualize os rótulos do Docker Compose para os novos domínios

2. Aplique migrações do Hasura:
   ```bash
   hasura migrate apply --admin-secret SEU_SECRET --database-name default --endpoint hasura-seuapp.seudominio.com
   hasura metadata apply --admin-secret SEU_SECRET --endpoint hasura-seuapp.seudominio.com
   ```

## Passo 7: Configurações Opcionais

1. **Portainer** (para gerenciamento visual):
   - Implante a pilha do Portainer
   - Acesse via `portainer.seudominio.com`

2. **Kuma** (para monitoramento):
   - Implante a pilha do Kuma
   - Configure os checks necessários

## Passo 8: Manutenção e Monitoramento

1. Configure backups regulares para o banco de dados
2. Monitore os logs dos serviços:
   ```bash
   docker service logs -f nhost_hasura
   ```
3. Atualize regularmente as imagens Docker

## Dicas Importantes

1. Para migrar de um Nhost gerenciado:
   ```bash
   pg_dump -h nhostsubdomain.db.eu-central-1.nhost.run -U postgres -p 5432 -d nhostsubdomain -F c -f backup.dump
   pg_restore -h localhost -U postgres -p 6432 -d novo_banco -F c --clean backup.dump
   ```

2. Para adicionar mais aplicativos:
   - Repita a configuração do Nhost com novos domínios
   - Crie um novo banco de dados na mesma instância PostgreSQL

3. Problemas comuns:
   - Verifique os logs do Traefik para problemas de certificado SSL
   - Confira se todos os serviços estão na rede `traefik-public`
   - Valide as configurações do PgBouncer para problemas de conexão

Este guia fornece uma visão geral do processo. Consulte a documentação completa do Nhost e Docker para detalhes específicos sobre sua configuração.
