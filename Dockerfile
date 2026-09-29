ARG BUN_VERSION='1.4'

FROM oven/bun:${BUN_VERSION}-debian AS build

WORKDIR /app

COPY package.json bun.lock tsconfig.json ./
COPY src ./src

RUN bun install --frozen-lockfile

FROM oven/bun:${BUN_VERSION}-debian

WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./
COPY --from=build /app/bun.lock ./
COPY --from=build /app/src ./src
COPY --from=build /app/tsconfig.json ./

ARG PG_VERSION='18'

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
    install -d /etc/apt/keyrings && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /etc/apt/keyrings/postgresql.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt $(. /etc/os-release && echo $VERSION_CODENAME)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-${PG_VERSION} && \
    rm -rf /var/lib/apt/lists/*

CMD pg_isready --dbname=$DATABASE_URL && \
    pg_dump --version && \
    bun run src/index.ts
