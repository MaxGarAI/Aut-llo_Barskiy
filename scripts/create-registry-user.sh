#!/usr/bin/env bash
set -e

# Скрипт создания/добавления пользователей для Docker Registry
REGISTRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/registry/auth"
HTPASSWD_FILE="$REGISTRY_DIR/htpasswd"
CONFIG_FILE="$REGISTRY_DIR/config.json"

mkdir -p "$REGISTRY_DIR"

USERNAME="${1:-developer}"
PASSWORD="${2:-DevSecurePass2026!}"

echo "==> Генерация учетных данных для Docker Registry..."
echo "Пользователь: $USERNAME"

# Генерация htpasswd с bcrypt через временный контейнер httpd:alpine
docker run --rm --entrypoint htpasswd httpd:alpine -Bbn "$USERNAME" "$PASSWORD" >> "$HTPASSWD_FILE"

# Убираем дубликаты, оставляя последнюю запись для пользователя
tac "$HTPASSWD_FILE" | awk -F: '!seen[$1]++' | tac > "${HTPASSWD_FILE}.tmp" && mv "${HTPASSWD_FILE}.tmp" "$HTPASSWD_FILE"
chmod 600 "$HTPASSWD_FILE"

# Генерация базового config.json для Watchtower (чтобы он мог автоматически скачивать образы)
AUTH_BASE64=$(echo -n "${USERNAME}:${PASSWORD}" | base64)
cat <<EOF > "$CONFIG_FILE"
{
  "auths": {
    "localhost:5000": {
      "auth": "${AUTH_BASE64}"
    },
    "127.0.0.1:5000": {
      "auth": "${AUTH_BASE64}"
    }
  }
}
EOF
chmod 600 "$CONFIG_FILE"

echo "==> Учетные данные успешно записаны в $HTPASSWD_FILE и $CONFIG_FILE"
echo "==> Теперь вы можете войти в реестр:"
echo "    docker login <IP_СЕРВЕРА>:5000 -u $USERNAME -p $PASSWORD"
