# datagen v2 C0-C3 dev 验证记录

> Date: 2026-08-23  
> Issue: NIX-149  
> Build: `0.3.2-b493`  
> Environment: dev (`http://172.22.1.123:19080`)

## Verification

1. `./gradlew compileJava` passed.
2. `./gradlew test --tests 'com.smartlivestock.datagen.*'` passed.
3. Flyway migration `V20260823100000__datagen_behavior_windows.sql` succeeded.
4. `behavior_feature_contracts` contained exactly one `v1` contract seed with schema hash `ed681cb289c0d9c7eb90d7e7a69e52663618af2f3004b71b4aa17db4ba95bfbc`.
5. Authenticated `POST /api/v1/admin/datagen/behavior/datasets` generated dataset `765e8c53-4130-38a7-b011-9af9dfe7671c`:
   - `dataSource=DATAGEN`
   - 3 episodes
   - 12 windows
   - 48 labels
   - 12 `FULL_0X40` windows
   - all windows assigned to `TRAIN` for this single-livestock smoke dataset
6. Re-submitting the same canonical definition returned the same dataset id with `alreadyExists=true`.
7. `POST /api/v1/admin/datagen/behavior/evaluations` with `datasetSplit=ALL` returned:
   - `state=NO_PREDICTIONS`
   - `reportType=PIPELINE_ONLY`
   - source/quality/split/livestock partitions
   - empty metric populations without fabricated predictions
8. Database integrity checks:
   - bad feature hash count: 0
   - duplicate window key count: 0
   - livestock split leakage count: 0
   - episode split leakage count: 0
   - duplicate facet label count: 0
   - required window/split/label indexes found: 4
9. IoT no-pollution counts were unchanged before and after behavior generation:
   - `device_telemetry_logs=15395`
   - `gps_logs=3600`
   - `temperature_logs=118475`
   - `activity_logs=457920`
10. App logs after final deployment contained no ERROR or repository query exception.

## Incident During Verification

Initial build `0.3.2-b492` failed application startup because Spring Data could not derive `findByDatasetId` for the embedded-id split assignment repositories. The query methods were corrected to `findByIdDatasetId`, targeted tests were rerun, and build `0.3.2-b493` started successfully.

## Result

Passed. The smoke behavior dataset remains in dev under its explicit dataset id and `DATAGEN` source; no cleanup is required.
