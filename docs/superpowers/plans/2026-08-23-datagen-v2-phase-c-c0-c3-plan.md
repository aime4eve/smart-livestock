# datagen v2 Phase C C0-C3 实施计划

> Date: 2026-08-23  
> Status: 待评审  
> Issue: NIX-149  
> Spec: `docs/superpowers/specs/2026-08-22-datagen-v2-behavior-and-phase-c-design.md`  
> Review: `docs/superpowers/reviews/2026-08-22-datagen-v2-behavior-and-phase-c-design-review.md`  
> Scope: C0-C3 only; no firmware change, no production L2 model training

## Goal

Build the synthetic behavior-data pipeline while firmware behavior summaries remain incomplete:

1. Freeze the five-minute feature and label contract.
2. Generate deterministic offline 25Hz behavior episodes.
3. Persist five-minute protocol summaries, labels, and split metadata with leakage protection.
4. Produce multi-label evaluation reports marked `PIPELINE_ONLY`.

Synthetic data is a transitional bootstrap. Once qualified real telemetry is available, C6/C7 must use the same feature contract and schema hash, build a separate labeled real dataset, fine-tune or retrain, and report real-only metrics. Synthetic-only results cannot close a production behavior-model claim.

## Non-Goals

- No raw high-rate waveform ingestion into IoT telemetry tables.
- No `TelemetryIngestionService` call from the offline behavior generator.
- No firmware `0x40` implementation or byte-layout decision.
- No L2 supervised model training in this batch.
- No rumination, feeding, sleep, estrus, or calving accuracy claims from synthetic results.
- No Flutter UI; this batch is backend and offline tooling only.

## Architecture

```text
BehaviorFeatureContract (C0)
        |
        v
BehaviorEpisodeGenerator + deterministic waveform synthesis (C1)
        |
        v
feature extraction -> PROTOCOL_SUMMARY (C1)
        |
        v
BehaviorWindowPersistence + split policy (C2)
        |
        v
BehaviorEvaluationService (C3)
```

Raw research waveforms remain offline artifacts. Production-path validation may later emit protocol summaries through the same decoder/persistence contract as real `0x40`, but it does not write sparse IoT telemetry in this batch.

## Task 1 - C0 Contract Freeze

**Files**

- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorFeature.java`
- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorFeatureContract.java`
- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorDominant.java`
- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorFacet.java`
- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorLabelValue.java`
- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/behavior/InputQuality.java`
- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/behavior/SamplingMode.java`
- Create `smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidator.java`
- Add matching unit tests under `src/test/java/com/smartlivestock/datagen/domain/`

**Steps**

1. Define feature version `v1` with the exact semantic fields from spec section 3.3.
2. Encode field order, primitive type, unit, required flag, minimum/maximum, and missing mask semantics in `BehaviorFeatureContract`.
3. Generate a deterministic SHA-256 `feature_schema_hash` from canonical contract JSON; never derive it from a serialized sample.
4. Implement write-time validation for required fields, finite numeric values, range checks, feature version, and schema hash.
5. Implement read-time compatibility rejection: a model or adapter with a different registered hash must reject the window instead of imputing fields.
6. Encode label domains:
   - Dominant: `LYING`, `RUMINATING`, `FEEDING`, `WALKING`, `OTHER`
   - `UNKNOWN` is an input-quality state, never a dominant label.
   - Facets: `posture`, `oral_activity`, `locomotion`, `event`
7. Add contract tests proving `COARSE_SNAPSHOT` cannot emit `RUMINATING` or `FEEDING`.

**Acceptance**

- Same contract definition and field order always yields the same hash.
- Field insertion, removal, reordering, type change, or range change yields a different hash.
- Missing required fields, non-finite values, out-of-range values, and version/hash mismatch are rejected.
- Coarse snapshots have no oral-activity label.

## Task 2 - C1 Deterministic Episode and Waveform Generator

**Files**

- Create behavior domain objects and generator services under:
  - `datagen/domain/model/behavior/`
  - `datagen/domain/service/`
  - `datagen/application/behavior/`
- Create a deterministic dataset export adapter under `datagen/infrastructure/export/`
- Add matching unit tests under `src/test/java/com/smartlivestock/datagen/`

**Steps**

1. Model behavior scenarios as data, not as one Java enum member per behavior:
   - farm/livestock/device scope
   - behavior mix and transition matrix
   - diurnal prior
   - seed and generator version
   - noise, missingness, and dropout profile
2. Generate a semi-Markov episode timeline on five-minute boundaries.
3. Synthesize each episode deterministically at 25Hz:
   - rumination chew: 1.0-1.5Hz quasi-periodic movement
   - feeding bite: irregular 1.5-3Hz bursts and pauses
   - lying: stable gravity orientation and low dynamic noise
   - walking: 1.5-2.5Hz cadence with GPS speed 0.4-1.5m/s
   - posture transition: 1-4s orientation change
   - calving-like restlessness: event overlay, not a dominant class
4. Parameterize individual baseline, device orientation, noise, sampling jitter, missing windows, and adversarial overlaps.
5. Extract the five-minute feature vector from the waveform through `BehaviorFeatureValidator`.
6. Make all generated artifacts reproducible from `(scenario_id, seed, generator_version)`.
7. Export deterministic five-minute summary datasets as versioned NDJSON/JSON for pipeline tests. Do not create a raw-waveform interchange format in this batch; the later research exporter must still use NumPy/Parquet with the same manifest and schema hash before C5 model work.
8. Keep the generator independent of JPA repositories and `TelemetryIngestionPort`.

**Acceptance**

- Re-running the same scenario, seed, generator version, and input definition produces byte-stable manifests and identical semantic samples.
- Changing seed, generator version, individual baseline, or orientation changes generated samples.
- A 24-hour episode contains plausible class imbalance and missing-window behavior.
- Rumination shows a spectral peak around 1.0-1.5Hz with lower entropy than feeding.
- Feeding has more burst/zero-crossing variability than rumination.
- Walking has cadence and speed distinct from lying.
- Every generated summary passes C0 validation.
- No raw research waveform is emitted as a C0-C3 interchange artifact.
- No generated research waveform enters IoT telemetry tables.

## Task 3 - C2 Persistence and Split Governance

**Files**

- Create `smart-livestock-server/src/main/resources/db/migration/V20260823100000__datagen_behavior_windows.sql`
- Create JPA entities, repositories, mappers, and application services under `datagen/`
- Add a minimal admin API under `datagen/interfaces/admin/`
- Add i18n error keys to both message properties files
- Add persistence/service/controller tests

**Database model**

1. `behavior_feature_contracts`
   - `feature_version` primary key
   - `schema_hash`
   - canonical `definition JSONB`
   - seeded with C0 `v1`
2. `behavior_datasets`
   - UUID id
   - scenario name/id, seed, generator version
   - `data_source`, status, time range
   - reproducibility manifest
3. `behavior_episodes`
   - UUID id, dataset id
   - livestock/device scope, start/end time
4. `behavior_windows`
   - scope and dataset/episode ids
   - five-minute boundary
   - denormalized dominant behavior
   - feature version/hash and JSONB features
   - `input_quality`, `data_source`, `dataset_split`, `sampling_mode`, `model_compatible`
   - unique `(device_id, window_start, feature_version)`
5. `behavior_window_labels`
   - one row per facet value
   - label source, confidence, labeler, timestamp, note
6. `behavior_predictions`
   - model name/version, predicted dominant and labels, probability vector, capability, predicted time

**Steps**

1. Add CHECK constraints for all enums, time ranges, confidence, and split values.
2. Add partial unique split constraints:
   - `(dataset_id, livestock_id, dataset_split)`
   - `(dataset_id, episode_id, dataset_split)`
3. Enforce the same rules in the application layer before database insertion, with actionable i18n errors.
4. Persist only protocol summaries; raw waveforms stay offline.
5. Assign splits by farm/livestock/contiguous episode blocks, never randomly by window.
6. Keep synthetic and real rows in separate datasets and reject a non-debug evaluation request whose selected test rows contain multiple sources.
7. Add minimal authenticated admin endpoints:
   - generate behavior dataset
   - inspect dataset manifest and counts
8. Reuse existing datagen admin role and tenant/farm access checks.
9. Do not add a scheduler in this batch.

**Acceptance**

- Flyway migration succeeds on a clean database.
- The same `(device, window_start, feature_version)` cannot be inserted twice.
- One livestock cannot occupy multiple splits in one dataset.
- One episode cannot be split across multiple dataset splits.
- Synthetic and real sources cannot silently share a non-debug dataset.
- `DATAGEN` is persisted as the explicit source.
- No generated window calls `TelemetryIngestionService`.
- Admin API returns authorization, validation, and generation errors through MessageSource.

## Task 4 - C3 Multi-Label Evaluation

**Files**

- Create `datagen/application/behavior/BehaviorEvaluationService.java`
- Create report DTOs under `datagen/application/behavior/dto/`
- Extend the minimal admin evaluation endpoint
- Add unit tests for metrics and rejection rules

**Steps**

1. Join predictions to labels by `window_id`; never treat predictions as ground truth.
2. Compute dominant-class:
   - confusion matrix over the five dominant classes
   - accuracy only as a diagnostic
   - macro F1 and weighted F1 as required metrics
3. Compute per-facet precision, recall, F1, Hamming loss, and support for:
   - posture
   - oral activity
   - locomotion
   - event
4. Report boundary tolerance at configurable 0, 30, 60, and 300 second tolerances.
5. Report source partitions and dataset/model/generator versions.
6. Mark every synthetic report `PIPELINE_ONLY`; do not emit a production-accuracy interpretation.
7. Reject a non-debug evaluation when selected test windows contain multiple `data_source` values.
8. Allow mixed-source evaluation only with explicit `allow_mixed_debug=true`; title and JSON metadata must then carry `debug=true` and list all sources.
9. Return empty/error metrics by explicit state rather than silently imputing labels.

**Acceptance**

- A report with only accuracy and no macro/weighted F1 or facet metrics fails the service test.
- Near-class confusion for `RUMINATING` vs `FEEDING` is explicitly visible.
- Missing predictions or labels never count as silent positives or negatives.
- Mixed-source reports cannot be produced accidentally.
- All synthetic report payloads carry `PIPELINE_ONLY`.

## Task 5 - Verification and Delivery

**Backend**

```bash
cd smart-livestock-server
./gradlew compileJava
./gradlew test --tests 'com.smartlivestock.datagen.*'
```

Compare full-suite failures against the documented 19-failure legacy baseline if a full test run is needed.

**Dev integration**

1. Deploy dev with `./scripts/deploy.sh dev`.
2. Verify Flyway records the behavior migration successfully.
3. Authenticate as a platform admin.
4. Generate a small deterministic 24-hour dataset.
5. Verify:
   - feature contract `v1` seed exists
   - dataset/episode/window counts are internally consistent
   - labels contain expected facets
   - every window has the registered schema hash
   - split constraints reject leakage probes
   - IoT telemetry row counts do not increase from research waveform generation
6. Run evaluation and verify the report contains confusion, F1, facet, boundary, source, and `PIPELINE_ONLY` metadata.
7. Keep the generated dataset marked `DATAGEN`; if cleanup is required, remove by dataset id rather than deleting by broad time range.
8. Update deployment/API reference docs with the new internal admin contract.

## Real-Data Transition Gate

This batch must preserve the following hooks for C6/C7:

1. Feature contract and schema hash are persisted, versioned, and seedable.
2. Summary persistence accepts a qualified future real adapter without model branching on `data_source`.
3. Dataset identity keeps synthetic and real data separated.
4. Evaluation separates synthetic pretraining, real fine-tuning, and real-only test reports.
5. The synthetic baseline can be frozen with dataset/model versions for later comparison.

When real telemetry is available, a separate implementation batch must:

1. Decode qualified real telemetry into the same C0 contract.
2. Build a labeled real dataset.
3. Fine-tune or retrain the model.
4. Run real-only evaluation.
5. Reproduce all reports with explicit source partitions.

## Rollout Order

1. Task 1 contract and tests.
2. Task 2 deterministic generator and offline export.
3. Task 3 persistence and split governance.
4. Task 4 evaluation.
5. Targeted tests and dev integration.
6. Docs, commit, push, and Linear status update.

Each task should land as a separately reviewable commit, but all C0-C3 work may be delivered in one PR if review capacity is constrained.
