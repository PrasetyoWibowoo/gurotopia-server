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
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY . . 

RUN make && chmod +x main.out

# Rename config.json to template
RUN mv config.json config. json.template || true

RUN cat > /start.sh <<'EOF'
#!/bin/bash
set -e

echo "=== ENVIRONMENT VARIABLES DEBUG ==="
echo "MYSQL_HOST = [$MYSQL_HOST]"
echo "MYSQL_PORT = [$MYSQL_PORT]"
echo "MYSQL_USER = [$MYSQL_USER]"
echo "MYSQL_DATABASE = [$MYSQL_DATABASE]"
echo "===================================="

MYSQL_HOST=${MYSQL_HOST:-mysql.railway.internal}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_DATABASE=${MYSQL_DATABASE:-railway}

echo "Using MYSQL_HOST:  $MYSQL_HOST"
echo "Using MYSQL_PORT: $MYSQL_PORT"

echo "Waiting for MySQL at $MYSQL_HOST:$MYSQL_PORT..."
until nc -z "$MYSQL_HOST" "$MYSQL_PORT"; do
  echo "MySQL is unavailable - sleeping"
  sleep 2
done

echo "MySQL is up!"
echo "===================================="

# Substitute environment variables in config.json
if [ -f config.json.template ]; then
  echo "Generating config.json from template..."
  envsubst < config.json.template > config.json
  echo "Config generated:"
  cat config.json
  echo "===================================="
fi

echo "Starting Growtopia server..."
./main.out 2>&1 || {
  echo "===================================="
  echo "ERROR:  Server crashed with exit code $?"
  echo "===================================="
  # Check for log files
  find /app -name "*.log" -exec echo "Log file: {}" \; -exec tail -50 {} \;
  # Keep container alive for debugging
  echo "Container will stay alive for 1 hour for debugging..."
  sleep 3600
  exit 1
}
EOF

RUN chmod +x /start.sh

EXPOSE 17091

CMD ["/start.sh"]
