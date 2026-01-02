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
    socat \
    && rm -rf /var/lib/apt/lists/*

COPY .  .    

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

MYSQLHOST=${MYSQLHOST:-mysql. railway.internal}
MYSQLPORT=${MYSQLPORT:-3306}
MYSQLUSER=${MYSQLUSER:-root}
MYSQLDATABASE=${MYSQLDATABASE:-railway}

export MYSQL_HOST=$MYSQLHOST
export MYSQL_PORT=$MYSQLPORT
export MYSQL_USER=$MYSQLUSER
export MYSQL_PASSWORD=$MYSQLPASSWORD
export MYSQL_DATABASE=$MYSQLDATABASE

echo "Using MYSQL_HOST: $MYSQL_HOST"
echo "Using MYSQL_PORT: $MYSQL_PORT"
echo "Using MYSQL_USER: $MYSQL_USER"

echo "Waiting for MySQL at $MYSQL_HOST:$MYSQL_PORT..."
until nc -z "$MYSQL_HOST" "$MYSQL_PORT"; do
  echo "MySQL is unavailable - sleeping"
  sleep 2
done

echo "MySQL is up!"
echo "===================================="

if [ -f config.json. template ]; then
  echo "Generating config.json from template..."
  
  # Change server port to localhost only since we'll proxy it
  export SERVER_HOST="127.0.0.1"
  export SERVER_PORT="17091"
  
  envsubst < config.json.template > config.json
  echo "Config generated:"
  cat config.json
  echo "===================================="
fi

echo "Starting Growtopia server on localhost:17091..."
./main.out &
SERVER_PID=$! 

echo "Server process started with PID: $SERVER_PID"
echo "Waiting for server to bind to port..."
sleep 5

# Check if server is listening
if netstat -tuln | grep -q ":17091"; then
  echo "✓ Server listening on port 17091"
else
  echo "✗ WARNING: Server not listening on port 17091"
fi

echo "===================================="
echo "Server is ready!"
echo "===================================="

# Monitor server
while kill -0 $SERVER_PID 2>/dev/null; do
  sleep 60
  echo "[$(date +%H:%M:%S)] Server still running (PID: $SERVER_PID)"
done

echo "ERROR: Server process died!"
exit 1
EOF

RUN chmod +x /start.sh

EXPOSE 17091

CMD ["/start.sh"]
