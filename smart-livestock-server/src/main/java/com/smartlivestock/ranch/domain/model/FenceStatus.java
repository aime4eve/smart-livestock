package com.smartlivestock.ranch.domain.model;

/**
 * Classification of a livestock position relative to all active fences of a farm.
 * <ul>
 *   <li>{@code SAFE} — inside at least one active fence</li>
 *   <li>{@code APPROACH} — outside all fences but inside at least one fence buffer zone</li>
 *   <li>{@code BREACH} — outside all fences and all buffer zones</li>
 * </ul>
 */
public enum FenceStatus {
    SAFE,
    APPROACH,
    BREACH
}
