terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "ap-southeast-1"
}

variable "solution_name" {
  default     = "supabase"
  description = "Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter."
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "c7n.2xlarge.2"
  description = "ECS flavor. Supabase runs ~10 Docker containers, c7n.2xlarge.2 (8vCPUs 16GiB) or above recommended. Change to match available flavors in target region."
  type        = string
  nullable    = false
}

variable "ecs_password" {
  description = "ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters."
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.ecs_password) >= 8 && length(var.ecs_password) <= 26
    error_message = "ECS password length must be between 8 and 26 characters."
  }
}

variable "db_password" {
  description = "PostgreSQL password, 8-26 chars. Used as the password for all database roles."
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 26
    error_message = "Database password length must be between 8 and 26 characters."
  }
}

variable "system_disk_size" {
  default     = 100
  description = "System disk size in GB (high-IO SAS). Docker images + DB data. 100GB recommended. Range: 40-1024."
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "System disk size must be between 40 and 1024 GB."
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "EIP bandwidth in Mbit/s, traffic billing. Range: 1-300. Default: 300."
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "Bandwidth must be between 1 and 300 Mbit/s."
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "Billing mode: postPaid (pay-per-use) or prePaid (subscription). Default: postPaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "Must be postPaid or prePaid."
  }
}

variable "charging_unit" {
  default     = "month"
  description = "Subscription unit: month or year. Required when charging_mode is prePaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "Must be month or year."
  }
}

variable "charging_period" {
  default     = 1
  description = "Subscription period: 1-9 (month) or 1-3 (year). Required when charging_mode is prePaid."
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "Period must be between 1 and 9."
  }
}

data "huaweicloud_images_image" "Ubuntu" {
  most_recent = true
  name        = "Ubuntu 24.04 server 64bit"
  visibility  = "public"
}

resource "huaweicloud_vpc" "vpc" {
  name = "${var.solution_name}-vpc"
  cidr = "172.16.0.0/16"
}

resource "huaweicloud_vpc_subnet" "subnet" {
  name       = "${var.solution_name}-subnet"
  cidr       = "172.16.1.0/24"
  gateway_ip = "172.16.1.1"
  vpc_id     = huaweicloud_vpc.vpc.id
}

resource "huaweicloud_networking_secgroup" "secgroup" {
  name = "${var.solution_name}-sg"
}

resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Allow ping for connectivity test"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "supabase_http" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Supabase Dashboard and API services"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 8000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "SSH access via Cloud Shell"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_vpc_eip" "vpc_eip" {
  name = "${var.solution_name}-eip"
  bandwidth {
    name        = "${var.solution_name}-bw"
    share_type  = "PER"
    size        = var.bandwidth_size
    charge_mode = "traffic"
  }
  publicip {
    type = "5_bgp"
  }
  charging_mode = "postPaid"
}

resource "huaweicloud_compute_instance" "compute_instance" {
  name                        = "${var.solution_name}-ecs"
  image_id                    = data.huaweicloud_images_image.Ubuntu.id
  flavor_id                   = var.ecs_flavor
  security_group_ids          = [huaweicloud_networking_secgroup.secgroup.id]
  system_disk_type            = "SAS"
  system_disk_size            = var.system_disk_size
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = true
  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }
  agent_list    = "hss,ces"
  eip_id        = huaweicloud_vpc_eip.vpc_eip.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
  tags = {
    app = "Supabase"
  }
  user_data = <<-EOT
  #!/bin/bash
  set -e

  echo 'root:${var.ecs_password}' | chpasswd

  LOG="/var/log/supabase-bootstrap.log"
  exec > >(tee -a "$LOG") 2>&1
  echo "[$(date)] Supabase bootstrap: start"

  # ---- Stage 1: Install Docker CE (official source) ----
  echo "[$(date)] Installing Docker CE..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-compose-plugin
  echo "[$(date)] Docker installed: $(docker --version)"

  # ---- Stage 2: Prepare directory and generate secrets ----
  SUPABASE_DIR="/opt/supabase"
  mkdir -p "$SUPABASE_DIR/volumes/api" "$SUPABASE_DIR/volumes/db" "$SUPABASE_DIR/volumes/storage"
  cd "$SUPABASE_DIR"

  DB_PASSWORD="${var.db_password}"
  JWT_SECRET="$(openssl rand -base64 32 2>/dev/null || echo "supabase-jwt-$(date +%s)")"
  SECRET_KEY_BASE="$(openssl rand -base64 32 2>/dev/null || echo "supabase-secret-key-base")"

  # Sign ANON_KEY / SERVICE_ROLE_KEY from JWT_SECRET (HS256)
  gen_jwt() {
    local secret="$1" role="$2"
    local header='{"alg":"HS256","typ":"JWT"}'
    local payload="{\"iss\":\"supabase\",\"role\":\"$role\",\"exp\":1983810273,\"ref\":\"default\"}"
    local h p sig
    h=$(printf '%s' "$header"  | openssl base64 -A | tr '/+' '_-' | tr -d '=')
    p=$(printf '%s' "$payload" | openssl base64 -A | tr '/+' '_-' | tr -d '=')
    sig=$(printf '%s' "$h.$p" | openssl dgst -sha256 -hmac "$secret" -binary | openssl base64 -A | tr '/+' '_-' | tr -d '=')
    printf '%s' "$h.$p.$sig"
  }
  ANON_KEY="$(gen_jwt "$JWT_SECRET" anon)"
  SERVICE_ROLE_KEY="$(gen_jwt "$JWT_SECRET" service_role)"

  # ---- Stage 3: Generate .env ----
  cat > "$SUPABASE_DIR/.env" << ENVEOF
  POSTGRES_PASSWORD=$DB_PASSWORD
  JWT_SECRET=$JWT_SECRET
  SECRET_KEY_BASE=$SECRET_KEY_BASE
  APP_NAME=supabase
  ANON_KEY=$ANON_KEY
  SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
  ENVEOF

  # ---- Stage 4: Generate kong.yml ----
  cat > "$SUPABASE_DIR/volumes/api/kong.yml" << 'KONGEOF'
  _format_version: "1.1"
  _transform: true

  services:
    - name: auth
      url: http://auth:9999
      routes:
        - name: auth-all
          paths:
            - /auth/v1/
      plugins:
        - name: cors

    - name: rest
      url: http://rest:3000
      routes:
        - name: rest-all
          paths:
            - /rest/v1/
      plugins:
        - name: cors
        - name: key-auth
          config:
            hide_credentials: true

    - name: studio
      url: http://studio:3000
      routes:
        - name: studio-all
          paths:
            - /
      plugins:
        - name: cors

    - name: realtime
      url: http://realtime:4000
      routes:
        - name: realtime-all
          paths:
            - /realtime/v1/
      plugins:
        - name: cors

    - name: storage
      url: http://storage:5000
      routes:
        - name: storage-all
          paths:
            - /storage/v1/
      plugins:
        - name: cors
        - name: key-auth
          config:
            hide_credentials: true
  KONGEOF

  # ---- Stage 5: Generate docker-compose.yaml (official Docker Hub images) ----
  cat > "$SUPABASE_DIR/docker-compose.yaml" << 'COMPOSEEOF'
  services:
    kong:
      image: kong:3.9.1
      container_name: supabase-kong
      restart: unless-stopped
      ports:
        - "8000:8000/tcp"
        - "8443:8443/tcp"
      environment:
        KONG_DATABASE: "off"
        KONG_DECLARATIVE_CONFIG: /home/kong/temp.yml
        KONG_DNS_ORDER: LAST,A,CNAME
        KONG_PLUGINS: request-transformer,cors,key-auth,rate-limiting
        KONG_NGINX_WORKER_PROCESSES: "2"
        KONG_LOG_LEVEL: warn
      volumes:
        - ./volumes/api/kong.yml:/home/kong/temp.yml:ro
      healthcheck:
        test: ["CMD", "kong", "health"]
        interval: 30s
        timeout: 10s
        retries: 5

    db:
      image: supabase/postgres:15.8.1.085
      container_name: supabase-db
      restart: unless-stopped
      ports:
        - "5432:5432"
      environment:
        POSTGRES_PASSWORD: $${POSTGRES_PASSWORD}
        JWT_SECRET: $${JWT_SECRET}
      volumes:
        - ./volumes/db/data:/var/lib/postgresql/data
      healthcheck:
        test: pg_isready -U postgres -h localhost
        interval: 10s
        timeout: 5s
        retries: 10

    supavisor:
      image: supabase/supavisor:2.7.4
      container_name: supabase-pooler
      restart: unless-stopped
      ports:
        - "6543:6543"
        - "5433:5433"
      environment:
        PROJECT_NAME: supabase
        DATABASE_URL: postgres://supabase_admin:$${POSTGRES_PASSWORD}@db:5432/supabase
        POOL_MODE: transaction
        DEFAULT_POOL_SIZE: "20"
        MaxPoolSize: "30"
        SECRET_KEY_BASE: $${SECRET_KEY_BASE}
      depends_on:
        db:
          condition: service_healthy
      healthcheck:
        test: pg_isready -h localhost -p 6543 -U supabase_admin
        interval: 10s
        timeout: 5s
        retries: 5

    auth:
      image: supabase/gotrue:v2.186.0
      container_name: supabase-auth
      restart: unless-stopped
      environment:
        GOTRUE_API_HOST: "0.0.0.0"
        GOTRUE_API_PORT: "9999"
        API_EXTERNAL_URL: http://localhost:8000
        GOTRUE_SITE_URL: http://localhost:3000
        GOTRUE_JWT_SECRET: $${JWT_SECRET}
        GOTRUE_DB_DRIVER: postgres
        GOTRUE_DB_DATABASE_URL: postgres://supabase_auth_admin:$${POSTGRES_PASSWORD}@db:5432/supabase
        DATABASE_URL: postgres://supabase_auth_admin:$${POSTGRES_PASSWORD}@db:5432/supabase
      depends_on:
        db:
          condition: service_healthy
      healthcheck:
        test: curl -sS http://localhost:9999/health
        interval: 30s
        timeout: 5s
        retries: 5

    rest:
      image: postgrest/postgrest:v14.8
      container_name: supabase-rest
      restart: unless-stopped
      environment:
        PGRST_DB_URI: postgres://authenticator:$${POSTGRES_PASSWORD}@db:5432/supabase
        PGRST_DB_SCHEMA: public,storage,graphql_public
        PGRST_DB_ANON_ROLE: anon
        PGRST_JWT_SECRET: $${JWT_SECRET}
        PGRST_DB_AGGREGATES_ENABLED: "true"
      depends_on:
        db:
          condition: service_healthy

    realtime:
      image: supabase/realtime:v2.76.5
      container_name: supabase-realtime
      restart: unless-stopped
      ports:
        - "4000:4000"
      environment:
        PORT: "4000"
        DB_HOST: db
        DB_PORT: "5432"
        DB_NAME: supabase
        DB_USER: supabase_admin
        DB_PASSWORD: $${POSTGRES_PASSWORD}
        DB_AFTER_CONNECT_QUERY: "SET search_path TO _realtime"
        JWT_SECRET: $${JWT_SECRET}
        SECRET_KEY_BASE: $${SECRET_KEY_BASE}
        APP_NAME: $${APP_NAME}
        ERL_AFLAGS: "-proto_dist inet_tcp"
        REPLICATION_MODE: "stream"
        REPLICATION_SLOT_NAME: "supabase_realtime_replication_slot"
      depends_on:
        db:
          condition: service_healthy

    storage:
      image: supabase/storage-api:v1.48.26
      container_name: supabase-storage
      restart: unless-stopped
      environment:
        ANON_KEY: $${ANON_KEY}
        SERVICE_ROLE_KEY: $${SERVICE_ROLE_KEY}
        POSTGREST_URL: http://rest:3000
        PGRST_JWT_SECRET: $${JWT_SECRET}
        IMGPROXY_URL: http://imgproxy:5001
        DATABASE_URL: postgres://supabase_storage_admin:$${POSTGRES_PASSWORD}@db:5432/supabase
        FILE_SIZE_LIMIT: "52428800"
        STORAGE_BACKEND: file
        FILE_STORAGE_BACKEND_PATH: /var/lib/storage
        FILE_STORAGE_PATH: /var/lib/storage
        TENANT_ID: default
        REGION: ap-southeast-1
        GLOBAL_S3_BUCKET: ""
      volumes:
        - ./volumes/storage:/var/lib/storage
      depends_on:
        db:
          condition: service_healthy
        rest:
          condition: service_started

    imgproxy:
      image: darthsim/imgproxy:latest
      container_name: supabase-imgproxy
      restart: unless-stopped
      environment:
        IMGPROXY_BIND: ":5001"
        IMGPROXY_USE_ETAG: "true"
        IMGPROXY_ENABLE_WEBP_DETECTION: "true"

    meta:
      image: supabase/postgres-meta:v0.96.3
      container_name: supabase-meta
      restart: unless-stopped
      environment:
        PG_META_PORT: "8080"
        PG_META_DB_HOST: db
        PG_META_DB_PORT: "5432"
        PG_META_DB_NAME: supabase
        PG_META_DB_USER: supabase_admin
        PG_META_DB_PASSWORD: $${POSTGRES_PASSWORD}
        PG_META_PG_META_CRYPTO_KEY: $${JWT_SECRET}
      depends_on:
        db:
          condition: service_healthy
      healthcheck:
        test: ["CMD-SHELL", "curl -sf http://localhost:8080/health > /dev/null || exit 1"]
        interval: 30s
        timeout: 5s
        retries: 5

    studio:
      image: supabase/studio:latest
      container_name: supabase-studio
      restart: unless-stopped
      environment:
        STUDIO_PG_META_URL: http://meta:8080
        SUPABASE_URL: http://kong:8000
        SUPABASE_ANON_KEY: $${ANON_KEY}
        SUPABASE_SERVICE_ROLE_KEY: $${SERVICE_ROLE_KEY}
        SUPABASE_PUBLIC_URL: http://localhost:8000
      depends_on:
        - meta
        - kong
  COMPOSEEOF

  # ---- Stage 6: Deploy with retry ----
  echo "[$(date)] Deploying Supabase..."
  cd "$SUPABASE_DIR"
  MAX_RETRIES=5
  COUNT=0
  deploy_ok=0
  until [ $COUNT -ge $MAX_RETRIES ]; do
    docker compose pull 2>&1 && docker compose up -d 2>&1 && deploy_ok=1 && break
    COUNT=$((COUNT+1))
    echo "[$(date)] Pull/start failed (attempt $COUNT/$MAX_RETRIES), retrying in 30s..."
    sleep 30
  done

  if [ $deploy_ok -eq 0 ]; then
    echo "[FATAL] Deployment failed after $MAX_RETRIES attempts"
    docker compose logs --tail=50 2>&1 || true
    exit 1
  fi
  echo "[$(date)] Containers started"

  # ---- Stage 7: Configure systemd auto-start ----
  cat > /etc/systemd/system/supabase.service << 'UNITEOF'
  [Unit]
  Description=Supabase Docker Compose Stack
  Requires=docker.service
  After=docker.service

  [Service]
  Type=oneshot
  RemainAfterExit=yes
  WorkingDirectory=/opt/supabase
  ExecStart=/usr/bin/docker compose up -d
  ExecStop=/usr/bin/docker compose down
  TimeoutStartSec=300

  [Install]
  WantedBy=multi-user.target
  UNITEOF
  systemctl daemon-reload
  systemctl enable supabase.service
  echo "[$(date)] Auto-start configured"

  # ---- Stage 8: DB initialization ----
  echo "[$(date)] Waiting for DB..."
  for i in $(seq 1 30); do
    docker exec supabase-db pg_isready -U postgres -q 2>/dev/null && break
    sleep 2
  done

  echo "[INFO] Initializing database roles and schema..."
  docker exec supabase-db psql -U postgres -v ON_ERROR_STOP=1 -c "ALTER USER supabase_admin WITH PASSWORD '$DB_PASSWORD';"
  docker exec supabase-db psql -U postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='supabase';" | grep -q 1 || \
    docker exec supabase-db psql -U postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE supabase OWNER supabase_admin;"
  docker exec supabase-db psql -U postgres -v ON_ERROR_STOP=1 -c "ALTER DATABASE supabase OWNER TO supabase_admin;"
  docker exec -i -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost -d supabase -v ON_ERROR_STOP=1 <<SQL
  CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION supabase_auth_admin;
  CREATE SCHEMA IF NOT EXISTS storage AUTHORIZATION supabase_storage_admin;
  CREATE SCHEMA IF NOT EXISTS extensions AUTHORIZATION supabase_admin;
  CREATE SCHEMA IF NOT EXISTS _realtime AUTHORIZATION supabase_admin;
  GRANT USAGE, CREATE ON SCHEMA auth TO supabase_auth_admin;
  GRANT USAGE, CREATE ON SCHEMA storage TO supabase_storage_admin;
  GRANT USAGE, CREATE ON SCHEMA public TO supabase_admin, authenticator, supabase_auth_admin, supabase_storage_admin;
  GRANT USAGE, CREATE ON SCHEMA extensions TO supabase_admin;
  GRANT USAGE, CREATE ON SCHEMA _realtime TO supabase_admin;
  GRANT ALL PRIVILEGES ON DATABASE supabase TO supabase_admin, supabase_auth_admin, supabase_storage_admin, authenticator;
  SQL
  docker exec supabase-db psql -U postgres -v ON_ERROR_STOP=1 -c "ALTER USER authenticator WITH PASSWORD '$DB_PASSWORD';"
  docker exec supabase-db psql -U postgres -v ON_ERROR_STOP=1 -c "ALTER USER supabase_auth_admin WITH PASSWORD '$DB_PASSWORD';"
  docker exec supabase-db psql -U postgres -v ON_ERROR_STOP=1 -c "ALTER USER supabase_storage_admin WITH PASSWORD '$DB_PASSWORD';"
  docker compose restart auth rest storage realtime 2>/dev/null || true
  echo "[OK] Database initialization complete"

  # ---- Stage 9: Health check ----
  echo "[$(date)] Health check..."
  sleep 15
  echo "--- Container status ---"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  echo "--- Dashboard check ---"
  curl -sS --connect-timeout 5 http://localhost:8000/project/default 2>&1 | head -3 || echo "Dashboard not ready (may need more time)"

  echo "[$(date)] Supabase bootstrap: done"

  EOT
}

output "access_info" {
  description = "Deployment access information"
  value       = "Wait ~10-15 minutes for deployment to complete | Dashboard: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/project/default | REST API: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/rest/v1/ | Auth API: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/auth/v1/ | Storage: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/storage/v1/ | SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address} | Config: /opt/supabase/ | Logs: /var/log/supabase-bootstrap.log"
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
