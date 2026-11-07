# HKT Technical Integration & Continuity Checklist — Response

> **Respondent**: HKT Technical Team ｜ **Date**: 2026-11-06 ｜ **Version**: v1.1
> **How to read the notes**: where the answer is "Yes", we state the conditions under which it holds; where the answer is "No", we explain how we achieve the same goal or what it takes to get there; where the answer is "To be discussed", we list exactly what needs to be discussed. All features and commercial terms are subject to the formal contract and technical agreement.

---

## A. What can the RBC-100 + current HKT software provide today?

| Capability | Available now | Under development | Not available | HKT notes |
|------------|:---:|:---:|:---:|-----------|
| Rumen / internal body temperature | [x] | [ ] | [ ] | The bolus reports rumen temperature every 30 minutes; per-cow temperature curves are available in the software. If connectivity is lost, data is buffered on the bolus and uploaded automatically once the link recovers |
| Activity / motion | [x] | [ ] | [ ] | The bolus has a built-in motion sensor; the software shows each cow's activity level (high / medium / low) and trends |
| Rumen motility / contraction count | [x] | [ ] | [ ] | The bolus continuously records rumen contractions; the software converts this into contractions-per-minute trends |
| Drinking activity / drinking frequency | [x] | [ ] | [ ] | Drinking events are detected automatically from temperature changes (no extra device needed): daily drinking count, time-of-day distribution and trends, with comparison against herdmates; currently a statistics feature — automatic drinking-abnormality alerts are on the roadmap |
| Rumination behavior | [ ] | [x] | [ ] | Behavior recognition (rumination / feeding / lying / walking) is on the R&D roadmap; the data foundation is ready |
| Feeding / eating behavior | [ ] | [x] | [ ] | Same as above — part of the behavior-recognition roadmap |
| Resting / lying behavior | [ ] | [x] | [ ] | Same as above — part of the behavior-recognition roadmap |
| Fever alert | [x] | [ ] | [ ] | Automatic warning when temperature stays elevated, pushed to the alert center by severity |
| Digestive / low-motility alert | [x] | [ ] | [ ] | Automatic notification when rumen motility drops significantly, helping detect digestive problems early |
| General health anomaly alerts | [x] | [ ] | [ ] | Dual protection of rule-based checks + AI analysis, combining temperature, motility and activity to flag abnormal animals |
| Heat / estrus detection | [x] | [ ] | [ ] | Automatic estrus detection with a score that updates as new data arrives |
| Insemination timing / breeding advice | [ ] | [x] | [ ] | Estrus results can already serve as a reference for manual insemination planning; automatic breeding advice and reproduction records (mating → conception → due date) are under development |
| Pregnancy / fertility monitoring | [ ] | [x] | [ ] | Part of the reproduction-management feature set, under development |
| Calving prediction | [ ] | [x] | [ ] | Calving reminders are being developed together with the reproduction-management features |
| Battery / device status | [x] | [ ] | [ ] | Battery, online status and signal quality are monitored in real time; automatic alerts for device offline or tampering |
| Historical charts / trends | [x] | [ ] | [ ] | Historical curves and statistical reports for temperature, motility, activity and drinking |

---

## B. Data flow & infrastructure

**1. Can RBC-100 data be sent directly to our servers without passing through the HKT cloud first? Please describe the normal data path.**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" under the following conditions — you operate your own network server and connect through one of the standard integration options we provide (direct platform connection or a data-push interface); data then flows from the bolus straight to your servers, bypassing the HKT cloud. The direct-connection option is already in real use in our own environments. The normal data path is: bolus → gateway → network server → our IoT platform → the farm-management software.

**2. Can we use our own LoRaWAN network server, e.g. ChirpStack or TTN?**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" subject to frequency-band compatibility — the devices follow the international LoRaWAN standard and work with mainstream network servers such as ChirpStack and TTN (our own test environment also uses ChirpStack). On frequency bands: devices are adapted to the radio band of the destination country, and **EU868 — the standard band for Europe — is an existing version that can be supplied directly**, with no custom lead time required.

**3. Will HKT provide the protocol, payload format, decoder and sample payloads needed to read all RBC-100 data? Please list the documents/materials HKT can provide.**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" once the device version of each delivery batch is confirmed — we will provide the product user manual, the data-format specification, a sample decoding script and real sample payloads, which are sufficient for your engineers to complete the integration independently.

**4. Will HKT provide all device registration information / keys needed to run the boluses on our own LoRaWAN infrastructure?**

Answer: Yes [x]　No [ ]　To be further discussed [x]

Notes: We answer "Yes" once the key-delivery process is agreed in a technical agreement — all registration information and keys required for network onboarding can be provided together with each device batch. **What needs further discussion**: ① the format in which keys are delivered; ② how confidentiality is ensured during delivery and storage; ③ how keys for follow-up orders will be provided.

**5. Do any RBC-100 functions depend on cloud services, APIs, license servers or activation servers controlled by HKT? If yes, please list them precisely.**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: The answer is "Yes" under the standard setup (data relayed via our platform, or operations hosted by us) — only two items depend on our cloud: ① the data-relay channel for device data; ② the operation & upgrade service in the hosted model. If you choose the **on-premises deployment**, the entire software stack (including AI analysis) runs in your own facility, depends on no HKT cloud service, and requires no online verification or activation.

**6. If the HKT cloud is temporarily unavailable, can the boluses, gateways and our own servers continue to receive and store data?**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" under the on-premises deployment — the software and data reside locally with you, and a temporary HKT cloud outage does not affect any local function or existing data. Even if the data link is interrupted, the bolus buffers the data and backfills automatically once the link recovers. If you use your own network server, the data path does not pass through us at all.

**7. Can all historical cattle / device data be exported at any time in a standard format, e.g. CSV / JSON / database export?**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" with API access enabled (or with an on-premises deployment) — ① export at any time via the standard data API (CSV / JSON); ② even after the cooperation ends, a 30-day self-service export window remains; ③ with on-premises deployment, all data stays in your facility and can be exported directly at any time — data never leaves your premises.

---

## C. Software customization & local deployment

> **Two recommended approaches for software customization**: Option one — HKT does the customization for you: you submit requirements, we evaluate, quote, develop and deliver, and we take care of maintenance and version continuity. Option two — build your own front end on top of our Open API: you develop the UI and workflows freely inside your own system. Both are more sustainable than modifying source code directly.

**1. Can HKT provide access to the front-end (UI) source code so that we can improve usability, language, branding and workflows?**

Answer: Yes [ ]　No [x]　To be further discussed [ ]

Notes: To safeguard long-term software quality and upgrade continuity, the source code is not opened externally. We help you reach the same goals in two ways: ① we do the customization for you — usability, language, branding and workflow adjustments can all be submitted as requirements, implemented and maintained by us; ② you build your own front end on our Open API (see C2/C3). For adjustments like language, product name or logo, no source code is needed at all — we provide them as product configuration (the UI already supports Chinese / English; other languages can be added as needed).

**2. Can our developers modify the dashboard, cattle pages, alert screens, navigation and customer/farm workflows?**

Answer: Yes [ ]　No [x]　To be discussed [ ]

Notes: Direct modification of our source code is not supported (it would break future version upgrades). We recommend instead: ① customization by us — tell us what you want changed, and we schedule, implement and maintain it as part of the official release; ② building on the Open API yourselves — we provide API documentation, keys and a usage dashboard, so your developers can build dashboards, cattle pages, alert screens and more with full autonomy, covering most customization goals.

**3. Can our modified UI be deployed on our own servers / cloud?**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" for front ends built on the Open API — where you deploy them (your own servers or your own cloud) is entirely your choice. Parts customized by us are delivered and deployed together with the platform; with an on-premises deployment, customized content is also installed in your environment as part of the package.

**4. Can HKT provide the database schema / data model and deployment instructions needed to run the software locally?**

Answer: Yes [x]　No [ ]　To be further discussed [ ]

Notes: We answer "Yes" with an on-premises deployment — we deliver a complete installation package with deployment and operation documentation; the database is created automatically during installation, and data-structure documentation can be provided as agreed in the contract. The on-premises deployment has been fully validated end-to-end in our own verification environment.

**5. Can external developers working for us access and modify the agreed source code under NDA / confidentiality terms?**

Answer: Yes [ ]　No [x]　To be further discussed [ ]

Notes: Since the source code is not opened externally, source-code access by external developers does not apply. Your external developers can instead work with the Open API — all they need is the API documentation and keys; no source-code access and no additional confidentiality arrangements are required (the API itself is opened on a least-privilege scope).

---

## D. Algorithms & long-term technical operation

**1. Which current alerts / algorithms run inside the bolus, and which run in the HKT software / cloud? E.g. fever, drinking, motility, estrus and health anomalies.**

Notes: The bolus only measures and transmits raw data (temperature, rumen motility, activity, battery); it makes no judgments of its own. All analysis and alerts (fever, digestion, drinking, estrus, disease, health anomalies) are performed in the software platform.

**2. Can the algorithms currently running in the HKT software / cloud also run on our own servers?**

Answer: Yes [x]　No [ ]　To be further discussed [ ]

Notes: We answer "Yes" with an on-premises deployment — all analysis functions (including AI) are installed on your servers as part of the package, run locally, and do not depend on our cloud. Even if the AI module is temporarily unavailable, the basic health assessment and alert functions continue to work.

**3. If an SDK or algorithm package is required, can it run locally without a permanent connection to HKT servers?**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" under the on-premises model — the software and all analysis functions run entirely locally, with no permanent connection to our servers. The license is activated once by importing a license file; a new file is only needed at renewal.

**4. Does locally installed HKT software require periodic online license verification or remote activation by HKT?**

Answer: Yes [ ]　No [x]　To be further discussed [ ]

Notes: We achieve this through **offline licensing** — a license file is imported once for activation, no online verification is needed during daily use, and we operate no remote activation server. When a license expires, the software automatically falls back to basic functions with all data retained; importing a renewed license restores everything immediately.

**5. If we build our own UI improvements or new business functions, can we keep using them together with HKT hardware?**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: We answer "Yes" provided your own system ingests device data through our data interfaces — hardware and software are decoupled, so your own UI and business functions can keep working with HKT hardware long-term (data formats and key support: see B3/B4).

**6. If HKT-hosted services become unavailable, which current functions keep running locally and which stop? Please list them clearly.**

Notes (for the on-premises model):

- **Keep running**: login and accounts, dashboards and maps, geofencing, alert center, health analysis (fever / digestion / estrus / disease / drinking), AI analysis, historical data and charts, data export;
- **Paused**: data relay via our platform (unaffected if you use your own data link — and the bolus buffers data and backfills after recovery); remote maintenance and version upgrades provided by us (the local system keeps running; upgrades resume once service is restored).

---

## E. Software access after September 30, 2027

**1. After September 30, 2027, will we need to purchase, lease or subscribe to the HKT software? Please describe the available options.**

Answer: Yes [x]　No [ ]　To be discussed [ ]

Notes: The answer is "Yes" once the free-trial period ends (uniformly on 2027-09-30; during the trial you enjoy the full Professional-tier features and only need to invest in the devices). Two options afterwards: ① **per-head subscription** (billed monthly — you pay for as many head as you run); ② **Enterprise buyout** (on-premises deployment + custom development + dedicated support). Details are subject to the commercial contract.

**2. If there is a recurring fee, how is it calculated — per cow, per bolus, per farm, per server, per account, per API usage, or per year?**

Answer: Yes [x] (per cow)　No [ ]　To be discussed [ ]

Notes: The fee is **calculated per head of cattle** — monthly fee = herd size × unit price, with lower unit prices at larger scales and no upper limit on headcount. Devices are a one-time purchase and belong to you; they are not part of the subscription. There is no charge per server, per account or per API usage.

**3. If a future subscription is not renewed, which specific functions stop? Please separate cloud/hosted functions from bulk data collection and local software functions.**

Notes: On expiry, the system automatically falls back to the free Basic tier —

- **Keep running**: location tracking, basic device management, geofencing (up to 3 fences); **device-data reception and storage continue without interruption**;
- **Stop**: paid features such as extended history, health analysis (temperature / estrus / disease) and AI analysis;
- **Data protection**: all existing data is **fully retained, never deleted**; self-service export of all data remains available for 30 days after expiry; features are restored immediately upon renewal.

**4. Does non-renewal affect our ability to receive raw / device data from the RBC-100 on our own servers?**

Answer: Yes [ ]　No [x]　To be discussed [ ]

Notes: We guarantee this through a "downgrade only, never cut off data" mechanism — non-renewal only downgrades features to the Basic tier; device-data reception and storage are not interrupted. If you use your own data link, the data path is entirely independent of subscription status.

**5. Does non-renewal affect locally deployed algorithms / SDK on our servers?**

Answer: Yes [x]　No [ ]　To be further discussed [ ]

Notes: The "Yes" applies when the local license expires without renewal — the software falls back to basic functions (paid features including AI are paused), while **all data is retained**. **Recovery condition**: importing a renewed license restores everything immediately, with no reinstallation required.

---

> This document has been prepared for our upcoming technical meeting, to align on platform capabilities and long-term service continuity arrangements beforehand. Items marked "To be discussed" (key delivery process, commercial terms), together with the detailed scope of any custom-development requirements, are proposed for the meeting agenda.
