# 📦 PostgreSQL Database Migration Script

This project provides a **Dockerized Bash script** to automate transferring all tables and data from a **source** PostgreSQL database to a **target** PostgreSQL database.

The script:

- Dumps the **entire source database** (schema and data) in custom format.
- Creates the **target database** if it doesn't exist.
- Restores the dump into the target database.
- Verifies the number of tables after migration.
- Cleans up temporary files.

---

## 🚀 How It Works

1. Reads database connection details from environment variables (or a `.env` file).
2. Dumps the source database to a temporary file.
3. Restores the dump into the target database.
4. Validates the migration by comparing table counts.
5. Deletes temporary dump files.

---

## 🛠 Prerequisites

- Docker installed
- Access to `.env` file containing required environment variables.

---

## ⚙️ Environment Variables

The following environment variables must be set **either via a `.env` file** or through the cloud environment configuration:

| Variable Name     | Description                                           |
| :---------------- | :---------------------------------------------------- |
| `SOURCE_HOST`     | Host of the source PostgreSQL server                  |
| `SOURCE_PORT`     | Port of the source PostgreSQL server (default `5432`) |
| `SOURCE_DB`       | Name of the source database                           |
| `SOURCE_USER`     | Username for the source database                      |
| `SOURCE_PASSWORD` | Password for the source database                      |
| `TARGET_HOST`     | Host of the target PostgreSQL server                  |
| `TARGET_PORT`     | Port of the target PostgreSQL server (default `5432`) |
| `TARGET_DB`       | Name of the target database                           |
| `TARGET_USER`     | Username for the target database                      |
| `TARGET_PASSWORD` | Password for the target database                      |

**Example `.env` file:**

```env
SOURCE_HOST=source-db.example.com
SOURCE_PORT=5432
SOURCE_DB=my_source_db
SOURCE_USER=source_user
SOURCE_PASSWORD=source_password

TARGET_HOST=target-db.example.com
TARGET_PORT=5432
TARGET_DB=my_target_db
TARGET_USER=target_user
TARGET_PASSWORD=target_password
```

---

## 🐳 Docker Build and Run Instructions

1. **Ensure your project directory contains:**

   - `Dockerfile`
   - `transfer_postgres_db.sh`
   - `.env`

2. **Build the Docker image:**

   ```bash
   docker build -t pg-db-migrator .
   ```

3. **Run the Docker container:**

   In your cloud platform (or locally if testing), make sure `.env` is copied inside the Docker image OR set environment variables appropriately.

   Example if you could control Docker run (for local testing):

   ```bash
   docker run --env-file .env pg-db-migrator
   ```
