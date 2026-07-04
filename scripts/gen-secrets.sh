#!/usr/bin/env bash
# Genera un .env a partir de .env.example rellenando cada CHANGE_ME_gen-secrets
# con un secreto aleatorio del largo correcto por variable.
# Uso:  ./scripts/gen-secrets.sh          (crea .env, no pisa si ya existe)
#       ./scripts/gen-secrets.sh --force  (regenera .env desde cero)
set -euo pipefail

cd "$(dirname "$0")/.."

FORCE="${1:-}"
if [[ -f .env && "$FORCE" != "--force" ]]; then
  echo "Ya existe .env. Usa --force para regenerarlo (perderas los secretos actuales)." >&2
  exit 1
fi

rand() { # rand <len>  -> string alfanumerico de <len> chars (sin SIGPIPE)
  local len="$1" s
  s="$(head -c "$((len * 2))" /dev/urandom | base64 | LC_ALL=C tr -dc 'A-Za-z0-9')"
  printf '%s' "${s:0:len}"
}

cp .env.example .env

# Largos especificos que exige cada app:
#   CALCOM_ENCRYPTION_KEY      = 32
#   PLAUSIBLE_SECRET_KEY_BASE  = 64
#   resto                      = 40 (mas que suficiente)
set_secret() { # set_secret VAR LEN
  local var="$1" len="$2" val
  val="$(rand "$len")"
  # reemplaza la linea VAR=... por VAR=<val>
  sed -i.bak "s|^${var}=.*|${var}=${val}|" .env && rm -f .env.bak
}

set_secret POSTGRES_PASSWORD 40
set_secret N8N_ENCRYPTION_KEY 40
set_secret N8N_BASIC_AUTH_PASSWORD 24
set_secret TWENTY_PG_PASSWORD 40
set_secret TWENTY_APP_SECRET 40
set_secret CALCOM_NEXTAUTH_SECRET 40
set_secret CALCOM_ENCRYPTION_KEY 32
set_secret LISTMONK_ADMIN_PASSWORD 24
set_secret PLAUSIBLE_SECRET_KEY_BASE 64
set_secret CLICKHOUSE_PASSWORD 40
set_secret OPENWA_API_KEY 40

echo "==> .env generado. Faltan por completar a mano:"
echo "    - dominios (N8N_HOST, *_URL, NPM_NETWORK)"
echo "    - SMTP_* (Brevo/SES)"
echo "    - SMTP_FROM"
