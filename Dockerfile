FROM ubuntu:23.04

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libsqlite3-dev \
    libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN make -j$(nproc)

EXPOSE 17091

CMD ["./main.out"]
