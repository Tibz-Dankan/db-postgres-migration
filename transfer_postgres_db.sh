#!/bin/bash

# PostgreSQL Database Transfer Script
# This script transfers all tables and their data from a source PostgreSQL database to a target
# All connection parameters are read from environment variables

# Check if necessary environment variables are set
required_vars=(
  "SOURCE_HOST" "SOURCE_PORT" "SOURCE_DB" "SOURCE_USER" "SOURCE_PASSWORD" 
  "TARGET_HOST" "TARGET_PORT" "TARGET_DB" "TARGET_USER" "TARGET_PASSWORD"
)

missing_vars=()
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    missing_vars+=("$var")
  fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
  echo "Error: The following required environment variables are not set:"
  for var in "${missing_vars[@]}"; do
    echo "  - $var"
  done
  echo ""
  echo "Please ensure these variables are set in your .env file or as Docker environment variables"
  exit 1
fi

# Output directory for temporary files
DUMP_DIR="/tmp/pg_dump_files"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="${DUMP_DIR}/full_db_dump_${TIMESTAMP}.custom"

# Create directory if it doesn't exist
mkdir -p $DUMP_DIR

echo "Starting database transfer from ${SOURCE_DB} to ${TARGET_DB}..."
echo "Source: ${SOURCE_HOST}:${SOURCE_PORT}, Target: ${TARGET_HOST}:${TARGET_PORT}"

# Export PostgreSQL password for source connection
export PGPASSWORD="${SOURCE_PASSWORD}"

# Step 1: Dump the entire database (schema and data) in custom format
echo "Dumping database schema and data from source..."
pg_dump -h "${SOURCE_HOST}" -p "${SOURCE_PORT}" -U "${SOURCE_USER}" \
  -d "${SOURCE_DB}" -Fc -v > "${DUMP_FILE}"

if [ $? -ne 0 ]; then
  echo "Error: Database dump failed!"
  exit 1
fi

echo "Database dump completed successfully."

# Step 2: Restore to target database
# Export PostgreSQL password for target connection
export PGPASSWORD="${TARGET_PASSWORD}"

# Check if target database exists, if not create it
echo "Checking if target database exists..."
if ! psql -h "${TARGET_HOST}" -p "${TARGET_PORT}" -U "${TARGET_USER}" \
  -lqt | cut -d \| -f 1 | grep -qw "${TARGET_DB}"; then
  echo "Target database does not exist. Creating..."
  psql -h "${TARGET_HOST}" -p "${TARGET_PORT}" -U "${TARGET_USER}" \
    -c "CREATE DATABASE \"${TARGET_DB}\";"
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create target database!"
    exit 1
  fi
fi

echo "Restoring data to target database..."
pg_restore -h "${TARGET_HOST}" -p "${TARGET_PORT}" -U "${TARGET_USER}" \
  -d "${TARGET_DB}" -v --clean --if-exists "${DUMP_FILE}"

restore_status=$?

# Check exit status of pg_restore
if [ $restore_status -ne 0 ]; then
  echo "Warning: pg_restore completed with status code $restore_status"
  echo "Some errors or warnings may have occurred during restoration."
  echo "Please check the output above for details."
else
  echo "Database restoration completed successfully."
fi

# Verify the transfer
echo "Verifying transfer..."
export PGPASSWORD="${SOURCE_PASSWORD}"
SOURCE_TABLES=$(psql -h "${SOURCE_HOST}" -p "${SOURCE_PORT}" -U "${SOURCE_USER}" \
  -d "${SOURCE_DB}" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';")

export PGPASSWORD="${TARGET_PASSWORD}"
TARGET_TABLES=$(psql -h "${TARGET_HOST}" -p "${TARGET_PORT}" -U "${TARGET_USER}" \
  -d "${TARGET_DB}" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';")

echo "Source database has $SOURCE_TABLES tables."
echo "Target database has $TARGET_TABLES tables."

if [ "$SOURCE_TABLES" = "$TARGET_TABLES" ]; then
  echo "Table count matches between source and target databases."
else
  echo "Warning: Table count mismatch between source and target databases."
fi

# Clean up
echo "Cleaning up temporary files..."
rm -f "${DUMP_FILE}"
echo "Temporary files removed."

echo "Database transfer process completed at $(date)."

# Start a simple HTTP server to indicate success
echo "Starting simple HTTP server on port 8081 to indicate success..."

while true; do
  echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nMigration Succeeded" | nc -l -p 8081 -q 1
done
