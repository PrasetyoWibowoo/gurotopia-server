# Dockerfile for Gurotopia GTPS
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libmysqlclient-dev \
    pkg-config \
    libenet-dev \
    libfmt-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build Gurotopia
RUN mkdir -p build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)

# Expose ports
EXPOSE 17091
EXPOSE 17092

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -z localhost 17091 || exit 1

# Run server
WORKDIR /app/build
CMD ["./Gurotopia"]
