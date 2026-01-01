FROM ubuntu:latest

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libsqlite3-dev \
    libmysqlclient-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY . . 

RUN make -j$(nproc) && \
    chmod +x main.out && \
    ls -la main.out

EXPOSE 17091
EXPOSE 17092

# Debug output
RUN echo "=== Binary Info ===" && \
    file main.out && \
    ldd main.  out || true

# Run with output
CMD ["sh", "-c", "echo 'Starting Gurotopia.. .' && ./main.out"]
