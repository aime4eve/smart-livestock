# 服务器初始化配置指南

**适用服务器**: 172.22.1.123（32 核 / 126GB 内存）
**Docker**: snap 版本（数据目录需 bind mount 到独立卷）
**关联**: `docs/guides/tileserver-deployment-guide.md`、`scripts/deploy.sh`

## 背景

服务器根分区（`/`）仅 97GB，Docker 默认将镜像、容器、日志写入 `/var/snap/docker/common/var-lib-docker`（根分区），多次部署后根分区 100% 满，导致 `docker compose build` 失败（`no space left on device`）。解决方案：将 Docker 数据目录迁移到独立的数据卷（`/data`，2TB），并调高系统文件描述符上限。

## 必做配置

### 1. Docker 数据目录迁移（fstab bind mount）

将 `/data/docker-data` 绑定挂载到 snap Docker 的数据目录：

```bash
# /etc/fstab — 添加以下行
/data/docker-data /var/snap/docker/common/var-lib-docker none bind 0 0
```

操作步骤（首次配置时）：

```bash
# 1. 创建数据目录
sudo mkdir -p /data/docker-data

# 2. 停止 Docker
sudo snap stop docker

# 3. 复制现有数据（如有）
sudo rsync -aP /var/snap/docker/common/var-lib-docker/ /data/docker-data/

# 4. 挂载
sudo mount -a

# 5. 启动 Docker
sudo snap start docker

# 6. 验证
docker info | grep "Docker Root Dir"  # 应显示 /var/snap/docker/common/var-lib-docker
df -h /data                            # 确认数据写入 /data 卷
```

### 2. 系统文件描述符上限（sysctl）

部署后容器数量多，默认 `fs.file-max` 不够用：

```bash
# /etc/sysctl.conf — 添加以下行
fs.file-max = 3000000

# 立即生效
sudo sysctl -p
```

## 验证

```bash
# 磁盘空间
df -h / /data

# Docker 数据目录
docker info | grep "Docker Root Dir"

# 系统文件描述符上限
cat /proc/sys/fs/file-max  # 应为 3000000
```

## 部署相关

部署使用 `scripts/deploy.sh`，两个环境隔离：

```bash
cd smart-livestock-server
./scripts/deploy.sh dev    # → 19080，compose project: sl-dev
./scripts/deploy.sh test   # → 18080，compose project: smart-livestock-server
```

部署后健康检查：

```bash
curl -s -X POST "http://172.22.1.123:19080/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123"}'   # dev

curl -s -X POST "http://172.22.1.123:18080/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123"}'   # test
```

## 磁盘维护

定期清理 Docker 无用资源（非破坏性，不影响运行中的容器）：

```bash
docker builder prune -f      # 清理 build cache
docker image prune -f        # 清理悬空镜像
docker volume ls -f dangling=true  # 检查孤立卷（谨慎删除）
```
