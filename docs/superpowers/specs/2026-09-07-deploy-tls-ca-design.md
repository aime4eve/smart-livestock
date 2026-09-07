# 部署 TLS 证书签发整合设计（签发工具「部署证书」页）

> **状态**：设计提案，待用户批准实现。来源：2026-09-07 用户指出 `gen-tls-cert.sh`
> "没有达到设计功能"——脚本只是装机兜底，而"CA 证书创建"按架构原则应整合进
> 内部签发工具（与授权证书同一入口、同一账号体系、独立内网部署）。

## 1. 背景与目标

- 现状：TLS 证书靠每台客户机器上的 `gen-tls-cert.sh` 自签/兜底，公司级 CA
  只存在于开发机手工流程（`~/.ssl-private/nix184-ca`），无台账、无审计、无统一入口。
- 目标：签发工具新增「部署证书」能力——
  1. **公司 CA 一次性创建**：厂商 CA（ca.crt/ca.key）托管在签发工具的密钥目录，
     ca.crt 交付运营人员装浏览器（一次），此后所有部署证书均由它签发；
  2. **按部署签发服务器证书**：录客户服务器 IP/域名 + 有效期 → 下载
     fullchain.pem + privkey.pem 交付包；
  3. **台账审计**：与授权证书同标准（谁、给哪台机器、何时、SAN 是什么）。
- 非目标：替代客户自备的正规 CA 证书；公网 ACME/Let's Encrypt 集成。

## 2. 签发工具侧设计

- 密钥目录扩展：`secrets/` 下新增 `deploy-ca/`（ca.crt/ca.key，0700/0600）；
  首次进入页面时若无 CA → 引导"创建公司 CA"（一次性，录 CA 名称）。
- 新页面「部署证书」：
  - 表单：SAN 列表（IP/域名，≥1 项）、有效期（默认 825 天）、备注；
  - 签发 → 展示 fullchain.pem / privkey.pem 下载按钮 + 台账落库
    （SQLite 新表 `deploy_certs`：id, san, not_before, not_after, serial,
     issued_by, created_at, note）;
  - 历史列表 + 重新下载。
- 复用现有Ed25519 无关：TLS 用 RSA/ECDSA + 公司 CA，cryptography 库已具备能力。
- 账号与权限：沿用签发工具操作员登录，无新增角色。

## 3. 客户机侧（保持现状，文档已覆盖）

- 下载的 `fullchain.pem`/`privkey.pem` 放进 `release/secrets/certs/`
  → `docker compose restart nginx`；
- 运营人员浏览器装过公司 CA → 访问无告警；客户侧如需无告警访问，
  由客户自行提供正规 CA 证书替换。
- `gen-tls-cert.sh` 保留为装机应急兜底（无 CA 时自签带 SAN），
  定位从"主路径"降级为"应急"。

## 4. 任务拆解（批准后实施）

| # | 任务 | 验证 |
|---|------|------|
| 1 | issuer：公司 CA 创建/托管 + 「部署证书」签发页 + 台账 | pytest：CA 创建、签发、SAN 校验、无 CA 引导 |
| 2 | 下载交付：fullchain/privkey 打包下载 | 文件内容与台账一致 |
| 3 | 文档：DEPLOY.md/运维指南改为"正路走签发工具" | — |
| 4 | 86/223 实测：签发 → 部署 → 浏览器无告警 | 链路验证 |

## 5. 边界

- 不做：公网 ACME、多 CA 轮换 UI、CRL/OCSP。
- 客户对浏览器的信任要求 = 安装我方 ca.crt 一枚；正式商业交付仍建议
  客户提供自有域名 + 正规 CA 证书。
