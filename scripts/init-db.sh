#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: init-db.sh
# Purpose: Initialize Azure Database for MySQL Flexible Server
#          - Runs init.sql (schema & tables)
#          - Runs setup-user.sql (ecommerce_user & privileges)
#          - Runs seed.sql (idempotent seed data)
#          - Verifies ecommerce_user connectivity & counts
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# Function to run mysql command as admin using MYSQL_PWD environment variable
run_admin_sql() {
  MYSQL_PWD="$MYSQL_ADMIN_PWD" mysql \
    --host="$MYSQL_HOST" \
    --user="$MYSQL_ADMIN_USER" \
    --ssl-mode=REQUIRED \
    "$@"
}

# ------------------------------------------------------------------------------
# 1. Test Admin Connection
# ------------------------------------------------------------------------------
echo "👉 Step 1: Testing connection as $MYSQL_ADMIN_USER..."
run_admin_sql -e "SELECT VERSION() as 'MySQL Version', NOW() as 'Server Time';"
echo "✅ Successfully connected to MySQL server."

# ------------------------------------------------------------------------------
# 2. Run Schema Initialization (db/init.sql)
# ------------------------------------------------------------------------------
echo "👉 Step 2: Applying schema (init.sql)..."
run_admin_sql < "$REPO_ROOT/db/init.sql"
TABLES=$(run_admin_sql -D ecommerce_store -sse "SHOW TABLES;" | tr '\n' ' ')
echo "✅ Schema applied! Tables created: $TABLES"

# ------------------------------------------------------------------------------
# 3. Create Application User & Permissions (db/setup-user.sql)
# ------------------------------------------------------------------------------
echo "👉 Step 3: Setting up application user (ecommerce_user)..."
run_admin_sql < "$REPO_ROOT/db/setup-user.sql"
echo "✅ Application user (ecommerce_user) configured with full privileges on ecommerce_store."

# ------------------------------------------------------------------------------
# 4. Check & Apply Seed Data (db/seed.sql)
# ------------------------------------------------------------------------------
echo "👉 Step 4: Checking if seed data is already present..."
EXISTING_USERS=$(run_admin_sql -D ecommerce_store -sse "SELECT COUNT(*) FROM users;" || echo "0")

if [ "$EXISTING_USERS" -eq "0" ]; then
  echo "Database is empty. Applying seed data (seed.sql)..."
  run_admin_sql -D ecommerce_store < "$REPO_ROOT/db/seed.sql"
  echo "✅ Seed data applied successfully."
else
  echo "ℹ️ Database already has $EXISTING_USERS user(s). Skipping seed.sql to prevent duplicate key errors."
fi

# ------------------------------------------------------------------------------
# 5. Verify App User Connection & Query Data
# ------------------------------------------------------------------------------
echo "👉 Step 5: Testing connectivity and query permissions with application user (ecommerce_user)..."
APP_VERIFY=$(MYSQL_PWD="hello123@" mysql \
  --host="$MYSQL_HOST" \
  --user="ecommerce_user" \
  --ssl-mode=REQUIRED \
  --database="ecommerce_store" \
  -sse "SELECT CONCAT('Categories: ', (SELECT COUNT(*) FROM categories), ' | Products: ', (SELECT COUNT(*) FROM products), ' | Users: ', (SELECT COUNT(*) FROM users));")

echo "✅ App user verified successfully!"
echo "📊 Database Summary: $APP_VERIFY"
echo "🎉 All database initialization steps completed successfully!"
