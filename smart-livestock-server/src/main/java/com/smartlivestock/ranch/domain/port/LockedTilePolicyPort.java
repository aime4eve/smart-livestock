package com.smartlivestock.ranch.domain.port;

/**
 * ACL port for the Ranch overview (NIX-389) to read the platform-wide
 * locked-tile presentation policy. Kept separate from {@link SceneGatePort}
 * so the three-state assembly (OPEN / LOCKED / HIDDEN) can combine a
 * per-tenant gate verdict with a platform-level policy and stays unit-testable
 * against two orthogonal mocks.
 */
public interface LockedTilePolicyPort {

    /**
     * Current policy value: "SHOW_LOCKED" (locked tiles stay visible) or
     * "HIDE" (locked tiles are dropped). Missing row or read failure falls
     * back to "SHOW_LOCKED".
     */
    String getLockedTilePolicy();
}
