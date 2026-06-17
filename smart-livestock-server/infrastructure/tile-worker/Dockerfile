FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq sqlite3 ca-certificates gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*
COPY infrastructure/tile-worker/entrypoint.sh /entrypoint.sh
COPY infrastructure/tile-worker/generate_mbtiles.py /tooling/generate_mbtiles.py
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
