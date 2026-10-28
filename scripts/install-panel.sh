#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

# Template rendered by .github/workflows/release.yaml for each tagged release.
RELEASE_VERSION="__VERSION__"
REPOSITORY="__REPOSITORY__"
INSTALL_DIR="/var/www/headypanel"
SERVICE_USER="www-data"
NGINX_SITE="/etc/nginx/sites-available/headypanel.conf"

log() { printf '\n[HeadyPanel] %s\n' "$*"; }
fail() { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || fail "Run with sudo/root: bash headypanel-install.sh"
[[ -t 0 ]] || fail "An interactive terminal is required."
[[ "$RELEASE_VERSION" != "__VERSION__" && "$REPOSITORY" != "__REPOSITORY__" ]] || fail "This installer was not generated for a release."
[[ "$RELEASE_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || fail "Invalid release version."

. /etc/os-release
case "${ID:-}" in
  debian) [[ "${VERSION_ID:-}" == "12" ]] || fail "Supported OS: Debian 12 only (PHP 8.2)." ;;
  ubuntu) [[ "${VERSION_ID:-}" == "24.04" ]] || fail "Supported OS: Ubuntu 24.04 only (PHP 8.3)." ;;
  *) fail "Unsupported OS: ${PRETTY_NAME:-unknown}. Use Debian 12 or Ubuntu 24.04." ;;
esac

log "Installing HeadyPanel ${RELEASE_VERSION} on ${PRETTY_NAME}."
printf 'Install directory [%s]: ' "$INSTALL_DIR"
read -r input_dir
if [[ -n "$input_dir" ]]; then INSTALL_DIR="$input_dir"; fi
[[ "$INSTALL_DIR" == /* && "$INSTALL_DIR" != "/" ]] || fail "Install directory must be an absolute path."
[[ ! -e "$INSTALL_DIR" || -z "$(find "$INSTALL_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]] || fail "$INSTALL_DIR is not empty; choose an empty directory or back it up first."
printf 'Public domain or IPv4 address (e.g. panel.example.com): '
read -r PANEL_HOST
[[ "$PANEL_HOST" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || fail "Invalid host name."
printf 'Email for optional Let’s Encrypt HTTPS (leave empty for HTTP): '
read -r TLS_EMAIL
[[ -z "$TLS_EMAIL" || "$TLS_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] || fail "Invalid email address."
if [[ -n "$TLS_EMAIL" && "$PANEL_HOST" =~ ^[0-9.]+$ ]]; then fail "Let’s Encrypt requires a domain name, not an IP address."; fi

export DEBIAN_FRONTEND=noninteractive
log "Installing system packages."
apt-get update
apt-get install -y ca-certificates curl unzip tar nginx mariadb-server redis-server composer openssl \
  php-cli php-fpm php-common php-curl php-gd php-mbstring php-mysql php-xml php-zip php-bcmath php-intl
PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')"
[[ "$PHP_VERSION" == "8.2" || "$PHP_VERSION" == "8.3" ]] || fail "PHP $PHP_VERSION detected; this panel requires PHP 8.2 or 8.3."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
ARCHIVE_URL="https://github.com/${REPOSITORY}/releases/download/${RELEASE_VERSION}/panel.tar.gz"
log "Downloading the release archive."
curl --fail --location --retry 3 --retry-delay 2 "$ARCHIVE_URL" --output "$TMP_DIR/panel.tar.gz"
tar -tzf "$TMP_DIR/panel.tar.gz" >/dev/null || fail "Invalid release archive."
mkdir -p "$INSTALL_DIR"
tar -xzf "$TMP_DIR/panel.tar.gz" -C "$INSTALL_DIR"
cd "$INSTALL_DIR"
[[ -f artisan && -f composer.json && -f .env.example ]] || fail "Release archive is missing required Laravel files."

log "Creating a local MariaDB database and restricted database user."
systemctl enable --now mariadb redis-server
DB_NAME="headypanel"
DB_USER="headypanel"
DB_PASS="$(openssl rand -hex 24)"
mysql --protocol=socket <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
ALTER USER '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

cp .env.example .env
if [[ -n "$TLS_EMAIL" ]]; then APP_SCHEME="https"; else APP_SCHEME="http"; fi
export HP_APP_URL="$APP_SCHEME://$PANEL_HOST" HP_DB_NAME="$DB_NAME" HP_DB_USER="$DB_USER" HP_DB_PASS="$DB_PASS"
php <<'PHP'
<?php
$path = '.env';
$content = file_get_contents($path);
if ($content === false) { fwrite(STDERR, "Unable to read .env\n"); exit(1); }
$values = [
    'APP_ENV' => 'production', 'APP_DEBUG' => 'false', 'APP_URL' => getenv('HP_APP_URL'),
    'DB_CONNECTION' => 'mysql', 'DB_HOST' => '127.0.0.1', 'DB_PORT' => '3306',
    'DB_DATABASE' => getenv('HP_DB_NAME'), 'DB_USERNAME' => getenv('HP_DB_USER'),
    'DB_PASSWORD' => getenv('HP_DB_PASS'),
];
foreach ($values as $key => $value) {
    $escaped = '"' . str_replace(['\\', '"', "\n", "\r"], ['\\\\', '\\\"', '\\n', '\\r'], (string) $value) . '"';
    $pattern = '/^' . preg_quote($key, '/') . '=.*/m';
    if (preg_match($pattern, $content)) { $content = preg_replace($pattern, $key . '=' . $escaped, $content, 1); }
    else { $content .= "\n" . $key . '=' . $escaped . "\n"; }
}
if (file_put_contents($path, $content, LOCK_EX) === false) { fwrite(STDERR, "Unable to write .env\n"); exit(1); }
PHP
chmod 640 .env

log "Installing production PHP dependencies."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist
php artisan key:generate --force
php artisan migrate --seed --force
php artisan storage:link || true
log "Create the first panel administrator."
php artisan p:user:make

log "Applying least-privilege file permissions."
chown -R root:"$SERVICE_USER" "$INSTALL_DIR"
find "$INSTALL_DIR" -type d -exec chmod 750 {} +
find "$INSTALL_DIR" -type f -exec chmod 640 {} +
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR/storage" "$INSTALL_DIR/bootstrap/cache"
find "$INSTALL_DIR/storage" "$INSTALL_DIR/bootstrap/cache" -type d -exec chmod 770 {} +
find "$INSTALL_DIR/storage" "$INSTALL_DIR/bootstrap/cache" -type f -exec chmod 660 {} +
chown root:"$SERVICE_USER" "$INSTALL_DIR/.env"
chmod 640 "$INSTALL_DIR/.env"

log "Configuring PHP-FPM and Nginx."
systemctl enable --now "php${PHP_VERSION}-fpm"
FPM_SOCKET="$(find /run/php -maxdepth 1 -type s -name 'php*-fpm.sock' -print -quit)"
[[ -n "$FPM_SOCKET" ]] || fail "PHP-FPM socket not found."
cat > "$NGINX_SITE" <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $PANEL_HOST;
    root $INSTALL_DIR/public;
    index index.php;
    charset utf-8;
    client_max_body_size 100m;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:$FPM_SOCKET;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_read_timeout 300;
    }
    location ~ /\. { deny all; }
}
NGINX
ln -sfn "$NGINX_SITE" /etc/nginx/sites-enabled/headypanel.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

if [[ -n "$TLS_EMAIL" ]]; then
  log "Enabling HTTPS with Let's Encrypt."
  apt-get install -y certbot python3-certbot-nginx
  certbot --nginx --non-interactive --agree-tos --redirect --email "$TLS_EMAIL" -d "$PANEL_HOST" || fail "Certbot failed. Check DNS and inbound port 80."
fi

log "Configuring Laravel queue worker and scheduler."
cat > /etc/systemd/system/headypanel-queue.service <<SERVICE
[Unit]
Description=HeadyPanel Laravel Queue Worker
After=network.target mariadb.service redis-server.service
[Service]
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/php $INSTALL_DIR/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
Restart=always
RestartSec=5
PrivateTmp=true
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable --now headypanel-queue.service
CRON_LINE="* * * * * /usr/bin/php $INSTALL_DIR/artisan schedule:run >> /dev/null 2>&1"
( crontab -u "$SERVICE_USER" -l 2>/dev/null | grep -Fv "$INSTALL_DIR/artisan schedule:run" || true; echo "$CRON_LINE" ) | crontab -u "$SERVICE_USER" -

printf '\nInstallation completed.\nPanel: %s://%s\nDirectory: %s\nDatabase: %s (user %s)\nDatabase password: %s\n' "$APP_SCHEME" "$PANEL_HOST" "$INSTALL_DIR" "$DB_NAME" "$DB_USER" "$DB_PASS"
printf 'Save the database password in a password manager. Create the first administrator using the HeadyPanel documentation.\n'
