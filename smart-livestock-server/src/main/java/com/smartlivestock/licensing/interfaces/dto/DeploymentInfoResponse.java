package com.smartlivestock.licensing.interfaces.dto;

/**
 * Public deployment descriptor served by {@code GET /api/v1/deployment-info}
 * (unauthenticated; consumed by the login screen).
 *
 * @param mode          HOSTED or ONPREM
 * @param runtimeStatus ONPREM only: latest derived license runtime status
 *                      (PENDING_ACTIVATION / VALID / EXPIRED / SUSPENDED);
 *                      null on HOSTED and before the first ONPREM validation.
 */
public record DeploymentInfoResponse(String mode, String runtimeStatus) {
}
