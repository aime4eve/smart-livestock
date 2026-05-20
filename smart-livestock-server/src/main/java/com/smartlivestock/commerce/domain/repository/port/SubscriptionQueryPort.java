package com.smartlivestock.commerce.domain.repository.port;

import java.util.Optional;

/**
 * Query interface for cross-context subscription status lookups.
 * Implemented by the persistence layer to expose read-only subscription info.
 */
public interface SubscriptionQueryPort {
    Optional<String> findSubscriptionStatusByTenantId(Long tenantId);
}
