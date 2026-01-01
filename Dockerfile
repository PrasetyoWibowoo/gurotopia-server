FROM ubuntu:23.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install dependencies dengan GCC yang support C++23
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    gcc-13 \
    g++-13 \
    libssl-dev \
    openssl \
    libsqlite3-dev \
    sqlite3 \
    libmysqlclient-dev \
    pkg-config \
    netcat-openbsd \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 \
    && rm -rf /var/lib/apt/lists/*

# Copy source
COPY . .

# Compile dengan GCC-13
RUN make clean || true && \
    CXX=g++-13 CC=gcc-13 make -j$(nproc) && \
    chmod +x main.out && \
    ls -lah main.out

EXPOSE 17091
EXPOSE 17092

CMD ["sh", "-c", "echo '=== Gurotopia Starting ===' && ./main.out 2>&1"]
