# datagen v2 C4-C5 dev 验证记录

> Date: 2026-08-23  
> Issue: NIX-150  
> Build: `0.3.2-b505`  
> Environment: dev (`http://172.22.1.123:19080`)

## Scope

C4/C5 synthetic prediction pipeline only. No firmware `0x40` decoder was added, no real-world accuracy claim was made, and the C6/C7 synthetic-to-real transition remains mandatory.

## Dataset

Generated deterministic dataset `0d94c249-a645-3f93-9a65-599562145f60`:

- scenario: `nix150-dev-training-v3`
- seed: `152`
- generator: `behavior-generator-v1`
- source: `DATAGEN`
- subjects: 20
- episodes: 2856
- windows: 5760
- labels: 22772
- quality: 5693 `FULL_0X40`, 67 `UNKNOWN`
- splits: 4032 `TRAIN`, 864 `VALIDATION`, 864 `TEST`

## Training

- Model: `behavior-l2:v1`
- Artifact hash: `2d2c9a47c93fd6b410aac21522ecfd63e3083c12548e9a4a3d129cf85e09d034`
- Feature schema hash: `ed681cb289c0d9c7eb90d7e7a69e52663618af2f3004b71b4aa17db4ba95bfbc`
- Train windows: 3987 model-compatible windows
- Validation windows: 853 model-compatible windows
- Minimum support: 20
- Random seed: 150
- Manifest: `PIPELINE_ONLY`, `synthetic_pretraining=true`

The synthetic validation metrics were `dominant_accuracy=1.0` and `dominant_weighted_f1=1.0`. They demonstrate pipeline mechanics only and must not be interpreted as real-world behavior recognition accuracy.

## Prediction

- L1 `behavior-rules:v1`: 5693 predictions
  - dominant values only `LYING`, `WALKING`, `OTHER`
  - `ORAL_ACTIVITY` labels: 0
- L2 `behavior-l2:v1`: 5693 predictions
  - all model-compatible windows covered
  - capability: `L2_SUPERVISED`
- Duplicate prediction keys: 0
- Repeated analysis updates the existing `(window_id, model_name, model_version)` row rather than duplicating it.

## Evaluation

Final report state:

- `state=COMPLETE`
- `reportType=PIPELINE_ONLY`
- `missingPredictionWindows=0`
- source partition: `DATAGEN=5760`
- quality partition: `FULL_0X40=5693`, `UNKNOWN=67`
- split partition: `TRAIN=4032`, `VALIDATION=864`, `TEST=864`
- dominant metrics present with confusion matrix, macro/weighted F1, class supports, and top-2 accuracy
- all four facet metric groups present
- boundary transition F1: 1.0
- event matching uses one-to-one event pairing; final precision/recall/F1 are valid ratios no greater than 1.0

## No IoT Pollution

Counts were unchanged after dataset generation, training, L1 analysis, L2 analysis, and evaluation:

- `device_telemetry_logs=15395`
- `gps_logs=3600`
- `temperature_logs=118475`
- `activity_logs=457920`

## Verification

1. ai-platform full suite: 81 tests passed.
2. Java full suite: 605 tests completed, 19 failed, 1 skipped; failures remained the documented legacy baseline.
3. dev app and ai-platform started successfully.
4. No model/schema/prediction ERROR appeared in final app or ai-platform logs.

## Issues Found During Verification

The integration verification found and fixed six issues before the final passing run:

1. Absolute livestock-hash split bucketing left the first 20-subject dataset without `VALIDATION`; replaced with proportional blocked subject assignment.
2. An absolute modulo-100 boundary still left 20 subjects entirely in `TRAIN`; replaced with subject-count proportional boundaries.
3. The deployment script did not rebuild `ai-platform`, leaving the service on an old image; `ai-platform` is now included in the build targets.
4. A 5693-window request exceeded the AI request limit; Java now batches requests by 5000 windows.
5. Per-window RandomForest calls exceeded the gateway timeout; Python now vectorizes prediction per request batch.
6. Evaluation counted incompatible `UNKNOWN` windows as missing predictions and allowed boundary/event matches to reuse one prediction; both metrics now use one-to-one matching and only model-compatible windows for prediction completeness.

## Result

Passed for synthetic C4/C5 pipeline acceptance. The trained artifact and predictions remain in dev under explicit dataset/model identifiers and `DATAGEN` provenance; no cleanup is required.
