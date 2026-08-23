# datagen v2 Phase C C4-C5 实施计划

> Date: 2026-08-23\
> Status: 已实施并完成 dev 验证（2026-08-23）\
> Issue: NIX-150\
> Spec: `2026-08-22-datagen-v2-behavior-and-phase-c-design.md`\
> Prior plan: `2026-08-23-datagen-v2-phase-c-c0-c3-plan.md`\
> Scope: C4-C5 synthetic pipeline only; C6/C7 real-data transition remains mandatory

## Goal

Turn the C0-C3 feature store into a working prediction pipeline:

1. Add an L1 behavior rule predictor for coarse posture and locomotion.
2. Add deterministic supervised L2 pretraining over synthetic `PROTOCOL_SUMMARY` windows.
3. Add Java orchestration to train, run, and persist behavior predictions.
4. Reuse C3 evaluation and produce explicit `PIPELINE_ONLY` synthetic reports.

This batch still makes no real-world accuracy claim. A qualified real telemetry adapter, real labels, fine-tuning or retraining, and real-only evaluation remain mandatory before production claims.

## Non-Goals

- No firmware `0x40` decoder.
- No real-world behavior model claim.
- No raw high-rate waveform ingestion.
- No sparse-to-oral shortcut: `COARSE_SNAPSHOT` never emits rumination or feeding.
- No Flutter UI and no automatic production scheduling.
- No synthetic/real mixed training or evaluation outside explicit debug mode.

## Architecture

```text
behavior_windows (synthetic PROTOCOL_SUMMARY)
        |
        v
Java BehaviorAnalysisOrchestrator
        |
        +--> ai-platform /ai/behavior/analyze
        |       |- L1 behavior rules (always available)
        |       '- L2 behavior model (available only when compatible artifact exists)
        |
        v
behavior_predictions
        |
        v
C3 BehaviorEvaluationService
```

Java remains the authorization, dataset scoping, persistence, and audit boundary. ai-platform remains stateless for prediction and owns only model execution/training. Model artifacts are versioned files with a JSON manifest; no model artifact is trusted without the registered feature schema hash.

## Task 1 - C4 L1 Coarse Rule Predictor

**Files**

- Extend `ai-platform/app/schemas.py`
- Create `ai-platform/app/behavior/rules.py`
- Create `ai-platform/app/capability/behavior_l1.py`
- Extend `ai-platform/app/main.py`, `engine.py`, and `capability/router.py` only as needed for a separate behavior endpoint
- Add focused tests under `ai-platform/tests/behavior/`

**Steps**

1. Define behavior request/response schemas:
   - feature version and schema hash per window
   - input quality, sampling mode, and feature map
   - dominant class, probability vector, posture/locomotion labels, capability, model name/version
2. Validate every request against the C0 semantic fields before prediction.
3. Implement coarse rules:
   - `LYING` posture when roll indicates a lying orientation and movement/speed is low.
   - `STANDING` otherwise; `TRANSITION` only when posture transition count is explicit.
   - `WALKING` locomotion when speed/steps exceed conservative thresholds.
   - `HIGH_ACTIVITY` only with an explicit intense-sample count.
   - Dominant class is limited to `LYING`, `WALKING`, and `OTHER`; L1 never emits `RUMINATING` or `FEEDING`.
4. Use a fixed model name `behavior-rules` and version `v1`; probability values are rule confidences, not calibrated clinical probabilities.
5. Return explicit per-window errors instead of partially imputing incompatible feature maps.

**Acceptance**

- Compatible full and partial summaries return posture and locomotion.
- `COARSE_SNAPSHOT` returns no oral activity label.
- Unknown schema/version, missing required fields, and out-of-range values are rejected.
- L1 cannot output rumination or feeding.
- No DB call is required for stateless prediction.

## Task 2 - C5 L2 Synthetic Pretraining

**Files**

- Create `ai-platform/app/behavior/dataset.py`
- Create `ai-platform/app/behavior/model.py`
- Create `ai-platform/scripts/train_behavior.py`
- Add model artifact tests under `ai-platform/tests/behavior/`

**Steps**

1. Read one synthetic dataset by dataset id from `behavior_windows` and `behavior_window_labels`.
2. Join predictions only for evaluation, never for training labels.
3. Require:
   - `data_source=DATAGEN`
   - feature version/hash `v1`
   - `model_compatible=true`
   - dataset splits are structurally leakage-free
   - every selected split/class/facet label has a configured minimum support
4. Build fixed numeric feature order from the C0 contract; missing fields use NaN plus the missing mask.
5. Train deterministic sklearn models:
   - one dominant-class classifier
   - one binary classifier per required facet value with sufficient support
   - fixed random seed and model version
6. Use blocked `TRAIN` / `VALIDATION` splits from C2; never randomly split windows.
7. Emit a model manifest containing:
   - dataset id and definition digest
   - feature schema hash
   - generator version
   - train/validation counts and class supports
   - model class, seed, and hyperparameters
   - validation metrics and `PIPELINE_ONLY`
8. Save artifact plus manifest under a configured model directory. Refuse to replace an existing model name/version.
9. Do not train if the dataset mixes sources or contains real data; C6/C7 requires a separate explicit batch.

**Acceptance**

- Re-training the same dataset and configuration produces the same artifact hash when library versions are fixed.
- Missing model artifact makes L2 unavailable and leaves L1 usable.
- Schema mismatch makes L2 unavailable.
- A split/class/facet with insufficient support fails training with an actionable error rather than silently dropping metrics.
- Training output is labeled synthetic and `PIPELINE_ONLY`.

## Task 3 - ai-platform Behavior Endpoint

**Files**

- Extend `ai-platform/app/main.py`
- Extend behavior schemas and tests

**Steps**

1. Add `POST /ai/behavior/analyze`.
2. Request carries tenant/farm scope and feature windows; Java has already authorized the dataset and user.
3. Prefer the requested compatible L2 model when its manifest matches feature version/hash.
4. Fall back to L1 rules when:
   - no model is requested,
   - artifact is absent,
   - artifact fails manifest validation,
   - or request explicitly selects `L1_RULE`.
5. Return one result per input window; partial successes and per-window failures are explicit.
6. Keep the endpoint internal-network only; authorization remains in Java.

**Acceptance**

- L2 path persists no state itself.
- L1 fallback is explicit in `capability_used`.
- No request silently changes the feature map or label semantics.
- Endpoint tests cover L2 success, L2 fallback, and per-window schema mismatch.

## Task 4 - Java Orchestration and Persistence

**Files**

- Create `datagen/application/behavior/BehaviorAnalysisService.java`
- Create `datagen/infrastructure/client/BehaviorPlatformClient.java`
- Extend `DataGenBehaviorController`
- Extend repositories and i18n resources
- Add controller/service tests

**API**

```text
POST /api/v1/admin/datagen/behavior/models/train
POST /api/v1/admin/datagen/behavior/datasets/{datasetId}/analyze
```

**Steps**

1. Reuse platform/B2B admin authorization and farm access checks.
2. Train API accepts dataset id, target capability, model name/version, and minimum support policy.
3. Analyze API:
   - loads one dataset
   - rejects mixed-source datasets unless explicit debug mode is set
   - validates every feature window before calling ai-platform
   - persists returned predictions by `(window_id, model_name, model_version)`
   - re-running the same model/version updates rather than duplicating
4. Store `L1_RULE` or `L2_SUPERVISED` exactly as returned by ai-platform.
5. Add i18n errors for unavailable platform, incompatible model, invalid artifact, empty dataset, and prediction mismatch.
6. Do not write behavior predictions into Health/IoT tables.

**Acceptance**

- Analyzer can produce both L1 and L2 predictions on dev.
- Repeated analysis is idempotent by model version.
- Prediction count never exceeds selected window count.
- Authorization and farm scope are enforced before ai-platform is called.
- A platform failure leaves existing predictions untouched.

## Task 5 - Evaluation and Dev Verification

**Backend/AI tests**

```bash
cd smart-livestock-server
./gradlew compileJava
./gradlew test --tests 'com.smartlivestock.datagen.*'
cd ai-platform
pytest
```

**Dev integration**

1. Deploy dev.
2. Train an L2 model on the NIX-149 smoke dataset or a larger deterministic dataset.
3. Run L1 analysis on the same dataset and verify:
   - predictions contain only coarse dominant classes
   - no oral labels
   - `capability_level=L1_RULE`
4. Run L2 analysis and verify:
   - schema/model versions are stored
   - `capability_level=L2_SUPERVISED`
   - all compatible windows have predictions
5. Run C3 evaluation and verify:
   - `COMPLETE`
   - `PIPELINE_ONLY`
   - dominant confusion, F1, facet metrics, boundary metrics, source partitions
   - explicit missing prediction count is zero
6. Compare IoT table row counts before/after training and analysis.
7. Archive the model manifest hash and evaluation summary in the verification report.

**Acceptance**

- L1 coarse report is complete but never claims oral behavior.
- L2 synthetic report is complete and marked `PIPELINE_ONLY`.
- Full backend suite does not enlarge the documented 19-failure legacy baseline.
- AI service tests and Java targeted tests pass.
- Dev logs contain no model/schema/persistence errors.

## Real-Data Transition Gate

C4/C5 must keep these C6/C7 hooks:

1. Feature contract hash gates all prediction.
2. No code branches on `data_source == DATAGEN`; source is used only by dataset construction/training governance.
3. L2 artifact manifest identifies the synthetic training dataset.
4. A future real adapter can supply the same feature map without changing inference code.
5. Future real fine-tuning/retraining must create a new model version and real-only report; it cannot silently reuse the synthetic artifact version.

## Rollout Order

1. Behavior schemas and L1 rules.
2. L1 endpoint tests.
3. Deterministic training/model manifest.
4. Behavior analyze endpoint.
5. Java client, orchestration, persistence, and API docs.
6. Targeted tests and dev integration.
7. Review evaluation report, commit, push, and update Linear.

## Implementation Result

- C4 L1 coarse rule prediction and C5 deterministic supervised pretraining were implemented on 2026-08-23.
- Java orchestration validates farm/tenant/livestock/device scope, batches AI requests, and upserts predictions by model version.
- ai-platform full tests and Java full tests passed within the documented legacy failure baseline.
- dev build `0.3.2-b505` completed L1/L2 prediction and C3 evaluation successfully.
- Verification record: `docs/reports/2026-08-23-datagen-v2-c4-c5-dev-verification.md`.
