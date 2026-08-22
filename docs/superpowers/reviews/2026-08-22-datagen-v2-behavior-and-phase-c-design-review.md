# Review: datagen v2 与 AI Phase C 设计

> Date: 2026-08-22  
> Spec: `2026-08-22-datagen-v2-behavior-and-phase-c-design.md`  
> Reviewer: Codex  
> Result: **评审通过；5 项实施前要求已回写 spec**

## 1. Conclusion

The design correctly separates three concerns that were previously at risk of being collapsed:

1. High-rate research waveform synthesis.
2. Protocol-compatible five-minute behavior summaries.
3. Coarse behavior inference from current sparse telemetry.

This avoids overclaiming rumination or feeding recognition from current 5-15 minute snapshots.

## 2. Findings

### P1-1 Dominant-class single label is insufficient, but design mitigates it

The proposed dominant class plus multi-label facets is appropriate. Before implementation, the evaluation contract must treat dominant-class confusion as diagnostic rather than the sole optimization objective.

**Required action**: C3 tests must fail if only exact-match accuracy is emitted without macro F1 and facet metrics.

### P1-2 Real-data source separation is mandatory

The design says synthetic and real test sets cannot mix. This must be enforced structurally, not merely by convention.

**Required action**: evaluation query/API should reject a request whose test range contains multiple `data_source` values unless `allow_mixed_debug=true` is explicitly set and the report is marked debug-only.

### P1-3 Sparse snapshot mode must not infer oral activity

Current data can support broad posture/locomotion only. The adapter contract is correct, but a router test is essential.

**Required action**: add tests proving `COARSE_SNAPSHOT` cannot emit `RUMINATING` or `FEEDING`.

### P2-1 Feature-version compatibility

Adding or reordering fields in JSONB could silently degrade a model.

**Required action**: persist `feature_version`, validate required fields and ranges on write, and reject incompatible versions at inference.

### P2-2 Dataset leakage risk

Random window splitting would leak individual and daily patterns.

**Required action**: enforce livestock-level and episode-level split assignment in the repository/service, not only in the generation script.

## 3. Clarifications

- `LYING` should not be translated or marketed as sleep.
- `capsule_motility` is a cross-check feature, never an independent behavior label.
- Calving examples are event-pipeline tests until confirmed real calving labels exist.
- Synthetic reports must be labeled `PIPELINE_ONLY`.

## 4. Recommendation

The five required actions are incorporated as C0-C3 acceptance criteria in the spec. Proceed to an implementation plan; do not start firmware changes or L2 model implementation before that plan is reviewed.
