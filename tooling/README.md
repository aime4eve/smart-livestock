# Tooling — 离线瓦片工具集

用于下载、生成和部署 MBTiles 离线地图瓦片的脚本集合，配合 `tileserver-gl` 为智慧畜牧移动端提供离线地图服务。

## 文件说明

| 文件 | 用途 |
|------|------|
| `generate_mbtiles.py` | 从在线瓦片服务下载并打包为 MBTiles，支持单区域和计划模式 |
| `tile-download-plan.json` | 全球畜牧牧场瓦片下载计划（15 个区域） |
| `import_mbtiles.sh` | 将 MBTiles 部署到 tileserver-gl，含校验与自动配置 |

---

## generate_mbtiles.py

### 计划模式（推荐）

按计划文件批量下载多个区域，自动跳过已完成的区域，每个区域完成后更新计划文件。

```bash
# 预览计划（估算瓦片数和时间）
python3 tooling/generate_mbtiles.py --plan tooling/tile-download-plan.json --dry-run

# 执行全部下载
python3 tooling/generate_mbtiles.py --plan tooling/tile-download-plan.json --outdir tooling/mbtiles

# 中断后重新运行会自动续传（跳过已完成区域 + 跳过已下载瓦片）
```

### 单区域模式

```bash
python3 tooling/generate_mbtiles.py \
  --bbox 112.8,28.1,113.1,28.4 \
  --zoom 11-15 \
  --output changsha.mbtiles
```

### 参数

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `--plan` | 否 | — | 计划 JSON 文件路径（计划模式） |
| `--outdir` | 否 | `tooling/mbtiles` | 计划模式输出目录 |
| `--dry-run` | 否 | — | 仅预览计划，不下载 |
| `--bbox` | 否 | — | 区域范围：`min_lon,min_lat,max_lon,max_lat`（单区域模式） |
| `--zoom` | 否 | `11-15` | 缩放级别范围（单区域模式） |
| `--output` | 否 | — | 输出 MBTiles 文件（单区域模式） |
| `--server` | 否 | `osm` | 瓦片源：`osm`（官方）、`osm_de`（德国镜像） |
| `--rate` | 否 | `0.3` | 请求间隔秒数 |

### 特性

- **计划驱动** — 按 JSON 计划文件逐区域下载，每完成一个区域自动更新状态
- **断点续传** — 跳过已完成的区域 + 跳过已下载的瓦片
- **自动重试** — 失败重试 3 次，429 限流指数退避
- **Ctrl+C 安全** — 中断时保存进度，重新运行自动恢复

---

## tile-download-plan.json

全球主要畜牧牧场区域的瓦片下载计划，包含 15 个区域：

| ID | 区域 | 牲畜类型 | Zoom |
|----|------|---------|------|
| changsha-demo | 长沙 Demo 区域 | 项目演示 | 11-15 |
| inner-mongolia | 内蒙古牧区 | 牛/羊/骆驼 | 7-11 |
| xinjiang | 新疆牧区 | 绵羊/山羊/牛 | 7-10 |
| qinghai-tibet | 青藏高原牧区 | 牦牛/藏羊 | 7-10 |
| mongolia | 蒙古国牧区 | 牛/羊/山羊/骆驼 | 7-10 |
| australia | 澳大利亚内陆牧场 | 牛/羊 | 7-10 |
| usa-great-plains | 美国大平原牧场 | 牛 | 7-10 |
| brazil-central | 巴西中南部牧场 | 牛 | 7-10 |
| argentina-pampas | 阿根廷潘帕斯草原 | 牛/羊 | 7-10 |
| new-zealand | 新西兰牧场 | 羊/牛/鹿 | 7-11 |
| uk-ireland | 英国/爱尔兰牧场 | 牛/羊 | 7-10 |
| scandinavia-reindeer | 北欧驯鹿区 | 驯鹿/麋鹿 | 7-10 |
| east-africa | 东非牧区 | 牛/羊/骆驼 | 7-10 |
| south-africa | 南非牧场 | 牛/羊 | 7-10 |
| india-northwest | 印度西北牧区 | 牛/羊/骆驼 | 7-10 |

每个区域完成后计划文件会自动写入 `status`、`tile_count`、`file_size_mb`、`completed_at`。

---

## import_mbtiles.sh

将已下载的 MBTiles 文件部署到 tileserver-gl 服务。

**用法：**

```bash
./tooling/import_mbtiles.sh <remote-host> [remote-path]
```

---

## 典型工作流

```bash
# 1. 预览下载计划
python3 tooling/generate_mbtiles.py --plan tooling/tile-download-plan.json --dry-run

# 2. 执行下载
python3 tooling/generate_mbtiles.py --plan tooling/tile-download-plan.json --outdir tooling/mbtiles

# 3. 上传到服务器
rsync -avz tooling/mbtiles/ agentic@172.22.1.123:/data/mbtiles/

# 4. 导入到 tileserver-gl
./tooling/import_mbtiles.sh agentic@172.22.1.123 /data/mbtiles
```
