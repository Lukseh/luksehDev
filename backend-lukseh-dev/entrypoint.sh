#!/bin/sh
# Wait for PostgreSQL to be available
until nc -z postgres 5432; do
  echo "Waiting for postgres..."
  sleep 1
done

# Run Prisma migrations
bun run prisma migrate deploy

# Start the backend app
bun run dist/index.js
