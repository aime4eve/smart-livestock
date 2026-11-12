package com.smartlivestock.ranch.domain.port;

/**
 * ACL port for the Ranch fence track-draft flow to ask Commerce/Licensing
 * for the current tenant's {@code fence_management} limit. The ranch context
 * stays free of Commerce/Licensing imports; the implementation lives in the
 * commerce ACL layer and resolves the request tenant from TenantContext.
 * <p>
 * Semantics mirror the {@code @QuotaCheck} chain (QuotaApplicationService):
 * license quota wins (ONPREM valid license carrying the key), otherwise the
 * tenant effective tier's feature_gates LIMIT row supplies the value; a
 * NONE gate, a missing gate/subscription, or no tenant context all resolve
 * to {@code null} meaning "unlimited" (enterprise).
 */
public interface FenceQuotaPort {

    /**
     * Numeric fence cap for the current tenant, or {@code null} when the
     * tier/license imposes no cap.
     */
    Integer resolveFenceManagementLimitForCurrentTenant();
}
