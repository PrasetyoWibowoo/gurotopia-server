FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install dependencies sesuai dokumentasi Gurotopia
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    gcc \
    g++ \
    libssl-dev \
    openssl \
    libsqlite3-dev \
    sqlite3 \
    libmysqlclient-dev \
    default-libmysqlclient-dev \
    pkg-config \
    netcat-openbsd \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . . 

# Compile (sama seperti dokumentasi)
RUN make clean || true && \
    make -j$(nproc) && \
    chmod +x main.out && \
    ls -lah main.out

# Expose ports
EXPOSE 17091
EXPOSE 17092

# Run dengan output logs
CMD ["sh", "-c", "echo '=== Gurotopia Server Starting ===' && \
     echo 'Working Directory: ' && pwd && \
     echo 'Binary Info:' && ls -lah main.out && \
     echo 'Environment Variables:' && env | grep MYSQL || echo 'No MYSQL vars' && \
     echo 'Starting server.. .' && \
     ./main. out 2>&1"]
