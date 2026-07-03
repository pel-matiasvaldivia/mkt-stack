#!/bin/bash
# Crea una base por servicio en el Postgres compartido.
# Corre UNA sola vez, en el primer arranque (volumen vacio).
# Todas usan el superusuario POSTGRES_USER (stack interno de un solo tenant).
set -euo pipefail

for db in n8n calcom listmonk plausible; do
  echo "==> creando base '$db' si no existe"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    SELECT 'CREATE DATABASE $db'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
EOSQL
done

echo "==> bases listas: n8n, calcom, listmonk, plausible"
