# Base image with PostgreSQL client tools
FROM postgres:15

# Set working directory
WORKDIR /app

# Install any additional tools we might need
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the transfer script
COPY transfer_postgres_db.sh /app/

# Make the script executable
RUN chmod +x /app/transfer_postgres_db.sh

# Set the script as the entrypoint
ENTRYPOINT ["/bin/bash", "-c", "if [ -f /app/.env ]; then set -a; . /app/.env; set +a; fi; exec /app/transfer_postgres_db.sh"]