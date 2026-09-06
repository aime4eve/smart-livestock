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

1. 代码同步本目录到专用机（`app/ templates/` + 本 compose 文件）。
2. 生成密钥与配置：

```bash
mkdir -p secrets data && chmod 700 secrets
cp <私钥备份>/sl-license-2026q3.* secrets/     # 签发私钥（务必离线备份一份）
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

```bash
docker compose exec issuer sh -c \
  "python -m app.create_user <运营用户名>"
# 按提示输入密码（bcrypt 入库；登录用）
```

4. 启动：`docker compose up -d`，浏览器打开 `http://<签发机内网IP>:8500`。

## 首次交付客户的操作序列（ONPREM）

1. 客户装机完成（零账号、待激活），在管理页复制**安装 ID + 指纹**发给我方。
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
