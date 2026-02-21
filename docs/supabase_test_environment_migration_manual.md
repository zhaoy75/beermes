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

## 9. Optional: Reset and Re-migrate

``` bash
docker compose down
docker volume rm <EC2_DB_VOLUME>
docker compose up -d
```

Then restore again.

------------------------------------------------------------------------

## 10. Test Environment Hardening

-   Restrict SSH to your IP
-   Do not expose Postgres port
-   Use strong passwords
-   Take pg_dump backups if data matters

------------------------------------------------------------------------

End of manual.
