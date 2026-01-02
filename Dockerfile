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
    net-tools \
    && rm -rf /var/lib/apt/lists/*

COPY .  . 

RUN make && chmod +x main.out

RUN mv config.json config.json.template || true

RUN cat > /start.sh <<'EOF'
#!/bin/bash
set -e

echo "=== ENVIRONMENT VARIABLES ==="
echo "MYSQLHOST = [$MYSQLHOST]"
echo "PORT = [$PORT]"
echo "============================="

# Get Railway PORT or default to 17091
SERVER_PORT=${PORT:-17091}

# MySQL setup
MYSQLHOST=${MYSQLHOST:-mysql. railway.internal}
MYSQLPORT=${MYSQLPORT:-3306}
MYSQLUSER=${MYSQLUSER:-root}
MYSQLDATABASE=${MYSQLDATABASE:-railway}

export MYSQL_HOST=$MYSQLHOST
export MYSQL_PORT=$MYSQLPORT
export MYSQL_USER=$MYSQLUSER
export MYSQL_PASSWORD=$MYSQLPASSWORD
export MYSQL_DATABASE=$MYSQLDATABASE

# Wait for MySQL
echo "Waiting for MySQL..."
until nc -z "$MYSQL_HOST" "$MYSQL_PORT"; do
  sleep 2
done
echo "✓ MySQL connected"

# Generate config with dynamic port
if [ -f "config.json.template" ]; then
  export SERVER_HOST="0.0.0.0"
  export SERVER_PORT=$SERVER_PORT
  
  envsubst < config.json.template > config.json
  
  # Force update port in config
  sed -i "s/\"port\"[[:space:]]*:[[:space:]]*[0-9]*/\"port\":  $SERVER_PORT/" config.json
  
  echo "✓ Config generated with port $SERVER_PORT"
  echo "--- Config content:  ---"
  cat config.json
  echo "--- End config ---"
fi

echo "============================="
echo "Starting server on 0.0.0.0:$SERVER_PORT..."
./main.out 2>&1 &
SERVER_PID=$! 

sleep 5

# Check if listening
echo "Checking listening ports..."
if netstat -tuln | grep ":$SERVER_PORT"; then
  echo "✓ Server LISTENING on port $SERVER_PORT"
  netstat -tuln | grep ": $SERVER_PORT"
else
  echo "✗ Server NOT listening on port $SERVER_PORT"
  echo "All listening ports:"
  netstat -tuln
fi

echo "============================="
echo "🚀 Server ready on port $SERVER_PORT!"
echo "============================="

# Monitor
while kill -0 $SERVER_ID 2>/dev/null; do
  sleep 60
  echo "[$(date +%H:%M:%S)] Server running (PID: $SERVER_PID)"
done

echo "ERROR: Server died!"
exit 1
EOF

RUN chmod +x /start.sh

EXPOSE 17091

CMD ["/start.sh"]
