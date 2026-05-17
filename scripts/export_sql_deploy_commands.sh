#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/export_sql_deploy_commands.sh <git-hash> <ec2-public-ip> [remote-dir]

Arguments:
  git-hash       Base commit/hash used by git diff.
  ec2-public-ip  EC2 public IP or DNS name used for scp/ssh.
  remote-dir     Server directory for copied SQL files. Default: /home/ubuntu/sql_deploy

Environment:
  SSH_KEY       SSH key path. Default: craftbeer.pem
  SSH_USER      SSH username. Default: ubuntu
  DB_CONTAINER  Docker database container. Default: supabase-db
  DB_USER       PostgreSQL user. Default: postgres
  DB_NAME       PostgreSQL database. Default: postgres

Examples:
  scripts/export_sql_deploy_commands.sh 6967546d2925acaafcbbde34ee6b52778064b5b3 1.2.3.4
  SSH_KEY=craftbeer.pem scripts/export_sql_deploy_commands.sh 6967546d2925acaafcbbde34ee6b52778064b5b3 ec2-1-2-3-4.ap-northeast-1.compute.amazonaws.com /home/ubuntu/sql_deploy
USAGE
}

quote() {
  local value=${1-}
  printf "'"
  printf "%s" "$value" | sed "s/'/'\\\\''/g"
  printf "'"
}

if [[ ${1-} == "-h" || ${1-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

base_hash=$1
ec2_public_ip=$2
remote_dir=${3:-"/home/ubuntu/sql_deploy"}
ssh_key=${SSH_KEY:-"craftbeer.pem"}
ssh_user=${SSH_USER:-"ubuntu"}
remote_target="${ssh_user}@${ec2_public_ip}"
db_container=${DB_CONTAINER:-"supabase-db"}
db_user=${DB_USER:-"postgres"}
db_name=${DB_NAME:-"postgres"}

if ! git rev-parse --verify --quiet "${base_hash}^{commit}" >/dev/null; then
  printf "error: git hash is not a valid commit: %s\n" "$base_hash" >&2
  exit 1
fi

sql_files=$(git diff --name-only --diff-filter=ACMR "$base_hash" -- '*.sql' '*.SQL')

if [[ -z $sql_files ]]; then
  printf "# No changed SQL files found since %s\n" "$base_hash"
  exit 0
fi

printf "# SQL files changed since %s\n" "$base_hash"
printf "%s\n" "$sql_files" | sed 's/^/# - /'
printf "\n"

printf "# Copy SQL files to server\n"
printf "ssh -i %s %s %s\n" \
  "$(quote "$ssh_key")" \
  "$(quote "$remote_target")" \
  "$(quote "mkdir -p $remote_dir")"

while IFS= read -r sql_file; do
  remote_file="${remote_dir%/}/$sql_file"
  remote_parent=${remote_file%/*}
  printf "ssh -i %s %s %s\n" \
    "$(quote "$ssh_key")" \
    "$(quote "$remote_target")" \
    "$(quote "mkdir -p $remote_parent")"
  printf "scp -i %s %s %s\n" \
    "$(quote "$ssh_key")" \
    "$(quote "$sql_file")" \
    "$(quote "${remote_target}:$remote_file")"
done <<< "$sql_files"

printf "\n"
printf "# Execute SQL files on server\n"
while IFS= read -r sql_file; do
  remote_file="${remote_dir%/}/$sql_file"
  remote_command="docker exec -i $db_container psql -U $db_user -d $db_name < $remote_file"
  printf "ssh -i %s %s %s\n" \
    "$(quote "$ssh_key")" \
    "$(quote "$remote_target")" \
    "$(quote "$remote_command")"
done <<< "$sql_files"
