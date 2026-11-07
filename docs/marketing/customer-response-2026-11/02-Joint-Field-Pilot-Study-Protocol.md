# Joint Field Pilot Study — Protocol

**Document type:** Study protocol (template, ready to adapt per farm)
**Product:** HKT Rumen Bolus (LoRaWAN) + LoRaWAN Gateway · Platform: BoviScout
**Version:** 1.0 · **Date:** 2026-11-06
**Parties:** HKT (technology provider) and the participating farm/customer ("Partner")

---

## 1. Objectives

| # | Objective | Primary endpoint |
|---|---|---|
| O1 | **Retention**: verify that boluses remain in the reticulorumen of adult cattle | Retention rate at each checkpoint; expulsion events logged with date and circumstances |
| O2 | **Safety**: observe animal health following bolus administration | Adverse event log; veterinary examination findings at checkpoints |
| O3 | **Performance**: verify telemetry continuity and platform alerting under real farm conditions | Device online rate; data completeness; alert event log |

## 2. Study Design

- **Type:** Prospective, single-herd observational pilot.
- **Herd size:** 30–50 adult cattle (minimum 30 for a meaningful retention estimate).
- **Duration:** 6 months (24 weeks), extendable to 12 months by mutual agreement.
- **Animals — inclusion criteria:**
  - Adult cattle, body weight ≥ 450 kg (adjusted per breed at protocol signing)
  - Clinically healthy at enrollment (appetite, rumination, temperature normal)
  - Expected to remain on the farm for the study duration
- **Exclusion criteria:** animals with a history of hardware disease (traumatic reticuloperitonitis), animals within 30 days of calving, or animals intended for culling during the study period.
- **Equipment:** HKT Rumen Bolus per enrolled animal; one or more LoRaWAN gateways covering the barn/feeding area; BoviScout platform account.

## 3. Administration SOP

1. Boluses are administered **orally with a standard balling gun** by a trained operator (HKT provides remote or on-site training).
2. Animals must be restrained (head gate or crush) during administration.
3. Record per animal: animal ID, bolus device ID, body weight, date/time, operator, and immediate post-administration observation (30 minutes).
4. Do not administer to animals below the minimum body weight or showing signs of illness.

## 4. Measurement Schedule

| Checkpoint | Retention verification | Safety | Performance |
|---|---|---|---|
| **Week 0** (enrollment) | Administration records; first telemetry frame confirms in-situ operation | Baseline vet check | Gateway coverage test |
| **Week 1** | Telemetry continuity check (all devices reporting) | Daily observation log | Online rate review |
| **Week 4** | Telemetry continuity + physical observation | Vet check | Data completeness report |
| **Week 8** | Telemetry continuity | Daily observation log | Alert event review |
| **Week 12** | Telemetry continuity + physical observation | Vet check | Interim report |
| **Week 24** | Final telemetry continuity + physical observation | Final vet check | Final report |

**Retention verification method:** continuous telemetry reception via the BoviScout platform is the primary retention indicator (a bolus that has exited the rumen stops reporting or shows an anomalous temperature signature). Suspected expulsions are confirmed by physical examination (e.g., transrectal/manual assessment by the farm veterinarian, or recovery of the device).

**Safety observation:** the farm staff record daily appetite, rumination, and general condition for enrolled animals during weeks 0–4, then weekly. Any health event in an enrolled animal is logged as a potential adverse event and assessed by the farm veterinarian for relatedness to the device.

## 5. Roles and Responsibilities

| Party | Responsibilities |
|---|---|
| **HKT** | Supply boluses, gateway(s) and platform access at preferential pilot pricing; administration training; remote technical support; monthly data summaries; interim and final reports. |
| **Partner (farm/customer)** | Provide eligible animals and facilities; perform or arrange administration and daily observations; maintain the adverse event log; arrange veterinary checkpoint examinations; grant HKT access to study data. |

## 6. Data, Reporting and Publication

- All study data are jointly owned by HKT and the Partner.
- HKT delivers a **monthly summary**, a **week-12 interim report**, and a **final study report** covering retention rate, safety findings, and telemetry performance.
- With the Partner's written consent, results may be published as a **co-authored case study**. No farm-identifying information is published without written authorization.

## 7. Annexes (templates provided at signing)

- **Annex A** — Animal enrollment & administration record
- **Annex B** — Retention checkpoint log (per animal, per checkpoint: device ID, telemetry status, physical check result, notes)
- **Annex C** — Adverse event record (date, animal ID, description, veterinary assessment, relatedness, outcome)
- **Annex D** — Monthly performance summary template (online rate, data completeness, alert counts)

---

*This protocol is a template; animal numbers, duration, and checkpoint cadence are adapted to the Partner's herd and local veterinary practice at signing.*
