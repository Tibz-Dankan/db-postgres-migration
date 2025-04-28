# syntax = docker/dockerfile:1.2

FROM postgres:17

# Set working directory
WORKDIR /app

# Install any additional tools we might need
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=secret,id=_env,dst=/etc/secrets/.env cat /etc/secrets/.env    

# Copy .env file
COPY .env /app/.env

# Copy the transfer script
COPY transfer_postgres_db.sh /app/

# 👇 Expose port 8081
EXPOSE 8081

# Make the script executable
RUN chmod +x /app/transfer_postgres_db.sh

# Set the script as the entrypoint
ENTRYPOINT ["/bin/bash", "-c", "if [ -f /app/.env ]; then set -a; . /app/.env; set +a; fi; exec /app/transfer_postgres_db.sh"]