# Dockerfile for Gurotopia GTPS (No CMake)
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    g++ \
    git \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    libmysqlclient-dev \
    libenet-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy all source files
COPY . .

# Check structure (for debugging)
RUN ls -la && \
    echo "=== Checking for Makefile ===" && \
    find . -name "Makefile" -o -name "makefile"

# Build using Makefile
# Gurotopia uses direct Makefile, not CMake
RUN if [ -f Makefile ]; then \
        echo "Building with Makefile..." && \
        make -j$(nproc); \
    elif [ -f src/Makefile ]; then \
        echo "Building in src directory..." && \
        cd src && make -j$(nproc); \
    else \
        echo "ERROR: No Makefile found!" && \
        exit 1; \
    fi

# Find the compiled binary
RUN echo "=== Finding binary ===" && \
    find .  -type f -executable -name "*urotopia*" -o -name "server" -o -name "gtps"

# Expose ports
EXPOSE 17091
EXPOSE 17092
EXPOSE 17093

# Run server
# Adjust binary name based on actual output
CMD if [ -f "./Gurotopia" ]; then \
        ./Gurotopia; \
    elif [ -f "./server" ]; then \
        ./server; \
    elif [ -f "./gtps" ]; then \
        ./gtps; \
    elif [ -f "./bin/Gurotopia" ]; then \
        ./bin/Gurotopia; \
    elif [ -f "./build/Gurotopia" ]; then \
        ./build/Gurotopia; \
    else \
        echo "ERROR: Binary not found!" && \
        find . -type f -executable && \
        exit 1; \
    fi
