# 签发工具独立部署（NIX-191）

签发工具（license-issuer）是**我方内部运营应用**，与客户交付包彻底分离：
它持有签发私钥与签发台账，部署在我方内网一台**专用服务器**上，只有内网
运营人员可访问。市场测试版发布包（images/install 包）不包含、也不允许包
含本工具（verify-release-bundle 会拒绝任何携带 issuer 的包）。

## 机器要求

- 内网专用服务器（不与 dev/业务云混部）
- Docker + Compose
- 能访问云端业务 API（合同拉取/回写）；若完全离线，可用"手工录入合同"模式
- 浏览器（内网）访问 8500 端口

## 部署步骤

1. **同步签发工具代码到专用机。**

   - **"本目录"** 指代码仓库里的 `license-issuer/` 目录（签发工具就住在智慧畜牧仓库的这个子目录里）。
   - **"代码"** 只有三样，同步它们即可——整个仓库的其他部分（Java 后端、Mobile、docs）都不需要：
     | 内容 | 是什么 |
     |------|--------|
     | `app/` | 签发工具的 Python 源码（FastAPI 后端、签发/验签逻辑、路由） |
     | `templates/` | 网页模板（登录、新建授权、合同台账、审计等页面） |
     | `docker-compose.yml` | 部署编排文件（定义容器、内网端口、数据卷） |
   - **"专用机"** 指我方内网专门跑签发工具的那台服务器（Docker + Compose 已装，仅内网可达）。不与开发机、业务云、客户机器混用。
   - **绝不随代码同步的东西**：`secrets/`（签发私钥，第 2 步用保密渠道单独放）、`data/`（签发台账，只在专用机上生成）、`.venv/`（依赖由容器内自动安装）。

   同步示例（在开发机上执行；专用机的 IP 与账号向运维申请）：

   ```bash
   # 在代码仓库根目录执行
   rsync -av \
     --exclude 'license-issuer/secrets' \
     --exclude 'license-issuer/.venv' \
     --exclude 'license-issuer/data' \
     license-issuer/app \
     license-issuer/templates \
     license-issuer/docker-compose.yml \
     <运维提供的账号>@<签发机内网IP>:/opt/license-issuer/
   # 目标目录约定为 /opt/license-issuer/（含 app/ templates/ docker-compose.yml 三项）
   ```

   > **为什么是 `/opt/license-issuer/`**：`/opt` 是 Linux 标准——"自己手动装的第三方应用"放这里，系统升级不会动它；固定路径让交接文档、备份、升级命令人人一致；也避免台账/私钥落进某个员工的 home 目录（账号删除时被连带清掉）。**路径本身不是硬性要求**（compose 用相对路径，放哪都能跑）——若公司规范用别的目录，保持 `docker-compose.yml`、`app/`、`templates/`、`.env.issuer` 四样同目录，并替换文档中出现的路径即可。
2. 生成密钥与配置：

   **`<私钥备份>` 是什么**：签发工具的 **Ed25519 签名私钥文件**——每张 `.sllicense`
   证书都是用它签名的，谁持有它谁就能签发合法授权，所以它是整个授权体系里
   最核心的机密：不进 git 仓库（已 gitignore）、权限 0600、只存在签发机上，
   另外保留一份离线备份（U 盘/保密存储）。**丢失 = 无法再签发证书（换新钥
   匙需逐台客户机更新公钥，代价极高）；泄露 = 任何人都能伪造授权。**

   当前这把私钥的实物位置：开发机代码目录 `license-issuer/secrets/sl-license-2026q3.pem`
   （PKCS#8 PEM，2026-09-03 生成）。**首次部署时就从这里拷贝**。按 a→b→c 顺序执行：

   a. 在**签发机**上创建目录（先建目录，私钥才有地方落）：

   ```bash
   cd /opt/license-issuer && mkdir -p secrets data && chmod 700 secrets
   ```

   b. 在**开发机**的仓库根目录执行（私钥从开发机送到签发机，走保密渠道）：

   ```bash
   scp license-issuer/secrets/sl-license-2026q3.pem \
       <运维提供的账号>@<签发机内网IP>:/opt/license-issuer/secrets/
   ```

   c. 在**签发机**上收紧权限并生成配置：

   ```bash
   cd /opt/license-issuer && chmod 600 secrets/sl-license-2026q3.pem

   python3 -c "import secrets; print(secrets.token_hex(32))"   # → SESSION_SECRET
   cat > .env.issuer <<EOF
   KEYS_DIR=/app/secrets
   ACTIVE_KEY_ID=sl-license-2026q3
   SESSION_SECRET=<上面生成的值>
   ISSUER_ALLOW_EMPTY_USERS=1
   # 合同自动关联（可选；不配则使用离线手工合同台账）
   CLOUD_BASE_URL=https://<云端业务地址>
   CLOUD_TOKEN=<专用机器账号的 accessToken>
   CLOUD_ALLOW_PRIVATE_IP=1     # 云端在内网时必须
   CLOUD_TLS_INSECURE=1         # 云端为 beta 自签/本地 CA 证书时；生产请装 CA 后置 0
   EOF
   chmod 600 .env.issuer
   ```

3. 首次启动后创建操作员账号（容器内一次性）：

   **`<运营用户名>`** = 我方运营人员登录签发工具网页的登录名（自己起，建议按人名拼音，
   一人一个——签发审计要能归因到人）。它与客户管理员手机号、业务系统账号完全无关。

   ```bash
   docker compose exec issuer sh -c \
     "python -m app.create_user <运营用户名>"
   # 按提示输入两遍密码（bcrypt 存进签发工具自己的数据库；登录签发工具用）
   ```
   每位需要签发权限的同事各建一个账号；不再使用的账号可用删除数据库 users 表
   对应行的方式停用（或后续版本提供管理页）。

4. 启动：`docker compose up -d`，浏览器打开 `http://<签发机内网IP>:8500`。

5. **部署 TLS 证书签发（已整合）**：给客户服务器签 nginx 的 HTTPS 证书，
   不再需要手工 openssl——进入「**部署证书**」页：

   - 首次使用引导"创建公司 CA"（一次性；ca.crt 装进运营人员浏览器一次，
     之后该 CA 签的所有证书都受信任；`secrets/deploy-ca/` 目录务必备份）；
   - 签发表单：填客户服务器 IP/域名（多条逗号分隔）+ 有效期 → 签发 →
     下载 fullchain.pem + privkey.pem 交付客户；
   - 客户侧放入 `secrets/certs/` → `restart nginx`；私钥与证书分开渠道交付；
   - 每次签发进台账（本页底部），`gen-tls-cert.sh` 脚本仍随 release 包
     作为应急兜底。

   注意：该 CA 签发的证书只有装了 ca.crt 的浏览器才信任；面向公网的正式
   商业部署请客户使用正规 CA 证书。

## 首次交付客户的操作序列（ONPREM）

1. 客户装机完成（零账号、待激活）。客户在浏览器打开
   `https://<服务器IP>/api/v1/admin/deployment-license/enrollment`
   （免登录窗口内直接可看）复制**安装 ID + 指纹**发给我方。
2. 签发工具「合同台账」确认该客户合同存在（云端拉取或手工登记）。
3. 「新建授权」：填 tenantId / 安装 ID / 指纹 / 档位期限 /
   **管理员手机号（客户负责人）**，选择合同 → 预览 → 确认签发。
4. 完成页会**只显示一次** 14 位初始密码：通过电话/纸质单独交给客户；
   证书文件走另一条渠道。**两样分开传**。
5. 客户在管理页免登录上传证书 → 管理员账号自动诞生 → 客户首次登录被
   强制改密 → 交付完成。

## 找回与应急

- 客户忘密码：见运维指南「管理员密码应急重置」（服务器本地命令，需机房权限）。
- 证书文件丢失：重新签发一张新证书（旧证书自动作废，重导会被拒绝）。
- 台账备份：定期备份 `data/issuer.sqlite3` 与 `secrets/`（含私钥，等同现金）。

## 安全边界

- 私钥与签发台账只存在于本机；仓库、客户包、备份数据库中都不含私钥。
- `CLOUD_TLS_INSECURE=1` 仅用于 beta 自签/本地 CA 阶段；生产请把云端证书
  换成正规 CA 并置 0。
- `CLOUD_ALLOW_PRIVATE_IP=1` 仅当云端就在内网时开启。
