# Rumen Bolus Retention — Engineering Design Basis & Industry Evidence

**Document type:** Technical white paper
**Product:** HKT Rumen Bolus (LoRaWAN) · Platform: BoviScout
**Version:** 1.0 · **Date:** 2026-11-06
**Audience:** Customers, distributors, and technical evaluators

---

## 1. Purpose and Scope

This document explains the engineering design basis that governs rumen retention of the HKT Rumen Bolus, and summarizes the publicly available, peer-reviewed evidence for the retention behavior of this **device class** (intraruminal sensor boluses).

> **Transparency note.** The publications cited in Section 3 are independent third-party studies describing intraruminal boluses as a device class. They are **not** field studies of the HKT Rumen Bolus itself. HKT's own long-term, device-specific field validation is currently in progress; customers are invited to participate in a joint pilot study (see Section 5).

## 2. Engineering Design Basis

Intraruminal bolus retention is governed by well-established engineering parameters. The HKT Rumen Bolus is designed according to these principles:

| Design parameter | Principle | Rationale |
|---|---|---|
| **Specific gravity** | Bolus overall specific gravity is designed to be > 2.0 | Ensures the bolus sinks and remains in the ventral sac/reticulum region rather than floating with the fibrous raft, where regurgitation risk is higher. |
| **Geometry** | Smooth cylindrical capsule, no protrusions | Prevents mechanical irritation of the rumen wall and minimizes the chance of migration toward the reticulo-omasal orifice. |
| **Size** | Sized beyond the passage threshold of the reticulo-omasal orifice in adult cattle | A correctly sized bolus cannot physically exit the reticulorumen in a healthy adult animal. |
| **Center of gravity** | Internal component layout keeps the center of gravity low and stable | Maintains a stable orientation for the sensor end and reduces tumbling. |
| **Administration** | Oral administration with a standard balling gun by a trained operator, only to animals above the specified minimum body weight | Correct administration is the single largest operational factor in retention; our administration SOP is provided with each shipment. |

## 3. Industry Evidence (Third-Party Publications)

The following peer-reviewed publications and invited reviews document the retention behavior and long-term in-situ operation of intraruminal boluses as a device class:

| # | Reference | Relevance to retention |
|---|---|---|
| 1 | **Han, C. S., et al. (2022).** "Invited review: Sensor technologies for real-time monitoring of the rumen environment." *Journal of Dairy Science*, 105(8), 6379–6404. DOI: [10.3168/jds.2021-20576](https://doi.org/10.3168/jds.2021-20576) | Comprehensive invited review of commercial and research rumen boluses; documents long-term in-situ operation as the established state of the art. |
| 2 | **Weir, C. D., et al. (2025).** Head-to-head comparison of two commercial rumen boluses. *Journal of Animal Science*. DOI: [10.1093/jas/skaf129](https://doi.org/10.1093/jas/skaf129) | 126-day trial in ruminally cannulated heifers with two commercial boluses; boluses remained in situ and functional throughout the trial period. |
| 3 | **Phillips, N., Mottram, T., et al. (2009).** "Continuous monitoring of ruminal pH using wireless telemetry." *Animal Production Science* (CSIRO). | On-farm deployment of a wireless rumen bolus; positional stability of the bolus within the reticulorumen was confirmed over the measurement period. |
| 4 | **Mottram, T. T. (2010).** "Is a lifetime rumen monitoring bolus possible?" *First North American Conference on Precision Dairy Management*. | Engineering analysis of multi-year in-situ bolus operation; establishes specific gravity (≥ ~2.0) as the key design parameter for long-term retention. |
| 5 | **Vakulya, G., et al. (2024).** Multifunctional LoRaWAN rumen bolus. *Sensors* (MDPI). DOI: [10.3390/s24216976](https://doi.org/10.3390/s24216976) | Demonstrates a LoRaWAN-based multifunctional bolus of the same architecture class as the HKT Rumen Bolus operating in live animals. |
| 6 | **Gesler, P. (2022).** Book chapter on commercial-farm bolus deployment, in *Practical Precision Livestock Farming*. DOI: [10.3920/978-90-8686-934-3_10](https://doi.org/10.3920/978-90-8686-934-3_10) | Documents commercial-farm operation of a rumen bolus system, including IoT gateway architecture and cloud analytics. |
| 7 | **Caja, G., Nehring, R., & Conill, C. (1999).** "Development of small boluses for the electronic identification of sheep and goats." *Computers and Electronics in Agriculture*, 24(1–2), 45–63. DOI: [10.1016/S0168-1699(99)00039-9](https://doi.org/10.1016/S0168-1699(99)00039-9) | Systematic study of how bolus size, weight and specific gravity determine retention in small ruminants; establishes the size/density design window. |

## 4. Material Safety Basis

- The bolus housing uses **biocompatible, food-contact-grade polymer** selected for long-term exposure to the rumen environment (moisture, pH 5.5–7.0, temperature up to ~41 °C, mechanical abrasion).
- All electronics are fully **potted and hermetically sealed**; the enclosure carries an **IP68** ingress protection rating verified in factory testing.
- The product complies with **RoHS** and **CE-RED** requirements; compliance documentation is available on request.
- Factory quality testing includes waterproof immersion, thermal cycling, and vibration/drop testing. Batch test records are retained for traceability.

## 5. Our Own Validation — Status and Invitation

HKT is currently running small-scale pilot deployments with dairy farms, and device-specific long-term retention and safety data are being collected under these programs. Because we believe validation claims must be verifiable, we do not present interim figures as final study results.

We invite interested customers to join a **structured joint pilot study** (30–50 head, 6 months, defined retention checkpoints and safety endpoints), with preferential pilot pricing and a co-authored case study on completion. A ready-to-execute study protocol is available in the companion document: *Joint Field Pilot Study — Protocol*.

---

*This document is provided for technical evaluation purposes. For questions, contact your HKT representative.*
