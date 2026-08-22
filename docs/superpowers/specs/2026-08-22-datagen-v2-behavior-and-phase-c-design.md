# datagen v2 与 AI Phase C 设计

> Date: 2026-08-22  
> Status: 待评审  
> Issue: NIX-147  
> Roadmap: `2026-06-19-ai-health-roadmap.md` §4  
> Baseline: `2026-06-26-datagen-context-design.md`

---

## 1. Position

datagen v2 is the data infrastructure for AI Phase C. It extends v1 from binary anomaly injection to **behavior feature synthesis, multi-label behavior labels, multi-class evaluation, and a real-data adapter**.

The design does not assume that current sparse snapshots can recognize fine behaviors. Current tracker/capsule telemetry is dominated by 5-15 minute datagen intervals or sparse blade snapshots, and the current LIS3DH low-power mode has roughly 16mg resolution. That is useful for coarse rest/light/active/intense classification, but not enough for 1.2Hz rumination jaw movement or irregular biting patterns.

Therefore v2 has three explicit layers:

1. **Offline waveform synthesis**: simulate 10-25Hz accelerometer signals for research datasets.
2. **Device-window summary**: compress each 5-minute window into a protocol-compatible feature vector, aligned with proposed firmware TLV `0x40`.
3. **Sparse-snapshot adapter**: use current GPS, step count, activity class, posture, and capsule motility only for coarse behavior, with an explicit `COARSE` quality marker.

Raw high-rate waveforms are not sent over LoRaWAN and are not ingested into production telemetry tables.

## 2. Label Model

### 2.1 Why not one flat class

Cattle behaviors overlap: a cow can ruminate while lying, walk while grazing, and change posture during calving. A single mutually-exclusive label would erase this information and make evaluation look worse than reality.

datagen v2 therefore uses a **dominant class + multi-label facets** model.

### 2.2 Dominant classes

Dominant class is the primary activity occupying the 5-minute window. It is used for the required confusion matrix.

| Class | Description | Target signals |
|---|---|---|
| `LYING` | Lying/resting posture; sleep is not claimed | Static gravity orientation, low dynamic acceleration, near-zero steps/distance |
| `RUMINATING` | Regular rumination chewing, commonly while lying or standing | 1.0-1.5Hz jaw movement, low spectral entropy, low locomotion |
| `FEEDING` | Grazing/biting and chewing | Irregular 1.5-3Hz bursts, head-down posture, low-to-medium locomotion |
| `WALKING` | Purposeful locomotion | Step cadence, GPS speed, medium/high dynamic acceleration |
| `OTHER` | Valid but unmodeled activity | No strong signature; intentionally retained to reduce forced labels |

`UNKNOWN` is not a dominant class. It is a data-quality state for windows with insufficient feature coverage.

### 2.3 Multi-label facets

| Facet | Values | Notes |
|---|---|---|
| `posture` | `LYING`, `STANDING`, `TRANSITION` | Sleep is represented only as `LYING`; do not infer sleep |
| `oral_activity` | `RUMINATING`, `FEEDING`, `NONE`, `MIXED` | Requires 0x40 or research-grade waveform |
| `locomotion` | `STATIONARY`, `WALKING`, `HIGH_ACTIVITY` | Coarse sparse data can support this facet |
| `event` | `NONE`, `CALVING_RISK`, `ESTRUS_LIKE` | Event overlay, not a competing base behavior |

A window can have `posture=LYING`, `oral_activity=RUMINATING`, `locomotion=STATIONARY`, and `event=NONE`.

### 2.4 Calving and estrus

Calving is not included as an ordinary dominant class. It is a rare, sequential event synthesized as increased posture transitions, restlessness, step bursts, and possible activity clustering. Without real labels, synthetic calving data validates the event pipeline but cannot substantiate clinical accuracy.

Estrus remains a Phase C supervised pattern-recognition task. Behavior features can augment it, but estrus labels must come from reproductive records or human confirmation; datagen only creates pipeline-level synthetic examples.

## 3. Waveform and Feature Contract

### 3.1 Synthesis rates

| Dataset mode | Internal rate | Output | Purpose |
|---|---:|---|---|
| `RESEARCH_WAVEFORM` | 25Hz | Offline NumPy/Parquet only | Verify waveform morphology and feature extraction |
| `PROTOCOL_SUMMARY` | Derived from 25Hz | 5-minute feature record | Model training/evaluation and future 0x40 decoding |
| `SPARSE_SNAPSHOT` | 5-15 minutes | Current telemetry dimensions | Coarse behavior only |

### 3.2 Waveform primitives

All primitives are parameterized by individual baseline, device orientation, noise, missingness, and class duration.

| Primitive | Model | Expected statistics |
|---|---|---|
| Rumination chew | Quasi-periodic 1.0-1.5Hz sinusoid plus device orientation | Clear spectral peak; low entropy; low locomotion |
| Feeding bite | Irregular 1.5-3Hz bursts with pauses | Higher spectral entropy; burst count; head-down tilt |
| Lying static | Stable gravity vector plus low-amplitude noise | Stable roll/pitch; near-zero dynamic variance |
| Walking | Step cadence plus bearing drift | 1.5-2.5Hz cadence; GPS speed 0.4-1.5m/s; step count |
| Posture transition | Orientation change over 1-4s | Roll/pitch delta; transient dynamic acceleration |
| Calving restlessness | Bursty transitions and step surges | Increased transition count and activity variance |

### 3.3 Five-minute feature vector

The protocol summary stores fixed-width features, not raw samples:

| Feature | Type | Notes |
|---|---:|---|
| `sample_count` / `expected_sample_count` | integer | Coverage |
| `accel_mean_x/y/z`, `accel_std_x/y/z` | decimal | Static and dynamic components |
| `roll_mean/std`, `pitch_mean/std` | decimal | Posture |
| `dominant_freq_hz`, `spectral_power_ratio`, `spectral_entropy` | decimal | Oral activity |
| `burst_count`, `zero_crossing_rate` | integer/decimal | Feeding and movement |
| `step_count`, `distance_meters`, `mean_speed_mps` | decimal | Locomotion |
| `activity_class_counts` | fixed vector | rest/light/active/intense |
| `capsule_motility_mean/std` | decimal | Cross-check only, not a behavior label |
| `posture_transition_count` | integer | Restlessness |
| `missing_feature_mask` | bitset | Adapter quality |

The exact TLV encoding is a separate firmware contract. This document fixes the semantic fields and requires all synthetic and real adapters to produce the same vector.

Every adapter validates required fields, numeric ranges, feature version, and `feature_schema_hash` before write. A model whose registered schema hash differs from the window's hash must reject that window rather than silently imputing incompatible fields.

## 4. Data Model

### 4.1 `behavior_windows`

Owned by datagen as the Phase C feature store. Future v3 governance can generalize it; Phase C does not create a second parallel table.

| Column | Description |
|---|---|
| `id`, `tenant_id`, `farm_id`, `livestock_id`, `device_id` | Scope |
| `dataset_id`, `episode_id` | Dataset and contiguous behavior episode |
| `window_start`, `window_end` | 5-minute boundary |
| `dominant_behavior` | §2.2 enum |
| `feature_version`, `feature_schema_hash`, `features` JSONB | Semantic feature contract |
| `input_quality` | `FULL_0X40`, `PARTIAL_0X40`, `COARSE_SNAPSHOT`, `UNKNOWN` |
| `data_source` | `DATAGEN`, `AGENTIC_PLATFORM`, `MANUAL_IMPORT`, `RESEARCH_IMPORT` |
| `dataset_split` | `TRAIN`, `VALIDATION`, `TEST`, `UNASSIGNED` |
| `sampling_mode` | `PROTOCOL_SUMMARY`, `SPARSE_SNAPSHOT`, `RESEARCH_WAVEFORM` |
| `model_compatible` | boolean | Derived from quality/version rules |

Unique key: `(device_id, window_start, feature_version)`.

Within one dataset, split leakage is prevented by two partial unique constraints:

```sql
UNIQUE (dataset_id, livestock_id, dataset_split)
UNIQUE (dataset_id, episode_id, dataset_split)
```

The second constraint is redundant for single-livestock episodes but protects future group episodes. The service must reject an attempted episode split when any member livestock already belongs to another split in the same dataset.

### 4.2 `behavior_window_labels`

One row per multi-label facet value:

- `window_id`
- `facet` (`posture`, `oral_activity`, `locomotion`, `event`)
- `label_value`
- `label_source` (`SYNTHETIC`, `MANUAL`, `REPRODUCTIVE_RECORD`, `VIDEO`, `SENSOR_RULE`)
- `confidence`
- `labeler_id`, `labeled_at`, `note`

The dominant behavior is denormalized on `behavior_windows` for efficient retrieval, while facets remain source-attributed.

### 4.3 `behavior_predictions`

One row per model run per window:

- `window_id`
- `model_name`, `model_version`
- `predicted_dominant_behavior`, `dominant_probability`
- `predicted_labels` JSONB
- `probability_vector` JSONB
- `capability_level` (`L1_RULE`, `L2_SUPERVISED`)
- `predicted_at`

Evaluation joins predictions to labels by `window_id`; it never treats a later prediction as ground truth.

### 4.4 Split strategy

Splits are blocked by **farm + livestock + contiguous episode**, not randomly by window.

1. Assign each livestock to exactly one split.
2. Keep all windows from one synthetic episode together.
3. Reserve a time-blocked validation/test period, not random windows from the same day.
4. Never mix synthetic and real rows in the same test set.
5. Report synthetic pretraining, real fine-tuning, and real-only evaluation separately.

Split assignment is not a convention left to an export script. Persistence and evaluation service tests must reject any attempt to assign one livestock or episode to multiple splits in the same dataset.

## 5. Generator Design

### 5.1 Scenario model

Extend the v1 scenario model with `Category.BEHAVIOR`, but avoid adding every behavior as a Java enum value. A behavior scenario carries:

- target farm/livestock/device set
- behavior mix and transition matrix
- diurnal activity prior
- individual random-effect seed
- missingness and noise profile
- optional overlays: estrus-like activity, calving-like restlessness, lameness-like suppression

This is a stochastic schedule, not a one-frame modulation. It emits episode timelines and then derives windows.

### 5.2 Generation flow

```text
BehaviorScenario
  -> individual baseline and daily activity schedule
  -> behavior state timeline (semi-Markov transition model)
  -> offline 25Hz waveform episode
  -> feature extraction
  -> protocol summary / sparse snapshot degradation
  -> behavior_windows + behavior_window_labels
```

The generator does not call `TelemetryIngestionService` for research waveforms. For production-path validation, it can emit a protocol summary that follows the same decoding and persistence contract as real 0x40 data.

### 5.3 Realism controls

Every generated dataset must include:

- class imbalance matching a plausible daily budget
- individual and device orientation variation
- missing windows and partial feature masks
- sampling jitter and dropouts
- label ambiguity windows, retained with `confidence < 1.0`
- adversarial near-classes: ruminating vs feeding, lying vs standing-ruminating, feeding while walking slowly

Generated files are reproducible from `(scenario_id, seed, generator_version)`.

## 6. Real-Data Adapter

### 6.1 Input ranks

| Rank | Input | Supported labels | `input_quality` |
|---|---|---|---|
| R1 | Real 0x40 full feature vector | Dominant + all facets | `FULL_0X40` |
| R2 | Partial 0x40 / dropped fields | Reduced label set | `PARTIAL_0X40` |
| R3 | Current sparse GPS + steps + activity class + posture | Coarse posture/locomotion only | `COARSE_SNAPSHOT` |
| R4 | Capsule motility only | Cross-check only, no behavior class | `UNKNOWN` for behavior |

### 6.2 Router behavior

- `FULL_0X40`: use L2 supervised behavior classifier.
- `PARTIAL_0X40`: use masked-feature model or L1 rule fallback.
- `COARSE_SNAPSHOT`: only classify broad locomotion/posture groups; mark fine oral activity unavailable.
- `UNKNOWN`: no behavior prediction; do not silently substitute health anomaly score.

No model code may branch on `data_source == DATAGEN`. Source is used only for dataset construction, traceability, and evaluation separation.

## 7. Evaluation

### 7.1 Dominant-class metrics

Report a confusion matrix over `LYING`, `RUMINATING`, `FEEDING`, `WALKING`, and `OTHER`, plus:

- accuracy
- macro precision / recall / F1
- weighted F1 using class support
- per-class support and predicted count
- class imbalance ratio
- top-2 accuracy for near-class diagnosis

Exact-match accuracy is never the sole release metric.

### 7.2 Multi-label metrics

For every facet:

- binary TP/FP/FN/TN
- precision, recall, F1, average precision
- calibration by confidence bin
- missing-label impact report

### 7.3 Boundary and event metrics

- For class transitions, allow a one-window tolerance and report boundary F1.
- For calving-like events, evaluate event-level precision/recall after merging adjacent positive windows.
- Report event detection latency relative to the synthetic event start.
- Do not average event latency when an event is missed.

### 7.4 Honest reporting

Every report is partitioned by:

- `data_source`
- `input_quality`
- dataset split
- farm/livestock grouping

Synthetic results are labeled `PIPELINE_ONLY`. They prove feature extraction, training, and evaluation mechanics; they do not prove real-world behavior accuracy.

Evaluation rejects a non-debug request whose selected test windows contain multiple `data_source` values. A mixed-source report is allowed only when `allow_mixed_debug=true` is explicitly set; its title and JSON metadata must carry `debug=true` and list the mixed sources.

## 8. ai-platform Phase C Capability

### 8.1 New capability

Add an L2 behavior capability beside `health_l1`:

```text
POST /ai/behavior/analyze
POST /ai/behavior/analyze/{livestock_id}
```

Request carries farm/livestock/window scope. Java retrieves compatible `behavior_windows`, calls ai-platform, and persists returned predictions.

### 8.2 Model progression

1. **Baseline rules**: posture and locomotion from roll/pitch, step count, speed, and activity class.
2. **Masked tabular model**: gradient boosting or shallow neural model over protocol features.
3. **Optional waveform pretrainer**: 1D CNN or contrastive model on offline 25Hz waveforms, distilled into the tabular feature model.

The production endpoint consumes feature vectors, not raw waveforms. Raw-waveform models are research artifacts until firmware or offline collection supplies them.

## 9. Phase C Work Breakdown

| Stage | Deliverable | Can run on synthetic? | Real dependency |
|---|---|---:|---|
| C0 | Freeze feature contract and label schema | Yes | No |
| C1 | Waveform generator + deterministic dataset export | Yes | No |
| C2 | `behavior_windows` + labels + predictions persistence | Yes | No |
| C3 | Multi-label evaluation service and reports | Yes | No |
| C4 | Coarse posture/locomotion rules from current telemetry | Partially | Current sparse input |
| C5 | L2 supervised behavior model pretraining | Yes | Real data for final claim |
| C6 | Firmware 0x40 real adapter | Pipeline test only | Firmware + real devices |
| C7 | Real-data fine-tuning and real-only test | No | NIX-146 / #55 |
| C8 | Estrus pattern model augmentation | Pipeline test only | Reproductive labels |
| C9 | Manual annotation and active learning | No | #56 / veterinary workflow |
| C10 | Calving event pipeline | Pipeline test only | Confirmed calving records |

## 10. Acceptance Criteria

- A generated 24-hour dataset has reproducible windows, labels, splits, and feature vectors.
- The five dominant classes can be distinguished by at least two independent synthetic statistics.
- Rumination and feeding near-class confusion is explicitly reported.
- Sparse snapshots are never labeled as rumination or feeding.
- Synthetic training and real test datasets cannot be mixed unintentionally.
- One livestock and one episode cannot occupy multiple splits in the same dataset.
- Evaluation outputs dominant-class confusion matrix, per-facet metrics, boundary metrics, and source partitions.
- The design introduces no production model code or firmware change.

## 11. Open Questions

1. Will firmware enable high-resolution LIS3DH mode, or will behavior remain 0x40 window summaries?
2. What exact 42-byte layout will TLV `0x40` use?
3. Which minimum real sample count per behavior class qualifies a real-only test set?
4. What reproductive/calving record source will provide authoritative event labels?
5. Should `behavior_windows` remain datagen-owned or move to Health when behavior becomes a product feature?

## 12. Explicit Non-Goals

- No claim of sleep detection; the system detects lying posture only.
- No raw high-rate accelerometer ingestion over LoRaWAN.
- No use of capsule motility alone as a behavior label.
- No claim that synthetic AUC/F1 predicts real-world accuracy.
- No LLM agent or multi-agent orchestration in this stage.
