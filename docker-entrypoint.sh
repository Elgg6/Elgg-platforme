#!/bin/sh
set -e

WAIT_MYSQL_START=60 # seconds

# Wait for MySQL to be ready
echo "Waiting for MySQL at ${ELGG_DB_HOST}:${ELGG_DB_PORT}..."
i=0
while ! nc -z "$ELGG_DB_HOST" "$ELGG_DB_PORT" >/dev/null 2>&1; do
  i=$((i+1))
  if [ $i -ge $WAIT_MYSQL_START ]; then
    echo "$(date) - ${ELGG_DB_HOST}:${ELGG_DB_PORT} still not reachable, giving up."
    exit 1
  fi
  echo "$(date) - waiting for ${ELGG_DB_HOST}:${ELGG_DB_PORT}... $i/$WAIT_MYSQL_START."
  sleep 1
done
echo "The MySQL server is ready."

# Prepare config & data directories
mkdir -p /var/www/html/elgg/elgg-config
mkdir -p /var/www/html/data
chown -R www-data:www-data /var/www/html/elgg/elgg-config /var/www/html/data
chmod -R 775 /var/www/html/elgg/elgg-config /var/www/html/data

# Install PHP dependencies if missing
if [ ! -f "/var/www/html/elgg/vendor/autoload.php" ]; then
  echo "Installing PHP dependencies via Composer..."
  composer install --no-dev --prefer-dist
fi

# Run Elgg installation if not already installed
if [ ! -f "/var/www/html/elgg/elgg-config/settings.php" ]; then
  echo "Running Elgg installation..."
  php /var/www/html/elgg/install.php \
    --dbhost="$ELGG_DB_HOST" \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --sitename="$ELGG_SITE_NAME" \
    --siteemail="$ELGG_SITE_EMAIL" \
    --adminuser="$ELGG_ADMIN_USER" \
    --adminpass="$ELGG_ADMIN_PASS" \
    --adminemail="$ELGG_ADMIN_EMAIL" \
    --wwwroot="$ELGG_SITE_URL" \
    --dataroot="/var/www/html/data"
else
  echo "Elgg already installed, skipping installation."
fi

# Start Apache
exec "$@"
