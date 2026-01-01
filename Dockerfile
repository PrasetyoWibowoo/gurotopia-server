FROM ubuntu:22.04

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    g++ \
    libssl-dev \
    libsqlite3-dev \
    libmysqlclient-dev \
    pkg-config \
    netcat \
    && rm -rf /var/lib/apt/lists/*

COPY . . 

RUN make clean || true && \
    make -j$(nproc)

RUN chmod +x main. out

EXPOSE 17091
EXPOSE 17092

CMD ["./main.out"]
