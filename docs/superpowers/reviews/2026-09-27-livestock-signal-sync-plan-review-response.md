# Livestock Signal Sync Plan Review Response

| Field | Value |
|---|---|
| Review | `docs/superpowers/reviews/2026-09-26-livestock-signal-sync-plan-review.md` |
| Response date | 2026-09-27 |
| Decision | **Accepted** |
| Superseded plan | Conversation-only plan dated 2026-09-26 |
| Replacement plan | [`2026-09-27-livestock-signal-sync-plan-v2.md`](../plans/2026-09-27-livestock-signal-sync-plan-v2.md) |
| Implementation status | **Not started; coding remains blocked pending user approval** |

## Decision Summary

The review is accepted. The three P0 findings are real blockers. The replacement plan fixes the GPS backfill ownership path, assigns unused migration versions, replaces the ambiguous “same transaction as GPS” promise with an explicit RocketMQ-consumer projection boundary, defines revision ownership and write paths, and changes the latency promise to measurable SLOs.

The review was written before rumen temperature and rumen motility were added to the requirements. Plan v2 adds both as authoritative health metrics in the Signal API, livestock cards, and the map inspector.

## Finding Dispositions

| ID | Decision | Resolution in Plan v2 |
|---|---|---|
| F1 | Accepted | `gps_logs` is backfilled through active installations. The SQL joins `gps_logs -> devices -> installations(active) -> livestock`, constrains fixes to the current installation window, excludes invalid coordinates and `MANUAL_IMPORT`, and uses a fresh database migration test as a gate. |
| F2 | Accepted | Migration IDs move to unused `V20260927090000` and `V20260927091000`. |
| F3 | Accepted with clarification | The GPS row write and the Signal projection are intentionally not one transaction. `GpsLogEventConsumer` projects location in its own transaction after resolving active installation and livestock, but before the no-fence early return. Phase 2 adds an Outbox event in that projection transaction. |
| F4 | Accepted | `livestock_location_snapshots` is the Signal API’s authoritative current-position source. `livestock.last_*` remains a legacy projection during Phase 1 and is not dropped until old map paths are retired. |
| F5 | Accepted | Plan v2 contains a write-path inventory and requires one revision assertion per source transaction. |
| F6 | Accepted | Farm revision rows are initialized during farm creation, lazily repaired on read/write, and incremented with atomic `UPDATE ... RETURNING`. The map payload and write frequency are capped. |
| F7 | Accepted | Phase 1 polls every 3 seconds and promises measurable P95/P99 targets, not an unconditional hard maximum. Phase 3 SSE remains the mechanism intended to meet the 5-second product target. |
| F8 | Accepted | Cursor format, validation, ahead/behind handling, resync threshold, deleted livestock behavior, and request limits are defined. |
| F9 | Accepted | Location snapshot source values exactly reuse `AGENTIC_PLATFORM`, `THINGSBOARD`, `DATAGEN`, `HTTP`, and `MANUAL_IMPORT`. API responses do not introduce `DEVICE` or use `UNKNOWN` as a stored value. |
| F10 | Accepted | Ranch map markers/status switch to Signal Store; the old 30-second Timer, frontend containment fallback, and `MapApiRepository.loadOverview()` path are removed in Phase 1b. `/ranch-overview` remains only for sheet lists during the transition. |
| F11 | Accepted | Signal aggregation is placed in a ranch-side signal module with explicit ports. Map snapshot support is capped at 1,000 livestock in v1 and larger farms return an explicit unsupported error rather than silently degrading. |
| F12 | Accepted | Phase 3 starts with a Flutter Web SSE spike using `package:web`, not `dart:html`. It must prove ticket auth, events, heartbeat, reconnect, and release-build behavior before SSE implementation. |
| F13 | Accepted | Farm authorization, timezone discipline, soft-deleted livestock behavior, and malformed request behavior are specified. |
| F14 | Accepted | Phase 1 is split into backend foundation (1a) and frontend integration (1b). |
| F15 | Accepted | The old ranch Timer and stale 30-second help copy are removed after Signal Store becomes authoritative. |

## Additional Requirement

Plan v2 also incorporates the later user requirement to include rumen temperature and rumen motility frequency. The Signal API returns them as current health metrics with values, stable units, source, assessment status, server-side freshness, and revision-driven updates. Livestock cards and the map inspector render both metrics from the same Signal Store.

## Exit Criteria Before Coding

1. User approves Plan v2.
2. Implementation branches are created only in dedicated worktrees.
3. Phase 1a begins with migrations, projection services, Signal APIs, and integration tests.
4. No Flutter UI work begins until the Phase 1a API contract tests pass on a clean database.
