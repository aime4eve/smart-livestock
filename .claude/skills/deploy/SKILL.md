---
name: deploy
description: 一键部署到 172.22.1.123 — 后端(Spring Boot) + 前端(Flutter Web) + Nginx
disable-model-invocation: true
---

# Deploy Smart Livestock

将后端 + 前端构建并部署到远程服务器。支持选择性部署。

## 参数

- `target`（可选）: `all`（默认）| `backend` | `frontend`

## 全量部署（all）

### A. 后端部署

1. **检查 git 状态**
   ```bash
   git status --short
   ```

2. **编译 bootJar**（跳过测试）
   ```bash
   cd smart-livestock-server && ./gradlew clean bootJar -x test
   ```

3. **Rsync 代码到远程**
   ```bash
   rsync -avz --exclude='.git' --exclude='.gradle' --exclude='node_modules' --exclude='._*' smart-livestock-server/ agentic@172.22.1.123:~/smart-livestock-server/
   ```

4. **确保远程 build/libs 目录**
   ```bash
   ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && mkdir -p build/libs"
   ```

5. **Rsync jar 文件**
   ```bash
   rsync -avz smart-livestock-server/build/libs/ agentic@172.22.1.123:~/smart-livestock-server/build/libs/
   ```

6. **清理远程旧 jar**（只保留版本号最大的一个）
   ```bash
   ssh agentic@172.22.1.123 "cd ~/smart-livestock-server/build/libs && ls -t smart-livestock-server-*.jar | tail -n +2 | xargs rm -f"
   ```

7. **Docker 重建并启动后端**
   ```bash
   ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && docker compose build app && docker compose up -d app"
   ```

### B. 前端部署

8. **Flutter Web 构建**（同源 `/api/v1`，不传 API_BASE_URL → ApiClient web 默认走页面 origin）
   ```bash
   cd Mobile/mobile_app && ./build_web.sh --dart-define=APP_MODE=live
   ```
   > Web 用相对路径 `/api/v1`：`api_client.dart` 的 `_resolveBaseUrl()` 在 web 平台默认 `/api/v1`，浏览器自动用页面 host:port（nginx 已反代 `/api/v1/` → app:8080），换部署域名/端口无需重建。开发连特定后端时可显式 `--dart-define=API_BASE_URL=http://...` 覆盖。
   > 必须用 `build_web.sh`（带 `--no-wasm-dry-run`）而非裸 `flutter build web`——后者会因 flutter_secure_storage 触发 wasm dry-run 误报失败。

9. **将构建产物复制到 nginx 目录**
   ```bash
   rm -rf smart-livestock-server/frontend
   cp -r Mobile/mobile_app/build/web smart-livestock-server/frontend
   ```

10. **Rsync 前端文件到远程**（仅 frontend 目录）
    ```bash
    rsync -avz --delete smart-livestock-server/frontend/ agentic@172.22.1.123:~/smart-livestock-server/frontend/
    ```

11. **重建并启动 nginx**
    ```bash
    ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && docker compose build nginx && docker compose up -d nginx"
    ```

### C. 健康检查

12. **验证后端 API**
    ```bash
    curl -sf http://172.22.1.123:18080/api/v1/auth/login \
      -X POST -H 'Content-Type: application/json' \
      -d '{"phone":"13800000000","password":"123"}' | python3 -m json.tool
    ```

13. **验证前端页面**
    ```bash
    curl -sf http://172.22.1.123:18080/ | head -5
    ```
    返回 HTML 即为成功。

## 仅后端（backend）

执行步骤 1-7 + 步骤 12。跳过前端构建。

## 仅前端（frontend）

执行步骤 8-11 + 步骤 13。跳过后端构建。

## 注意

- 任何编译/构建步骤失败则中止，不继续部署
- 健康检查失败时查看日志：
  - 后端：`ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && docker compose logs app --tail 50"`
  - 前端：`ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && docker compose logs nginx --tail 20"`
- Flyway 迁移在应用启动时自动执行 — 留意日志中 migration 是否成功
- 前端 nginx Dockerfile: `COPY frontend /usr/share/nginx/html`，前端静态文件打包在镜像中
