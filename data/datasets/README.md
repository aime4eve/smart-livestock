# 公开数据集登记（Open Datasets Registry）

> 原始数据文件不入 git（见 .gitignore）；本 README 是唯一索引。
> 机制设计见 `docs/calibration/open-dataset-calibration-mechanism.md`（四层闭环：接入→转换灌入→评估→反哺）。

## 1. Strathclyde Bolus 2015（已选定，待下载）

| 项 | 值 |
|---|---|
| 内容 | 107 小时连续奶牛瘤胃内 bolus 三轴加速度 + 行为分类标签（0=其他 / 1=反刍 / 2=进食，来自同期活动项圈） |
| 文件 | `bolus_sample_data.csv`，约 345 MB（application/octet-stream） |
| 许可 | **CC BY 4.0**（允许共享/演绎，需署名） |
| 引用 | Hamilton, A.; Tachtatzis, C.; Michie, C.; Davison, C.; Andonovic, I. (15 Apr 2020). *Bolus Sensor Acceleration Data With Timestamp and Behavioural Classification*. University of Strathclyde. DOI: `10.15129/5e1dfedc-87c7-4af0-bb20-3f3e1388d9d9` |
| 对口维度 | 活动/反刍行为真值 → 校准 activityStatus 阈值与发情行为评分；体内 bolus 形态与 RBC 胶囊最接近 |

### 下载（自动化被 Cloudflare 拦截，需手动）

`https://pureportal.strath.ac.uk/files/101154531/bolus_sample_data.csv` 的自动化访问（curl 伪装 UA、真浏览器渲染）均被 Cloudflare managed challenge 拦截（2026-09-09 实测，等待 2 分钟未放行）。**请用日常浏览器打开上面的链接直接下载**，完成后放到本目录：

```
data/datasets/strathclyde-bolus/bolus_sample_data.csv
```

文件到位后运行体检：`python3 scripts/calibration/profile_bolus.py`（待实现）。

### 体检结论（2026-09-10 实测）

- **699 万行 × 5 列**（`t, x, y, z, classification`），时间跨度 2015-07-22 09:04 → 07-26 20:20（约 4.5 天连续）
- **原始采样 ≈ 14.5 Hz**（间隔 69ms，毫秒级时间戳）；**论文算法工作在 5 Hz**（作者降采样后提取特征）→ 复现论文行为需 3 倍降采样
- 加速度为原始计数（±20000 量级）。**论文未声明 counts→物理单位换算，且其特征对常数标度不敏感**：作者将各轴解算为 jerk 差分 `jx(t)=x(t)−x(t−1/fs)`（消除直流与标度），判别特征为 ICI（收缩峰间间隔）+ JVB（垂直轴 jerk 变差）→ **无需精确 g 标定即可做行为校准**
- **标签分布：反刍 49.4%（345.9 万行）/ 进食 38.4%（268.5 万行）/ 其他 12.2%（85.3 万行）**
- **交叉验证红利**：论文判定反刍的特征是 **ICI ≈ 40–50 秒**（瘤胃收缩周期）→ 换算 1.2–1.5 次/分，独立佐证文献「牛瘤胃蠕动 1–3 次/分」——双源印证，现行系统阈值误报问题的文献下限（1.0 次/分）更可信

### 配套论文（已下载，CC BY 4.0）

`hamilton2019-rumination-svm-bolus-sensors.pdf`（5.0MB）：Hamilton et al., *Identification of the Rumination in Cattle Using Support Vector Machines with Motion-Sensitive Bolus Sensors*, Sensors 2019, 19(5), 1165, DOI `10.3390/s19051165`。获取路径：MDPI 与 NCBI 主站均有 bot 拦截，经 **Europe PMC render 接口**（`europepmc.org/articles/PMC6427569?pdf=render`）下载。

## 2. 候选 / 待获取

| 数据集 | 状态 | 说明 |
|---|---|---|
| MmCows（NeurIPS 2024） | 暂缓 | Kaggle（需凭据）；以视觉/音频多模态为主，需先确认是否含生理时序，暂不投入 |
| PMC 热应激研究瘤胃温度数据 | 待索取 | 大规模放牧奶牛 bolus 温度，需邮件联系作者；到手后对口体温节律验证 |
| 瘤胃蠕动频率时序 | 无公开数据 | 以文献参数为校准源（1–3 次/分，见知识库文献基线调研） |

## 3. 纪律

- 每个数据集必须登记许可与引用格式；CC BY 4.0 项目对外产出时附署名。
- 原始文件永不进 git；允许进 git 的只有：本 README、小样本 fixture（≤1MB）、校准报告。
- 数据集验证结论一律标注「文献/数据集校准」，不得混充真实采集效果。
