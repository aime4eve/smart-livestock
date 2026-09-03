# license-issuer — 内部授权签发服务

智慧畜牧地端离线授权（`.sllicense`）的内部签发服务，对应 NIX-184 设计文档 §3/§4。
FastAPI + Jinja2 服务端渲染，SQLite 存储签发记录与审计，`cryptography` 做 Ed25519 签名。

> **红线**：本服务只部署在内部可信网络。**绝不进入客户 release 包、绝不进公网、
> 私钥绝不进地端**。release 包验证脚本会扫描并拒绝包含本目录的发布产物。

## 页面与路由

| 路由 | 方法 | 页面 | 说明 |
| --- | --- | --- | --- |
| `/login` | GET/POST | 登录页 | bcrypt 校验 + CSRF + 失败限速（15 分钟 5 次） |
| `/issue/new` | GET | 新建授权 | 表单：绑定字段 / 类型 / 档位 / 有效期 / 配额 / 签发原因 |
| `/issue/preview` | GET/POST | 签发预览 | 展示 canonical payload 摘要（SHA-256），需二次确认（CSRF） |
| `/issue/confirm` | POST | （动作） | 用 ACTIVE_KEY_ID 私钥签名，写 licenses + audit |
| `/issue/{id}/done` | GET | 签发完成 | 提供下载链接 |
| `/licenses` | GET | 授权列表 | |
| `/licenses/{id}` | GET | 授权详情 | |
| `/licenses/{id}/download` | GET | 下载 | `application/octet-stream`，`{licenseId}.sllicense`，记录审计 |
| `/audit` | GET | 审计日志 | 登录成功/失败、签发、下载、退出 |
| `/keys` | GET | 密钥状态 | 只显示 keyId、公钥指纹、active 标记；**永不显示私钥** |

所有路由可挂在 `ISSUER_BASE_PATH` 前缀下（如 `/issuer`）。

## 环境变量

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `KEYS_DIR` | `./secrets` | 私钥目录，布局 `<KEYS_DIR>/<keyId>.pem`（PKCS#8 PEM） |
| `ACTIVE_KEY_ID` | `sl-license-2026q3` | 当前签名密钥 ID |
| `DB_PATH` | `./data/issuer.sqlite3` | SQLite 文件，建议挂内部数据卷 |
| `SESSION_SECRET` | 必填 | 会话 cookie 签名密钥（≥32 字符），`python3 -c "import secrets; print(secrets.token_hex(32))"` |
| `ISSUER_BASE_PATH` | 空 | 反向代理子路径前缀 |
| `KEYS_STRICT_PERMISSIONS` | `1` | 私钥目录 0700 / 文件 0600 校验；关闭仅用于测试 |
| `ISSUER_ALLOW_EMPTY_USERS` | `0` | 允许无账号启动（仅首次装配用） |
| `ISSUER_BCRYPT_ROUNDS` | `12` | bcrypt 代价因子 |
| `ISSUER_RATE_LIMIT_MAX_FAILURES` | `5` | 登录失败限速阈值（按用户名+IP） |
| `ISSUER_RATE_LIMIT_WINDOW_SECONDS` | `900` | 限速时间窗（秒） |

## 启动 fail fast

启动时依次校验，任一失败即退出：

1. 环境配置可解析（`SESSION_SECRET` 必填等）。
2. 私钥存在、目录/文件权限 0700/0600（严格模式）、算法为 Ed25519（其他算法拒绝）。
3. 自检：签名探针 → 用配套公钥验签。
4. 打开 SQLite；`users` 表为空则拒绝启动（除非 `ISSUER_ALLOW_EMPTY_USERS=1`）。

## 初始化与运行

```bash
cd license-issuer
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

export SESSION_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
export KEYS_DIR=/secure/mount/keys          # 私钥目录（0700，内含 <keyId>.pem 0600）
export DB_PATH=/secure/mount/data/issuer.sqlite3

# 1. 初始化运营账号（bcrypt 入库，可重复执行添加多人）
.venv/bin/python -m app.create_user ops-admin

# 2. 启动（内部端口，不要暴露公网）
.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8787
```

## 密钥管理

- 私钥目录只挂载到 issuer（容器/主机），`chmod 0700`；私钥文件 `chmod 0600`。
- 当前签名密钥由 `ACTIVE_KEY_ID` 指定；对应公钥内置在后端
  `smart-livestock-server/src/main/resources/licensing/license-public-keys.json`。
- 测试/联调用测试密钥：`smart-livestock-server/src/test/resources/licensing/`
  （keyId `sl-license-test`），pytest 通过 `KEYS_DIR`/`ACTIVE_KEY_ID` 指向它。
- 密钥轮换：生成新 keyId 私钥 → 新公钥以 `active` 追加进后端公钥文件，旧公钥改
  `rotated`（仍然可验旧授权）→ 切换 issuer 的 `ACTIVE_KEY_ID` 并重启。

## 测试

```bash
cd license-issuer
.venv/bin/pytest -q
```

测试覆盖：canonical JSON 与 Java 共享向量逐字节一致、签发→下载→公钥验签、
篡改拒绝、登录失败/限速/CSRF 拒绝、私钥缺失与权限过宽 fail fast、
未登录重定向、页面渲染。roundtrip 样例由测试生成到
`test-vectors/issuer-roundtrip/`，由 Java 侧
`IssuerRoundtripVectorTest` 做回程验证。
