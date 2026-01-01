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
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY . .   

RUN make && chmod +x main.out

RUN mv config.json config.json.template || true

RUN cat > /start.sh <<'EOF'
#!/bin/bash
set -e

echo "=== ENVIRONMENT VARIABLES DEBUG ==="
echo "MYSQLHOST = [$MYSQLHOST]"
echo "MYSQLPORT = [$MYSQLPORT]"
echo "MYSQLUSER = [$MYSQLUSER]"
echo "MYSQLDATABASE = [$MYSQLDATABASE]"
echo "===================================="

MYSQLHOST=${MYSQLHOST:-mysql.railway.internal}
MYSQLPORT=${MYSQLPORT:-3306}
MYSQLUSER=${MYSQLUSER:-root}
MYSQLDATABASE=${MYSQLDATABASE:-railway}

export MYSQL_HOST=$MYSQLHOST
export MYSQL_PORT=$MYSQLPORT
export MYSQL_USER=$MYSQLUSER
export MYSQL_PASSWORD=$MYSQLPASSWORD
export MYSQL_DATABASE=$MYSQLDATABASE

echo "Using MYSQL_HOST:   $MYSQL_HOST"
echo "Using MYSQL_PORT:  $MYSQL_PORT"
echo "Using MYSQL_USER:  $MYSQL_USER"

echo "Waiting for MySQL at $MYSQL_HOST:$MYSQL_PORT..."
until nc -z "$MYSQL_HOST" "$MYSQL_PORT"; do
  echo "MySQL is unavailable - sleeping"
  sleep 2
done

echo "MySQL is up!"
echo "===================================="

if [ -f config.json. template ]; then
  echo "Generating config.json from template..."
  envsubst < config.json.template > config.json
  echo "Config generated:"
  cat config.json
  echo "===================================="
fi

echo "Starting Growtopia server..."
echo "===================================="

# Start server in background
./main.out &
SERVER_PID=$!

echo "Server process started with PID: $SERVER_PID"
echo "Monitoring server status..."

# Monitor process
while kill -0 $SERVER_PID 2>/dev/null; do
  echo "[$(date +%H:%M:%S)] Server is running (PID: $SERVER_PID)"
  
  # Show any log files if they exist
  if ls *.log 2>/dev/null; then
    echo "--- Recent logs ---"
    tail -10 *.log 2>/dev/null | head -20
  fi
  
  sleep 30
done

echo "===================================="
echo "ERROR: Server process died!"
echo "Exit code: $?"
echo "===================================="

# Show final logs
find /app -name "*.log" -exec echo "=== {} ===" \; -exec cat {} \;

exit 1
EOF

RUN chmod +x /start.sh

EXPOSE 17091

CMD ["/start.sh"]
