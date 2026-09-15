# iOS 编译与装机指南（开发签名版）

> 适用对象：团队内部把智慧畜牧 App 装到 iPhone 真机的开发者/测试者。
> 当前签名方式：免费个人团队开发签名（Apple ID: sales@hktlora.com，Team `J62PU4Y357`）——**不需要付费开发者账号**，但证书 7 天有效，到期需重新编译装机。
> 环境对应：`test` = ah.hkttech.cn（云端测试环境）；`dev` = 172.22.1.123:19080（办公室开发环境）。

---

## 1. 一分钟快速开始

前提：用那台已经配对过 iPhone 的 Mac（首次配对见 §3），手机数据线连好并解锁。

```bash
cd Mobile/mobile_app
./build_ios_install.sh test          # 编译 test 环境 IPA → 装进默认 iPhone → 自动启动
```

看到 `==> Done: installed, launched and process is alive.` 即成功，手机上会出现绿底牛头图标的 App。

## 2. 命令速查

| 命令 | 作用 |
|---|---|
| `./build_ios_install.sh test` | 编译 test 环境 IPA + 装机 + 启动（默认设备） |
| `./build_ios_install.sh dev` | 同上，连 dev 环境 |
| `./build_ios_install.sh test --skip-build` | 不重新编译，重装现有最新 IPA（改完后端/只想重装时用） |
| `./build_ios_install.sh test --launch-only` | 只拉起手机上的 App（解锁手机后执行） |
| `./build_ios_install.sh test <UDID>` | 指定要装的设备（UDID 用 `--list` 查） |
| `./build_ios_install.sh --list` | 列出当前连接的设备 |
| `./build_ios.sh test` | 只编译不装机（产物在 `build/ios/ipa/hkt-smartlivestock-*.ipa`） |

产物：`Mobile/mobile_app/build/ios/ipa/hkt-smartlivestock-<版本>.ipa`（版本号自动同步后端 `build.number`）。

## 3. 新手机首次接入（团队多人装机）

免费签名的证书只对**已注册进证书的设备**生效，新手机必须先做一次注册：

1. 手机用数据线连到这台 Mac，手机上点"信任此电脑"
2. 跑一次 `./build_ios_install.sh test`——编译过程会自动把这台手机注册进证书并完成安装
3. 记下它的 UDID（`./build_ios_install.sh --list`），以后可以指定设备安装

多人团队时每台新手机都要重复上述一次（都用同一台 Mac）。注册过的手机重装可以走 Wi-Fi（见 §4）。每次重新编译会自动把**所有已注册设备**打包进新证书。

## 4. Wi-Fi 无线装机（不插线重装）

首次 USB 配对时做过下面设置的手机，之后重装/拉起可以不插线：

1. 手机保持连着 Mac（USB），打开 **Xcode → Window → Devices and Simulators**
2. 选中这台 iPhone，勾选 **"Connect via network"**（通过网络连接）
3. 之后拔掉数据线，只要**手机和 Mac 在同一个局域网 Wi-Fi**，`./build_ios_install.sh test --skip-build` 就能无线完成装机

注意事项：

- 首次配对和勾选必须插线，勾选是一次性的
- 要求手机和 Mac 在同一 Wi-Fi（公司网络如屏蔽了组播/ Bonjour 可能发现不了设备，换手机热点或常规办公网即可）
- 装机时手机最好解锁亮屏；**启动 App 必须手机解锁**
- 无线传输装机包约 30~60 秒，比 USB 慢属正常

## 5. 证书 7 天有效期（重要）

免费签名证书 7 天后过期，**过期后 App 打不开**（点图标闪退/提示不受信任）。续命方式：

```bash
cd Mobile/mobile_app
./build_ios_install.sh test     # 重新编译即生成新证书，装上即续 7 天
```

建议团队约定每周固定时间（如周一早上）集体刷新一次。所有人装完同一版本后版本一致，便于联调。

## 6. 常见问题排查

| 现象 | 原因与处理 |
|---|---|
| `Launch failed ... device was not, or could not be, unlocked` | 手机锁屏了。解锁手机点图标，或 `./build_ios_install.sh test --launch-only` |
| `CoreDeviceError 1005 / 260 ... file doesn't exist` | devicectl 用了相对路径。**必须在 `Mobile/mobile_app` 目录下跑脚本**，或给 IPA 绝对路径（脚本内部已处理） |
| `ERROR: device ... is not connected` | 手机没连/没信任电脑。插线解锁重试；`--list` 确认设备在列表里 |
| 点图标闪退（之前能用） | 证书过期，重新编译装机（§5） |
| `maximum number of apps` / 装不上提示 3 个应用上限 | 免费账号每台手机最多同时装 3 个开发签名 App，删一个不用的再装 |
| 地图灰瓦片 | 检查手机端 App"我的→时区"设置：中国时区走高德，其他时区走 OpenStreetMap（OSM 国内网络打不开） |
| 手机端连不上后端 | test 环境地址 `https://ah.hkttech.cn`，手机需能访问公网；账号找管理员要测试种子号 |

## 7. 已知的体验限制与升级路径

免费方案的三个硬伤：证书 7 天过期、每台新手机都要连一次这台 Mac、设备数量有上限。团队超过 5 台或要发给客户时，建议升级 **Apple Developer Program（688 元/年）**走 TestFlight：上传一次，所有人在 App Store 装 TestFlight 后点一下即安装和更新，无过期无设备数烦恼（中国区需要 App ICP 备案）。

## 8. 相关文件

- 编译脚本：`Mobile/mobile_app/build_ios.sh`（单编译）
- 编译+装机脚本：`Mobile/mobile_app/build_ios_install.sh`（本文档主角）
- 图标生成器：`Mobile/mobile_app/tooling/make_appicon.swift`（改图标设计后跑一遍 + `dart run flutter_launcher_icons`）
- iOS 发布历史与踩坑：知识库 `10-Projects/02-smart-livestock/2026-09-14-iOS开发签名装机首发布.md`
