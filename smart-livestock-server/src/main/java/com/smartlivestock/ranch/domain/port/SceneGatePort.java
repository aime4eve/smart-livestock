package com.smartlivestock.ranch.domain.port;

/**
 * ACL port for the Ranch overview (NIX-389) to ask Commerce whether a
 * scene's feature gate is locked for the current tenant. The ranch context
 * stays free of Commerce imports; the implementation lives in the commerce
 * ACL layer and resolves the request tenant from TenantContext.
 */
public interface SceneGatePort {

    /**
     * Whether the given feature key is locked for the current tenant
     * (feature_gates consulted through the request tenant's effective tier).
     *
     * @param featureKey feature_gates key, e.g. "calving_warning"
     */
    boolean isLocked(String featureKey);
}
