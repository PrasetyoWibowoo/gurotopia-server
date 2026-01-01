FROM debian:bookworm

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    make \
    g++ \
    libssl-dev \
    libsqlite3-dev \
    default-libmysqlclient-dev \
    libenet-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . .

# Build the application
RUN make

# Verify the executable exists
RUN ls -la main.out && file main.out

# Make it executable (just in case)
RUN chmod +x main.out

# Run the application
CMD ["./main. out"]
