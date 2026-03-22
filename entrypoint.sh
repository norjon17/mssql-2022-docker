#!/bin/bash

# Ensure data dir exists with correct permissions for SQL Server
mkdir -p /var/opt/mssql/data
chown -R 10001:10001 /var/opt/mssql/data

# Backups folder is shared with host user, leave permissions as-is
mkdir -p /var/opt/mssql/backups

/opt/mssql/bin/sqlservr &
PID=$!

echo "Waiting for SQL Server to start..."
sleep 10

until /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -Q "SELECT 1" -b -C &>/dev/null; do
  echo "Still waiting..."
  sleep 3
done

echo "SQL Server ready. Running init.sql..."
sleep 2

/opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P "$MSSQL_SA_PASSWORD" \
  -C \
  -Q "IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '${APP_ADMIN_USER}') BEGIN CREATE LOGIN [${APP_ADMIN_USER}] WITH PASSWORD = '${APP_ADMIN_PASSWORD}', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF; ALTER SERVER ROLE [sysadmin] ADD MEMBER [${APP_ADMIN_USER}]; END"

echo "Done."
wait $PID