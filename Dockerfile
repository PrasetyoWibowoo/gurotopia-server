# Dockerfile untuk Gurotopia
FROM ubuntu: 22.04

# Set working directory SEBELUM copy
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libsqlite3-dev \
    libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . .

# Build dengan Makefile
RUN make -j$(nproc)

# Expose ports
EXPOSE 17091
EXPOSE 17092

# Run server
CMD ["./main.out"]
