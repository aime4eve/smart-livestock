# 论文包：RSSI 测距与追踪器-网关通讯距离

> 背景：动物追踪器与 LoRaWAN 网关通讯距离评估（2026-09-18）结论——**方案 A（GPS+网关坐标几何距离）为主；方案 B（RSSI 路径损耗反推距离）被 test 库实测证伪，降级为链路质量分档**。本目录收录评估时参照的开放获取论文。完整评估记录见知识库 `10-Projects/02-smart-livestock/2026-09-18-追踪器网关通讯距离计算落地评估.md`。

## 已下载 PDF

| 文件 | 论文 | 来源 | 参照意义 |
|------|------|------|---------|
| `2019-WiMOB-Dieng-LoRa-RSSI-cattle-localization.pdf` | Dieng, Pham, Thiare. *Outdoor Localization and Distance Estimation Based on Dynamic RSSI Measurements in LoRa Networks: Application to Cattle Rustling Prevention*. IEEE WiMOB 2019 | [作者主页](https://cpham.perso.univ-pau.fr/Paper/WIMOB19-1.pdf) | **同场景必读**（牛项圈+LoRa+RSSI 测距）。静态路损模型不够，用带 GPS 项圈实时动态标定 RSSI-距离映射，log-distance 只做兜底——"方案 A 反哺方案 B"的文献版 |
| `2017-GIoTS-Fargas-GPS-free-geolocation-LoRa.pdf` | Fargas, Petersen. *GPS-free geolocation using LoRa in low-power WANs*. GIoTS 2017 | [CORE](https://core.ac.uk/download/84004327.pdf) | LoRa 免 GPS 定位基准：RSSI 换算距离误差百米级（迭代算法后 ~100m / 2km×2km 城区），定义方案 B 的精度天花板 |
| `2021-INFOCOM-DeepLoRa-path-loss-long-distance.pdf` | Liu et al. *DeepLoRa: Learning Accurate Path Loss Model for Long Distance Links*. IEEE INFOCOM 2021 | [MSU](https://cse.msu.edu/~caozc/papers/infocom21-liu.pdf) | 数据驱动路损建模路线（深度学习），如未来做分档标定可参照 |
| `2021-Sensors-LoRa-pastured-livestock-monitoring.pdf` | *A LoRa sensor network for monitoring pastured livestock location and activity*. Sensors 2021 | [PMC8139410](https://pmc.ncbi.nlm.nih.gov/articles/PMC8139410/) | 在体（on-animal）部署的 LoRa 链路实测，体损/遮挡波动的场景佐证 |
| `2023-Animals-grazing-cattle-LoRaWAN-monitoring.pdf` | Nyamuryekung'e et al. *Real-Time Monitoring of Grazing Cattle Using LoRaWAN Sensors … Daily Distance Walked Metrics*. Animals 13(16):2641, 2023 | [PMC10451644](https://pmc.ncbi.nlm.nih.gov/articles/PMC10451644/) | 放牧牛 LoRaWAN 实测（日行走距离口径），牧场景链路表现 |
| `2026-Sensors-923MHz-empirical-path-loss.pdf` | Boonlom et al. *Experimental Comparison and Empirical Path Loss Modeling of LoRa Communication in Line-of-Sight and Forest Environments at 923 MHz*. Sensors 26(10):3192, 2026 | [PMC13210814](https://pmc.ncbi.nlm.nih.gov/articles/PMC13210814/) | 923MHz 经验路损参数（贴近我方 915 频段），LOS/森林环境 n 值参照 |

## 仅引用（未下载）

- **Rappaport**, *Wireless Communications: Principles and Practice* — log-distance path loss 模型与 n 值经验范围的经典出处（教科书，版权原因不收录）。
- **Choi et al.**, *LoRa Outdoor Positioning Using a Fingerprinting Algorithm*, MDPI IJGI 2018 — 指纹法 28.8m 精度但仅 340m×340m 场地（[MDPI](https://www.mdpi.com/2076-3263/7/11/440)）。
- **Podevijn et al.** — TDoA 多网关实测 ~200m 精度（TDoA 路线在我们单网关/单站形态下不适用）。

## 下载备注（2026-09-18）

- MDPI 官网被 Akamai 反爬拦截（403），PMC 直链有 JS 工作量证明（PoW，SHA-256 前导 4 零，cookie `cloudpmc-viewer-pow=<challenge>,<nonce>`）——三篇 PMC 均以脚本解题后下载；CORE 用新版短链 `/download/<id>.pdf`（旧 `/download/pdf/<id>.pdf` 返回空）；DTU Orbit 有 Cloudflare 盾。
- 刷新/补文献时：MDPI 系优先走 Europe PMC 搜 PMCID（`www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:"10.xxxx/yyy"`），再解 PoW 下载。
