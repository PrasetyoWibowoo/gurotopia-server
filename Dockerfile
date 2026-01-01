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

RUN ls -la main.out && chmod +x main.out

# Create wait-for-mysql script
RUN echo '#!/bin/sh\n\
set -e\n\
\n\
host="$1"\n\
port="$2"\n\
shift 2\n\
\n\
echo "Waiting for MySQL at $host:$port..."\n\
\n\
until nc -z "$host" "$port"; do\n\
  echo "MySQL is unavailable - sleeping"\n\
  sleep 2\n\
done\n\
\n\
echo "MySQL is up - executing command"\n\
exec "$@"\n\
' > /wait-for-mysql.sh && chmod +x /wait-for-mysql.sh

# Use wait script before starting app
CMD ["/wait-for-mysql.sh", "${MYSQL_HOST}", "${MYSQL_PORT}", "./main.out"]
