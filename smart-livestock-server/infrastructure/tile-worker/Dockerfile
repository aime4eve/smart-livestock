FROM docker:cli AS docker-cli
FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq sqlite3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
# Docker CLI comes from the official cli image instead of apt: build hosts
# with restricted networks can reach the registry but not download.docker.com.
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker
COPY infrastructure/tile-worker/entrypoint.sh /entrypoint.sh
COPY infrastructure/tile-worker/generate_mbtiles.py /tooling/generate_mbtiles.py
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
