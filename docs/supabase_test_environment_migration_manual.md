# Supabase Local Docker → AWS EC2 Docker (Test Environment) Migration Manual

This guide migrates a **local Supabase (Docker Compose)** project to a
**single EC2 instance** running the **Supabase self-hosted Docker
stack**. It is optimized for a **test/staging environment**.

------------------------------------------------------------------------

## 1. Assumptions

-   You run Supabase locally via Docker.
-   You want a simple AWS test environment (1 EC2 instance + Docker).
-   You want to migrate database schema + data.

------------------------------------------------------------------------

## 2. Create EC2 Test Host

### Recommended Setup

-   Ubuntu 22.04 LTS
-   Instance: t3.medium or t3.large
-   EBS: 50--100GB gp3
-   Security Group:
    -   22 from your IP only
    -   80/443 optional
    -   DO NOT open 5432 publicly

Fix SSH key permission if needed:

``` bash
chmod 400 craftbeer.pem
ssh -i craftbeer.pem ubuntu@<EC2_PUBLIC_IP>
```

------------------------------------------------------------------------

## 3. Install Docker on EC2

``` bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

newgrp docker
docker --version
docker compose version
```

------------------------------------------------------------------------

## 4. Setup Supabase on EC2

``` bash
git clone https://github.com/supabase/supabase
cd supabase/docker
cp .env.example .env
```

Edit `.env`:

-   POSTGRES_PASSWORD
-   JWT_SECRET
-   ANON_KEY
-   SERVICE_ROLE_KEY
-   DASHBOARD_USERNAME
-   DASHBOARD_PASSWORD
-   SITE_URL
-   API_EXTERNAL_URL

Generate secrets:

``` bash
openssl rand -base64 32
```

Start stack:

``` bash
docker compose up -d
docker compose ps
```

------------------------------------------------------------------------

## 5. Export Local Database

Find local DB container:

``` bash
docker ps --format "table {{.Names}}\t{{.Image}}"
```

Dump DB:

``` bash
docker exec -t <LOCAL_DB_CONTAINER> pg_dump -U postgres -Fc postgres > supabase_local.dump
```

------------------------------------------------------------------------

## 6. Copy Dump to EC2

``` bash
scp -i craftbeer.pem supabase_local.dump ubuntu@<EC2_PUBLIC_IP>:/home/ubuntu/
```

------------------------------------------------------------------------

## 7. Restore on EC2

Find EC2 DB container:

``` bash
docker ps --format "table {{.Names}}\t{{.Image}}"
```

Restore:

``` bash
docker exec -i <EC2_DB_CONTAINER> pg_restore -U postgres -d postgres --clean --if-exists < /home/ubuntu/supabase_local.dump
```

## Option postgresのバージョンが異なる場合

### Export sql from local database
docker exec -t  supabase_db_beer  pg_dump -U postgres --schema-only --no-owner --no-privileges -n public postgres > schema.sql
docker exec -t  supabase_db_beer pg_dump -U postgres --data-only --column-inserts --no-owner --no-privileges -n public postgres > data.sql

### Copy sql to EC2
``` bash
scp -i craftbeer.pem supabase_local.dump ubuntu@<EC2_PUBLIC_IP>:/home/ubuntu/
```


### Import on EC2
docker exec -i supabase-db psql -U postgres -d postgres < schema.sql
docker exec -i supabase-db psql -U postgres -d postgres < data.sql

### Fix Supabase role grants after restore

If you see `{"error":"permission denied for schema public"}` or
`{"error":"permission denied for schema mes"}` after importing
schema/data, restore the schema grants for the Supabase API roles.

``` bash
docker exec -i <EC2_DB_CONTAINER> psql -U postgres -d postgres <<'SQL'
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

GRANT USAGE ON SCHEMA mes TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA mes TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA mes TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA mes TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA mes
GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA mes
GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA mes
GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
SQL
```

Verify:

``` bash
docker exec -i <EC2_DB_CONTAINER> psql -U postgres -d postgres -c "
select
  role_name,
  has_schema_privilege(role_name, 'public', 'USAGE') as public_usage,
  has_schema_privilege(role_name, 'mes', 'USAGE') as mes_usage
from (values
  ('anon'),
  ('authenticated'),
  ('service_role')
) as roles(role_name);
"
```

------------------------------------------------------------------------

## 8. Verify

Check services:

``` bash
docker compose ps
docker compose logs -f --tail=200
```

Test API:

``` bash
curl http://<EC2_PUBLIC_IP>/rest/v1/
```

Open Studio:

    http://<EC2_PUBLIC_IP>/studio

------------------------------------------------------------------------

## 9. Migrate Edge Function

### Copy Edge Function

### Confirm Edge Function Folder

Check supabase docker-compose.yml file to get folder of Edge Function 
./volumes/functions


```
  213  docker exec -it <EDGE_CONTAINER> sh -lc 'ls -la /home/deno/
  214  docker exec -it supabase-edge-functions sh -lc 'ls -la /home/deno/
  215  docker exec -it supabase-edge-functions sh -lc 'ls -la /home/deno/functions'
```

### Copy Edge Function to Edge Function Folder


### Check again
```
  213  docker exec -it <EDGE_CONTAINER> sh -lc 'ls -la /home/deno/
  214  docker exec -it supabase-edge-functions sh -lc 'ls -la /home/deno/
  215  docker exec -it supabase-edge-functions sh -lc 'ls -la /home/deno/functions'
```


## 10. Optional: Reset and Re-migrate

``` bash
docker compose down
docker volume rm <EC2_DB_VOLUME>
docker compose up -d
```

Then restore again.

------------------------------------------------------------------------

## 11. Test Environment Hardening

-   Restrict SSH to your IP
-   Do not expose Postgres port
-   Use strong passwords
-   Take pg_dump backups if data matters

# Build Vue

## create env file for test env

copy .env to .ens.test
modify ULR & KEY

## modify package.json file to add following script
    "build:test": "vite build --mode test"

## Build the module 
npm run build:test


# Install Ngnix

## Install Ngnix

```
sudo apt install nginx
sudo systemctl start nginx
```

## Modify Ngnix Setting File

```
sudo vi /etc/nginx/sites-available/app
```

```
# /etc/nginx/sites-available/app

map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

server {
  listen 80;
  server_name _;

  # ---- Vue (static) ----
  root /var/www/vue;
  index index.html;

  # Vue router history mode support:
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Cache static assets aggressively
  location ~* \.(?:js|css|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
    expires 30d;
    add_header Cache-Control "public, max-age=2592000, immutable";
    try_files $uri =404;
  }

  # ---- Supabase via /api/ ----
  # IMPORTANT: proxy to Kong (Supabase gateway), usually on 8000 in self-host compose.
  location /api/ {
    proxy_pass http://127.0.0.1:8000/;   # trailing slash matters
    proxy_http_version 1.1;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # WebSocket support (Realtime)
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

    # Optional: larger uploads
    client_max_body_size 50m;
  }
}
```

```

sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
sudo nginx -t
sudo systemctl reload nginx
```



End of manual.
