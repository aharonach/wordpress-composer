#!/usr/bin/env bash
set -euo pipefail

# Composer-managed WordPress bootstrap for Laravel Herd.
# Prompts for the local values you commonly change before installing WordPress.

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
WORDPRESS_DIR="${WORDPRESS_DIR:-$PROJECT_DIR/public}"
ENV_FILE="${ENV_FILE:-$PROJECT_DIR/.env}"
WP_BIN="${WP_BIN:-wp}"

DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-root}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PREFIX="${DB_PREFIX:-wp_}"
SITE_URL="${WP_HOME:-http://wordpress.test}"
SITE_TITLE="${WP_TITLE:-Herd WordPress}"
ADMIN_USER="${WP_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-Password123!}"
ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.test}"

prompt_for() {
  local var_name="$1"
  local default_value="$2"
  local label="$3"
  local value=""

  if [ -t 0 ]; then
    read -rp "$label [$default_value]: " value
  fi

  if [ -n "$value" ]; then
    printf -v "$var_name" '%s' "$value"
  else
    printf -v "$var_name" '%s' "$default_value"
  fi
}

load_env_file() {
  local key=""
  local value=""

  [ -f "$ENV_FILE" ] || return 0

  while IFS='=' read -r key value || [ -n "${key:-}" ]; do
    if [ -z "$key" ] || [[ "$key" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    key="${key%$'\r'}"
    value="${value%$'\r'}"
    export "$key=$value"
  done < "$ENV_FILE"
}

if [ -f "$ENV_FILE" ]; then
  load_env_file
fi

# Re-apply defaults from the loaded env, then prompt the user for each configurable local value.
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-root}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PREFIX="${DB_PREFIX:-wp_}"
SITE_URL="${WP_HOME:-${SITE_URL:-http://wordpress.test}}"
SITE_TITLE="${WP_TITLE:-${SITE_TITLE:-Herd WordPress}}"
ADMIN_USER="${WP_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-Password123!}"
ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.test}"

if [ -t 0 ]; then
  echo "Configure your local WordPress setup. Press Enter to keep the default value."
  prompt_for DB_NAME "$DB_NAME" "Database name"
  prompt_for DB_USER "$DB_USER" "Database user"
  prompt_for DB_PASSWORD "$DB_PASSWORD" "Database password"
  prompt_for DB_HOST "$DB_HOST" "Database host"
  prompt_for DB_PREFIX "$DB_PREFIX" "Table prefix"
  prompt_for SITE_URL "$SITE_URL" "Site URL"
  prompt_for SITE_TITLE "$SITE_TITLE" "Site title"
  prompt_for ADMIN_USER "$ADMIN_USER" "Admin username"
  prompt_for ADMIN_PASSWORD "$ADMIN_PASSWORD" "Admin password"
  prompt_for ADMIN_EMAIL "$ADMIN_EMAIL" "Admin email"
  echo
fi

{
  printf '%s=%q\n' "DB_NAME" "$DB_NAME"
  printf '%s=%q\n' "DB_USER" "$DB_USER"
  printf '%s=%q\n' "DB_PASSWORD" "$DB_PASSWORD"
  printf '%s=%q\n' "DB_HOST" "$DB_HOST"
  printf '%s=%q\n' "DB_PREFIX" "$DB_PREFIX"
  printf '%s=%q\n' "WP_HOME" "$SITE_URL"
  printf '%s=%q\n' "WP_SITEURL" "$SITE_URL"
  printf '%s=%q\n' "WP_TITLE" "$SITE_TITLE"
  printf '%s=%q\n' "WP_ADMIN_USER" "$ADMIN_USER"
  printf '%s=%q\n' "WP_ADMIN_PASSWORD" "$ADMIN_PASSWORD"
  printf '%s=%q\n' "WP_ADMIN_EMAIL" "$ADMIN_EMAIL"
} > "$ENV_FILE"

if ! command -v composer >/dev/null 2>&1; then
  echo "Composer is required. Install it before running this script."
  exit 1
fi

if ! command -v "$WP_BIN" >/dev/null 2>&1; then
  echo "WP-CLI is required. Install it with: brew install wp-cli or use the Herd PHP CLI."
  exit 1
fi

cd "$PROJECT_DIR"

if [ ! -f "$PROJECT_DIR/composer.json" ]; then
  echo "composer.json is missing. Add it before bootstrapping the site."
  exit 1
fi

if [ ! -f "$PROJECT_DIR/vendor/autoload.php" ]; then
  composer install --no-interaction --prefer-dist
fi

if [ ! -f "$WORDPRESS_DIR/wp-config.php" ]; then
  echo "Creating wp-config.php"
  cat <<PHP | "$WP_BIN" config create \
    --path="$WORDPRESS_DIR" \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="$DB_HOST" \
    --dbprefix="$DB_PREFIX" \
    --force \
    --extra-php
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'WP_HOME', '$SITE_URL' );
define( 'WP_SITEURL', '$SITE_URL' );
PHP
fi

MYSQL_CMD=(mysql -h "$DB_HOST" -u "$DB_USER" --password="$DB_PASSWORD")
if ! "${MYSQL_CMD[@]}" -e "USE \`$DB_NAME\`;" >/dev/null 2>&1; then
  echo "Creating database: $DB_NAME"
  "${MYSQL_CMD[@]}" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
fi

if ! "$WP_BIN" core is-installed --path="$WORDPRESS_DIR" >/dev/null 2>&1; then
  echo "Installing WordPress"
  "$WP_BIN" core install \
    --path="$WORDPRESS_DIR" \
    --url="$SITE_URL" \
    --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASSWORD" \
    --admin_email="$ADMIN_EMAIL"
fi

# Activate Composer-installed plugins while leaving src-managed custom code outside the WordPress root.
for plugin_path in "$WORDPRESS_DIR"/wp-content/plugins/*; do
  plugin_name="$(basename "$plugin_path")"
  if [ "$plugin_name" = "custom-plugin" ] || [ ! -d "$plugin_path" ]; then
    continue
  fi

  echo "Activating plugin: $plugin_name"
  "$WP_BIN" plugin activate "$plugin_name" --path="$WORDPRESS_DIR" >/dev/null 2>&1 || true
done

"$WP_BIN" option update home "$SITE_URL" --path="$WORDPRESS_DIR" >/dev/null
"$WP_BIN" option update siteurl "$SITE_URL" --path="$WORDPRESS_DIR" >/dev/null

echo "WordPress is ready. Open $SITE_URL/wp-admin"
