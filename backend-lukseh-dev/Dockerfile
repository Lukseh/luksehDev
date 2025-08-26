# Lukseh.dev Backend Dockerfile
FROM oven/bun:latest
WORKDIR /app
RUN apt-get update -y && apt-get install -y openssl netcat-openbsd
COPY . .
RUN bunx prisma generate --schema=prisma/schema.prisma
RUN bun install
RUN bun build src/index.ts --outdir dist --target bun
EXPOSE 3000
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
