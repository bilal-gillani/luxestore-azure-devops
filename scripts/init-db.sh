#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: init-db.sh
# Purpose: Initialize Azure Database for MySQL Flexible Server
#          - Runs init.sql (schema & tables)
#          - Runs setup-user.sql (ecommerce_user & privileges)
#          - Runs seed.sql (idempotent seed data)
#          - Verifies ecommerce_user connectivity
# ==============================================================================

MYSQL_HOST="${1:-mysql-server-name.mysql.database.azure.com}"
MYSQL_ADMIN_USER="${2:-sqladmin}"
MYSQL_ADMIN_PWD="${MYSQL_ADMIN_PASSWORD:-${3:-}}"

if [ -z "$MYSQL_ADMIN_PWD" ]; then
  echo "❌ Error: MySQL admin password is required. Please set MYSQL_ADMIN_PASSWORD or pass as arg."
  exit 1
fi

echo "=================================================="
echo "Connecting to MySQL Flexible Server: $MYSQL_HOST"
echo "Admin User: $MYSQL_ADMIN_USER"
echo "=================================================="

# Function to run mysql command as admin
run_admin_sql() {
  mysql \
    --host="$MYSQL_HOST" \
    --user="$MYSQL_ADMIN_USER" \
    --password="$MYSQL_ADMIN_PWD" \
    --ssl-mode=REQUIRED \
    "$@"
}

# 1. Test admin connection
echo "👉 Step 1: Testing connection as $MYSQL_ADMIN_USER..."
run_admin_sql -e "SELECT VERSION() as 'MySQL Version', NOW() as 'Server Time';"
echo "✅ Successfully connected to MySQL server."

# 2. Run schema initialization (db/init.sql)
echo "👉 Step 2: Applying schema (init.sql)..."
run_admin_sql < db/init.sql
echo "✅ Schema and tables created successfully."

# 3. Create backend application user and grant permissions (db/setup-user.sql)
echo "👉 Step 3: Setting up application user (ecommerce_user)..."
run_admin_sql < db/setup-user.sql
echo "✅ Application user configured."

# 4. Check if seed data already exists before running seed.sql
echo "👉 Step 4: Checking if seed data is already present..."
EXISTING_USERS=$(run_admin_sql -D ecommerce_store -sse "SELECT COUNT(*) FROM users;" || echo "0")

if [ "$EXISTING_USERS" -eq "0" ]; then
  echo "Database is empty. Applying seed data (seed.sql)..."
  run_admin_sql -D ecommerce_store < db/seed.sql
  echo "✅ Seed data applied successfully."
else
  echo "ℹ️ Database already has $EXISTING_USERS user(s). Skipping seed.sql to prevent duplicates."
fi

# 5. Verify connectivity and permissions using the application user
echo "👉 Step 5: Testing connectivity with application user (ecommerce_user)..."
APP_VERIFY=$(mysql \
  --host="$MYSQL_HOST" \
  --user="ecommerce_user" \
  --password="hello123@" \
  --ssl-mode=REQUIRED \
  --database="ecommerce_store" \
  -sse "SELECT CONCAT('Categories: ', (SELECT COUNT(*) FROM categories), ' | Products: ', (SELECT COUNT(*) FROM products), ' | Users: ', (SELECT COUNT(*) FROM users));")

echo "✅ App user verified! Counts: $APP_VERIFY"
echo "🎉 Database initialization completed successfully!"
