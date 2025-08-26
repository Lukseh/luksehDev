FROM oven/bun:latest
WORKDIR /app
RUN apt-get update -y && apt-get install -y openssl netcat-openbsd
COPY . .
RUN bun install
RUN bunx prisma generate --schema=prisma/schema.prisma
RUN bun build src/index.ts --outdir dist --target bun
EXPOSE 3774
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]