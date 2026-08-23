# Review: datagen v2 Phase C C4-C5 实施计划

> Date: 2026-08-23\
> Plan: `2026-08-23-datagen-v2-phase-c-c4-c5-plan.md`\
> Result: **自评审通过，待用户最终确认**

## Findings and Resolutions

### P1-1 L1 must not infer oral activity

The initial scope risk was collapsing C4 coarse inference into fine behavior classification. Required resolution: L1 emits only `LYING`, `WALKING`, and `OTHER` for dominant class and never emits `RUMINATING` or `FEEDING`.

Resolution: incorporated in Task 1.

### P1-2 Training must not use prediction rows as labels

The plan explicitly distinguishes `behavior_window_labels` as ground truth from `behavior_predictions`; training reads labels only and evaluation joins predictions later.

Resolution: incorporated in Task 2.

### P1-3 Model compatibility must be structural

An artifact filename or requested version is not enough. Required resolution: model manifest must bind dataset definition, feature schema hash, generator version, model version, and validation metadata; Java/Python reject mismatch.

Resolution: incorporated in Tasks 2-4.

### P1-4 Repeated analysis must be idempotent

The database already enforces `(window_id, model_name, model_version)`. Java must therefore update existing rows rather than rely on duplicate exceptions.

Resolution: incorporated in Task 4.

### P2 Sparse and full inputs need separate routes later

C4 is intentionally coarse for both full and sparse inputs. Fine oral labels are reserved for C5 L2 with full protocol features; sparse input remains ineligible.

Resolution: incorporated in Tasks 1-2 and Non-Goals.

## Remaining Decision

Confirm the C4/C5 scope above. Implementation should not begin until this plan is accepted.
