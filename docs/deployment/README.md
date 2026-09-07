# 上市部署文档中心（Deployment Docs）

> 本目录收录**商业化上市（客户购买）部署**的全部操作文档。从签发工具装机、签发激活证书、客户机房交付，到长期运维，按闭环流程各管一段。
> 内部 dev/test 环境部署**不在本目录**——见 `docs/reference/deployment.md`。

## 闭环全景：一套系统从卖出到长期运行

```
① 我方内网·装一次          ② 我方内网·每卖一套做一次
   签发工具专用机装机          选客户合同 → 录管理员手机号
   （私钥+台账+部署证书CA）    → 生成一次性密码 → 签发激活证书
        │                          │
        └──────────┬───────────────┘
                   ▼
③ 客户机房·交付日             ④ 客户机房·长期
   装机 → 免登录登记(安装ID)     巡检 / 备份 / 授权续期
   → 导入首张证书 → 解锁        → 版本升级 / 证书更换
   → 管理员诞生 → 强制改密      （续费=回到②签新证书再导入）
        │
        ▼
⑤ 发布把关（发布负责人按检查清单逐项勾选，串起③④）
```

## 场景速查：我在什么情况，看哪份

| 你是谁 / 场景 | 看这份 | 说明 |
|---|---|---|
| **我方运营**，第一次部署签发工具 | [license-issuer-deploy.md](license-issuer-deploy.md) | 签发工具独立部署 compose、私钥 0700、合同回写配置 |
| **我方运营**，客户签约后要出证书 | [license-issuer/README.md](../../license-issuer/README.md) | 签发操作、部署证书 CA 页、台账与审计 |
| **交付工程师**，去客户现场装机 | [release-install-guide.md](release-install-guide.md) | 主文档：从发布包到系统可用每一步怎么做 |
| **交付工程师**，出发前/遇到坑 | [release-deployment-playbook.md](release-deployment-playbook.md) | 86/223 双机实战复盘：顺序、真实耗时、必须先知道的坑 |
| **运维/售后**，交付之后长期维护 | [release-operations-guide.md](release-operations-guide.md) | 巡检、日志、备份恢复、续期、升级、证书更换 |
| **发布负责人**，放行前把关 | [release-checklist.md](release-checklist.md) | 逐项勾选清单，操作指向安装/运维指南 |

## 本目录文档清单

| 文档 | 阶段 | 读者 |
|---|---|---|
| [license-issuer-deploy.md](license-issuer-deploy.md) | ① 签发工具装机 | 我方运营 |
| [release-install-guide.md](release-install-guide.md) | ③ 客户交付 | 交付工程师 |
| [release-deployment-playbook.md](release-deployment-playbook.md) | ③ 客户交付（实战参考） | 交付工程师 |
| [release-operations-guide.md](release-operations-guide.md) | ④ 长期运维 | 运维/售后 |
| [release-checklist.md](release-checklist.md) | ⑤ 发布把关 | 发布负责人 |

## 关联文档（不在本目录，但属于闭环）

| 文档 | 为什么在那 | 何时看 |
|---|---|---|
| [`license-issuer/README.md`](../../license-issuer/README.md) | 签发工具应用自身的主 README（惯例位置） | 阶段②签发操作 |
| [`docs/testing/market-beta-test-cases.md`](../testing/market-beta-test-cases.md) | 测试域文档（TC-H/TC-O 用例编号） | 检查清单的验收依据 |
| [`docs/superpowers/specs/2026-09-05-admin-bootstrap-design.md`](../superpowers/specs/2026-09-05-admin-bootstrap-design.md) | 设计历史归档（spec 惯例位置） | 账号随证书诞生的设计依据 |
| [`docs/superpowers/specs/2026-09-07-deploy-tls-ca-design.md`](../superpowers/specs/2026-09-07-deploy-tls-ca-design.md) | 设计历史归档 | 部署 TLS 证书统一签发的设计依据 |
| [`docs/reference/deployment.md`](../reference/deployment.md) | 内部 dev/test 环境，与上市交付无关 | 只在内部开发环境时看 |

## 维护约定

- 打进发布包的是 `release/docs/` 三件套（install / operations / checklist），由 `smart-livestock-server/scripts/build-release-package.sh` 从本目录拷贝——**新增交付文档时同步改该脚本**。
- issuer 部署文档（license-issuer-deploy.md）**绝不进客户发布包**（verify-release-bundle 会拒绝携带 issuer 的包）。
- 四份 release-* 文档之间的同目录互引使用纯文件名；从目录外引用请带 `docs/deployment/` 前缀。
