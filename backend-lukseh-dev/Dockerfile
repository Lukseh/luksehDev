# Lukseh.dev Backend Dockerfile
FROM oven/bun:latest
WORKDIR /app
RUN apt-get update -y && apt-get install -y openssl
COPY . .
RUN bun install
RUN bun run prisma migrate deploy
RUN bun build src/index.ts --outdir dist
EXPOSE 3000
CMD ["bun", "run", "dist/index.js"]
