FROM ubuntu:24.04

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js + C++ build tools
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
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY .  . 

# Build game server
RUN make && chmod +x main.out

# Install Node.js dependencies for proxy
RUN npm install ws

RUN mv config. json config.json.template || true

RUN cat > /start.sh <<'EOF'
#!/bin/bash
set -e

echo "=== ENVIRONMENT VARIABLES ==="
echo "MYSQLHOST = [$MYSQLHOST]"
echo "PORT = [$PORT]"
echo "============================="

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

# Generate config
if [ -f config.json. template ]; then
  envsubst < config.json.template > config.json
  echo "✓ Config generated"
fi

# Start game server on localhost
echo "Starting game server on localhost: 17091..."
./main.out &
SERVER_PID=$!

sleep 5

if netstat -tuln | grep -q ":17091"; then
  echo "✓ Game server listening on port 17091"
else
  echo "✗ WARNING: Game server not listening"
fi

# Start WebSocket proxy on Railway PORT
echo "Starting WebSocket proxy on port ${PORT:-8080}..."
node proxy.js &
PROXY_PID=$!

sleep 3
echo "✓ WebSocket proxy running (PID: $PROXY_PID)"

echo "============================="
echo "🚀 All services ready!"
echo "============================="

# Monitor both processes
while kill -0 $SERVER_PID 2>/dev/null && kill -0 $PROXY_PID 2>/dev/null; do
  sleep 60
  echo "[$(date +%H:%M:%S)] Server & Proxy running"
done

echo "ERROR: Process died!"
exit 1
EOF

RUN chmod +x /start.sh

# Railway auto-assigns PORT
EXPOSE 8080

CMD ["/start.sh"]
