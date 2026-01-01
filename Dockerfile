FROM ubuntu:24.04

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    make \
    g++ \
    libssl-dev \
    libsqlite3-dev \
    libmysqlclient-dev \
    libenet-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN make

RUN ls -la main.out && chmod +x main. out

# Create startup script dengan bash
COPY <<'EOF' /start.sh
#!/bin/bash
set -e

# Debug: Print all environment variables
echo "=== ENVIRONMENT VARIABLES DEBUG ==="
echo "MYSQL_HOST = [$MYSQL_HOST]"
echo "MYSQL_PORT = [$MYSQL_PORT]"
echo "MYSQL_USER = [$MYSQL_USER]"
echo "MYSQL_DATABASE = [$MYSQL_DATABASE]"
echo "===================================="

# Set defaults if empty
MYSQL_HOST=${MYSQL_HOST:-mysql.railway.internal}
MYSQL_PORT=${MYSQL_PORT:-3306}

echo "Using MYSQL_HOST: $MYSQL_HOST"
echo "Using MYSQL_PORT: $MYSQL_PORT"

# Wait for MySQL
echo "Waiting for MySQL at $MYSQL_HOST:$MYSQL_PORT..."
until nc -z "$MYSQL_HOST" "$MYSQL_PORT"; do
  echo "MySQL is unavailable - sleeping"
  sleep 2
done

echo "MySQL is up - starting server"
exec ./main.out
EOF

RUN chmod +x /start.sh

CMD ["/start.sh"]
