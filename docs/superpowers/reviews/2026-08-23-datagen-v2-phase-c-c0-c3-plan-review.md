# Review: datagen v2 Phase C C0-C3 实施计划

> Date: 2026-08-23\
> Plan: `2026-08-23-datagen-v2-phase-c-c0-c3-plan.md`\
> Result: **退回修订；P0/P1 已回写计划后可进入实施**

## Findings

### P0 Split constraints block normal inserts

The original constraints `UNIQUE (dataset_id, livestock_id, dataset_split)` and `UNIQUE (dataset_id, episode_id, dataset_split)` allow only one window per livestock or episode per split. Since a 24-hour livestock series contains many windows, the second insert would violate the constraint.

Required fix: use separate livestock and episode assignment tables. Keep one row per `(dataset_id, livestock_id)` and one row per `(dataset_id, episode_id)`, then validate episode/livestock compatibility transactionally.

### P1-1 Global window uniqueness blocks the future real adapter

`UNIQUE (device_id, window_start, feature_version)` prevents the same device/window/feature version from existing in separate synthetic and real datasets. That directly conflicts with the C6/C7 transition policy.

Required fix: uniqueness is dataset-scoped: `(dataset_id, device_id, window_start, feature_version)`. Dataset generation must also be idempotent for the same canonical scenario definition.

### P1-2 Data source is duplicated inconsistently

Putting `data_source` independently on `behavior_windows` and datasets allows a window source to disagree with its dataset. Required fix: source is owned by the dataset; a window may only carry it as a denormalized value enforced by a composite foreign key or derive it at query time.

### P1-3 Coarse oral-activity semantics were ambiguous

"No oral-activity label" must not become `oral_activity=NONE`; absence of high-rate evidence is unavailable, not a confirmed absence of chewing. Required fix: coarse windows omit the oral facet and set the missing-feature mask.

### P1-4 Boundary tolerances contradicted the five-minute contract

The plan requested 30 and 60 second tolerances, but the persisted labels are five-minute windows and predictions have no event timestamp. Required fix: C0-C3 reports one-window boundary tolerance and event merging/latency at event-window granularity. Sub-window timing requires a separate event-occurrence contract.

### P1-5 C3 had no legitimate prediction producer

C0-C3 excludes model training and C4/C5 models, so a populated dev evaluation report cannot be assumed. Required fix: metrics are tested with explicit fixture predictions; the dev endpoint returns an explicit `NO_PREDICTIONS` state until a later model stage persists predictions. No endpoint may fabricate model results or use labels as predictions.

### P1-6 Duplicate facet labels could inflate evaluation

The original persistence model had no key on `(window_id, facet, label_value)`. Replaying an insert could count one ground-truth facet value multiple times and inflate support.

Required fix: add `(window_id, facet, label_value)` uniqueness and reject duplicate label rows in the application layer.

### P2 Determinism and resource bounds needed tighter wording

Byte stability across JVM implementations is fragile for floating-point JSON. Required fix: use a canonical JSON serialization, fixed numeric formatting, and semantic digest; process episodes in bounded chunks rather than retaining a full 24-hour 25Hz waveform in memory. Generation requests need explicit duration/device/window limits.

## Required Plan Updates

1. Replace the split constraints with split-assignment tables and transactional compatibility checks.
2. Make dataset identity deterministic and window uniqueness dataset-scoped.
3. Make dataset source authoritative.
4. Preserve coarse oral activity as unavailable via missing mask.
5. Align boundary metrics with five-minute windows.
6. Define fixture-only prediction tests and explicit `NO_PREDICTIONS` dev behavior.
7. Add canonical serialization and bounded generation requirements.
8. Add deterministic dataset-definition identity and unique facet-label keys.

All required updates have been incorporated into revision 1.1 of the implementation plan.
