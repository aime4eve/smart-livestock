# tileserver-gl 部署操作指导

**日期**: 2026-05-17
**适用环境**: 国内服务器 (172.22.1.123) + Docker snap
**关联设计**: `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md`

---

## 概述

本文档指导手工完成以下工作：

1. 从 OSM 下载离线瓦片并打包为 MBTiles
2. 上传 MBTiles 到服务器
3. 用 Docker 部署 tileserver-gl 并验证

### 服务器环境约束

服务器 Docker 是 **snap 版本**（根目录 `/var/snap/docker/`），bind mount 只允许 `/home/` 和 `/media/` 下的路径。因此：

- 数据目录放在 `/home/agentic/tileserver-data/`
- 项目代码在 `/data/agentic/` 下的路径**不能**用于 Docker volume

---

## 第一步：下载离线瓦片

在**本机**（能访问 tile.openstreetmap.org 的环境）执行。

### 工具脚本

使用 `tooling/download_mbtiles.py`（见附录 A）：

```bash
python3 tooling/download_mbtiles.py \
  --bbox 112.8,28.1,113.1,28.4 \
  --zoom 11-15 \
  --output changsha.mbtiles
```

### 参数说明

| 参数 | 含义 | 示例 |
|------|------|------|
| `--bbox` | min_lon,min_lat,max_lon,max_lat | `112.8,28.1,113.1,28.4`（长沙） |
| `--zoom` | 缩放级别范围 | `11-15`（牧场全景到围栏细节） |
| `--output` | 输出 MBTiles 文件名 | `changsha.mbtiles` |

### 常用城市 bbox

| 城市 | bbox | zoom 11-15 瓦片数（约） |
|------|------|------------------------|
| 长沙 | `112.8,28.1,113.1,28.4` | 2000 |
| 北京 | `116.1,39.7,116.7,40.1` | 4000 |
| 上海 | `121.3,31.0,121.7,31.5` | 3000 |
| 乌鲁木齐 | `87.4,43.6,87.8,43.9` | 2000 |
| 呼和浩特 | `111.5,40.6,111.9,40.9` | 2000 |

> 自定义区域：在 https://boundingbox.klokantech.com/ 画框获取坐标。

### 下载耗时参考

- 单张瓦片下载 + OSM ToS 限速（0.3s/张）
- zoom 11-15 长沙市区约 2000 张，耗时约 10 分钟
- zoom 范围越大，瓦片数指数增长（zoom 16 是 zoom 15 的 4 倍）

### 验证下载结果

```bash
ls -lh changsha.mbtiles

sqlite3 changsha.mbtiles "SELECT COUNT(*) FROM tiles;"
```

---

## 第二步：上传到服务器

```bash
scp changsha.mbtiles agentic@172.22.1.123:~/tileserver-data/

# 多个区域
scp beijing.mbtiles agentic@172.22.1.123:~/tileserver-data/
```

### 更新 config.json

每次添加新 MBTiles 文件后，更新服务器上的 config.json：

```bash
ssh agentic@172.22.1.123

cd ~/tileserver-data

# 自动扫描 *.mbtiles 生成 config.json
python3 -c "
import json, glob
files = sorted(glob.glob('*.mbtiles'))
config = {
    'data': {
        f.replace('.mbtiles', ''): {'mbtiles': f}
        for f in files
    }
}
json.dump(config, open('config.json', 'w'), indent=2)
print(json.dumps(config, indent=2))
"
```

生成示例（两个区域）：

```json
{
  "data": {
    "beijing": {
      "mbtiles": "beijing.mbtiles"
    },
    "changsha": {
      "mbtiles": "changsha.mbtiles"
    }
  }
}
```

### 验证数据完整性

```bash
# 本机生成 MD5
md5 changsha.mbtiles          # macOS
md5sum changsha.mbtiles       # Linux

# 服务器端检查
ssh agentic@172.22.1.123 "md5sum ~/tileserver-data/changsha.mbtiles"
```

---

## 第三步：Docker 部署 tileserver-gl

### 3.1 确认数据文件

```bash
ssh agentic@172.22.1.123 "ls -la ~/tileserver-data/"
# 应看到：changsha.mbtiles, config.json
```

### 3.2 修改 docker-compose.yml

在服务器上编辑 `~/smart-livestock-server/docker-compose.yml`，确保 tileserver 部分为：

```yaml
  tileserver:
    image: maptiler/tileserver-gl:latest
    volumes:
      - /home/agentic/tileserver-data:/data
    command: /data/config.json
    restart: unless-stopped
```

**关键点：**
- `volumes` 必须用绝对路径 `/home/agentic/tileserver-data:/data`（snap Docker 只允许 /home/ 路径）
- `command` 是 `/data/config.json`（tileserver-gl v5.x 不需要 `--port` 参数，默认 8080）
- **不要**加 `ports` 映射（服务器 Docker `iptables=false`，端口映射不生效，通过 nginx 代理访问）

### 3.3 修改 nginx 代理

编辑 `~/smart-livestock-server/infrastructure/nginx/nginx.conf`，瓦片代理路径改为：

```nginx
location /tiles/ {
    proxy_pass http://tileserver:8080/data/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    add_header Cache-Control "public, max-age=2592000";
}
```

> `proxy_pass` 末尾的 `/` 不能省略，它将 `/tiles/xxx` 映射为 `/data/xxx`。

### 3.4 启动服务

```bash
ssh agentic@172.22.1.123

cd ~/smart-livestock-server

# 全部重启（确保网络初始化正确）
docker compose down
docker compose up -d

# 等待所有服务启动
sleep 15
```

### 3.5 验证部署

**检查 tileserver 日志：**

```bash
docker logs smart-livestock-server-tileserver-1 2>&1 | tail -10
# 应看到 "Listening at http://[::]:8080/"
```

**检查容器内数据文件：**

```bash
docker exec smart-livestock-server-tileserver-1 ls -la /data/
# 应看到 changsha.mbtiles 和 config.json
```

**检查 tileserver 健康状态：**

```bash
docker exec smart-livestock-server-tileserver-1 curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/
# 应返回 200
```

**检查 nginx -> tileserver 连通性：**

```bash
docker exec smart-livestock-server-nginx-1 curl -s -o /dev/null -w '%{http_code}' http://tileserver:8080/
# 应返回 200
```

**测试瓦片请求（长沙 zoom 13）：**

```bash
# 通过 nginx 代理（从外部，本机执行）
curl -s -o /dev/null -w '%{http_code}' \
  "http://172.22.1.123:18080/tiles/changsha/13/6743/3436.png"
# 应返回 200
```

### 3.6 如果容器内 /data 为空

这是 Docker snap bind mount 限制的表现。排查步骤：

```bash
# 1. 确认路径在 /home/ 下
echo "Source: /home/agentic/tileserver-data"

# 2. 确认 Docker 版本
docker info | grep "Docker Root Dir"
# 显示 /var/snap/docker/ 则是 snap 版本

# 3. 确认 docker-compose.yml 中 volumes 是绝对路径
grep 'volumes:' -A2 ~/smart-livestock-server/docker-compose.yml | grep tileserver -A2
# 应该是：- /home/agentic/tileserver-data:/data

# 4. 强制重建
docker compose down
docker compose up -d --force-recreate
sleep 10
docker exec smart-livestock-server-tileserver-1 ls -la /data/
```

如果仍然为空，改用**附录 B 的非 Docker 部署**。

---

## 第四步：更新 Flutter 瓦片源 URL

tileserver-gl 部署成功后，更新 Flutter 端的瓦片 URL。

编辑 `Mobile/mobile_app/lib/core/map/map_config.dart`：

```dart
static const String selfHostedTileUrl =
    'http://172.22.1.123:18080/tiles/changsha/{z}/{x}/{y}.png';
```

> URL 中的 `changsha` 对应 config.json 中的数据集名称。多区域时需要根据当前牧场动态选择。

---

## 故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| 容器内 /data 为空 | Docker snap 限制 | 数据必须在 `/home/` 下 |
| "No input file found" | config.json 未找到或格式错误 | 检查容器内 `/data/config.json` |
| "paths[1] argument error" | config.json 格式不兼容 v5.x | 用 `{"data": {"name": {"mbtiles": "file.mbtiles"}}}` 格式 |
| nginx 返回 502 | nginx 无法连接 tileserver | 检查 Docker 网络（`docker compose down && up`） |
| 瓦片返回 200 但图片空白 | MBTiles 中无此瓦片（超出 bbox） | 检查请求的 z/x/y 是否在下载范围内 |
| 瓦片 404 | proxy_pass 路径不匹配 | 确认 nginx `proxy_pass` 末尾有 `/` |

---

## 附录 A：download_mbtiles.py 脚本

如果 `tooling/download_mbtiles.py` 不存在，手动创建：

```python
#!/usr/bin/env python3
"""从 OSM CDN 下载瓦片并打包成 MBTiles。"""
import argparse, math, os, sqlite3, time
from urllib.request import urlopen, Request

def lat_lon_to_tile(lat, lon, zoom):
    n = 2 ** zoom
    x = int((lon + 180) / 360 * n)
    lat_rad = math.radians(lat)
    y = int((1 - math.asinh(math.tan(lat_rad)) / math.pi) / 2 * n)
    return max(0, min(x, n - 1)), max(0, min(y, n - 1))

def download_mbtiles(bbox, zoom_range, output):
    min_lon, min_lat, max_lon, max_lat = [float(v) for v in bbox.split(",")]
    min_zoom, max_zoom = [int(v) for v in zoom_range.split("-")]
    if os.path.exists(output): os.remove(output)
    conn = sqlite3.connect(output)
    conn.execute("CREATE TABLE metadata (name text, value text)")
    conn.execute("CREATE TABLE tiles (zoom_level int, tile_column int, tile_row int, tile_data blob)")
    conn.execute("CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row)")
    conn.execute("INSERT INTO metadata VALUES ('name', ?)", (os.path.basename(output),))
    conn.execute("INSERT INTO metadata VALUES ('format', 'png')")
    conn.execute("INSERT INTO metadata VALUES ('bounds', ?)", (f"{min_lon},{min_lat},{max_lon},{max_lat}",))
    conn.commit()
    done, errors, total = 0, 0, 0
    for z in range(min_zoom, max_zoom + 1):
        x0, y0 = lat_lon_to_tile(max_lat, min_lon, z)
        x1, y1 = lat_lon_to_tile(min_lat, max_lon, z)
        total += (x1 - x0 + 1) * (y1 - y0 + 1)
    for z in range(min_zoom, max_zoom + 1):
        x0, y0 = lat_lon_to_tile(max_lat, min_lon, z)
        x1, y1 = lat_lon_to_tile(min_lat, max_lon, z)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                tms_y = (2 ** z - 1) - y
                url = f"https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                try:
                    req = Request(url, headers={"User-Agent": "SmartLivestock/1.0"})
                    data = urlopen(req, timeout=10).read()
                    conn.execute("INSERT INTO tiles VALUES (?, ?, ?, ?)", (z, x, tms_y, data))
                except Exception as e:
                    errors += 1
                    if errors <= 5: print(f"  ERR {url}: {e}")
                done += 1
                if done % 50 == 0:
                    conn.commit()
                    print(f"  {done}/{total} ({errors} errors)")
                time.sleep(0.3)
        conn.commit()
    conn.commit()
    conn.close()
    print(f"Done: {output} ({done-errors}/{total}, {errors} errors, {os.path.getsize(output)/1024/1024:.1f} MB)")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--bbox", required=True, help="min_lon,min_lat,max_lon,max_lat")
    p.add_argument("--zoom", default="11-15")
    p.add_argument("--output", required=True)
    a = p.parse_args()
    download_mbtiles(a.bbox, a.zoom, a.output)
```

---

## 附录 B：非 Docker 部署（备选方案）

如果 Docker snap 的 bind mount 始终无法工作，可在宿主机直接运行 tileserver-gl：

```bash
# 1. 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. 安装 tileserver-gl
sudo npm install -g tileserver-gl

# 3. 测试启动
cd ~/tileserver-data && tileserver-gl --port 8083

# 4. 注册 systemd 服务
sudo tee /etc/systemd/system/tileserver-gl.service << 'EOF'
[Unit]
Description=TileServer GL
After=network.target

[Service]
Type=simple
User=agentic
WorkingDirectory=/home/agentic/tileserver-data
ExecStart=/usr/bin/tileserver-gl --port 8083
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tileserver-gl
sudo systemctl start tileserver-gl
```

非 Docker 方式下，nginx 代理改为：

```nginx
location /tiles/ {
    proxy_pass http://172.22.1.123:8083/data/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    add_header Cache-Control "public, max-age=2592000";
}
```

---

*Generated: 2026-05-17*
