FROM gcc:13

WORKDIR /app

RUN apt-get update && apt-get install -y \
    make \
    libssl-dev \
    libsqlite3-dev \
    libmysqlclient-dev \
    default-libmysqlclient-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN make -j$(nproc)

RUN chmod +x main.out

EXPOSE 17091

CMD ["./main.out"]
