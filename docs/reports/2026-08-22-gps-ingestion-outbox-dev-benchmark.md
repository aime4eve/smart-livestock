# GPS Ingestion Outbox Dev Benchmark

**Date**: 2026-08-22
**Environment**: dev (`172.22.1.123:19080`, app build `0.3.2-b489`)
**Issue**: NIX-145

## Method

1. Inserted 100 outbox tasks for device 1 with `source=MANUAL_IMPORT`, timestamps from `2030-01-01 00:00:00` to `00:01:39`, and `next_attempt_at = now + 1 hour`.
2. Released all 100 tasks atomically by setting `next_attempt_at = now`.
3. Polled the marked task window until the outbox count reached zero.
4. Verified the corresponding `gps_logs` count and scheduler logs.
5. Re-enqueued the first `(device_id, recorded_at)` with changed coordinates to verify idempotency.

`MANUAL_IMPORT` was selected so the downstream fence consumer would explicitly skip test events. All rows in the 2030 test window were removed after verification.

## Results

| Metric | Result |
|---|---:|
| Tasks released | 100 |
| Outbox clear elapsed | 1517 ms |
| Observed throughput | 65.9 tasks/s |
| GPS rows written | 100 |
| Failed tasks | 0 |
| Duplicate re-enqueue result | 1 GPS row, coordinates updated, task removed |

All tasks were released together and the marked window cleared in 1517 ms, so every task completed within 1517 ms. Per-task latency was not individually instrumented; 1517 ms is therefore a conservative upper bound for P95 in this run.

The scheduler log recorded `GPS ingestion batch complete: succeeded=100`.

## Failure Check

A fault-injection task with an invalid source exposed a boundary bug: it could not be loaded as `TelemetrySource`, so the worker repeatedly logged the failure but could not persist retry state. The fix adds `V20260822210000__gps_ingestion_source_check.sql`, restricting outbox sources to the four legal enum values. Unit tests also cover normal GPS write failure propagation, delayed retry, and terminal failure after the configured attempt limit.

## Residual Scope

This benchmark validates a 100-task burst on one dev app container. It does not model multi-instance contention or a prolonged production-scale soak. If horizontal replicas are introduced, add a distributed claim/lease mechanism before scaling the scheduler beyond one instance.
