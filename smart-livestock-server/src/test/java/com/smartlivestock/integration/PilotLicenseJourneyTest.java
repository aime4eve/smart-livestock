package com.smartlivestock.integration;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Journey test for the hosted pilot license flow (NIX-184).
 * <p>
 * Exercises the real database: trial subscription creation must satisfy the
 * subscriptions schema constraints (billing_cycle NOT NULL etc.). This is the
 * guard that unit tests with mocked repositories cannot provide.
 */
class PilotLicenseJourneyTest extends AbstractJourneyTest {

    private static final String PILOT_URL = "/api/v1/admin/tenants/%s/pilot-license";

    @Test
    @SuppressWarnings("unchecked")
    void grantCreatesTrialSubscriptionPersistedInDatabase() {
        // fresh tenant without any subscription
        Map<String, Object> tenant = createTenant("pilot-journey-" + System.nanoTime());
        String tenantId = String.valueOf(tenant.get("id"));

        Map<String, Object> body = postRaw(platformAdminToken, String.format(PILOT_URL, tenantId), Map.of()).getBody();
        assertThat(body.get("code")).isEqualTo("OK");

        Map<String, Object> data = (Map<String, Object>) body.get("data");
        assertThat(data.get("status")).isEqualTo("TRIAL");

        Instant trialEndsAt = Instant.parse((String) data.get("trialEndsAt"));
        Instant expectedFloor = Instant.now().plus(364, ChronoUnit.DAYS);
        assertThat(trialEndsAt).isAfter(expectedFloor);

        // the row must really be in the database with a usable subscription
        Map<String, Object> subs = getApi(platformAdminToken, "/api/v1/admin/subscriptions?tenantId=" + tenantId);
        List<Map<String, Object>> items = (List<Map<String, Object>>) subs.get("items");
        assertThat(items).isNotEmpty();
        Map<String, Object> sub = items.stream()
                .filter(it -> String.valueOf(it.get("tenantId")).equals(tenantId))
                .findFirst().orElseThrow();
        assertThat(sub.get("status")).isEqualTo("TRIAL");
        assertThat(sub.get("tier")).isEqualTo("BASIC");
        assertThat(sub.get("effectiveTier")).isEqualTo("PREMIUM");
        assertThat((String) sub.get("billingCycle")).isNotBlank();
    }

    @Test
    @SuppressWarnings("unchecked")
    void regrantExtendsTrialInsteadOfShortening() {
        Map<String, Object> tenant = createTenant("pilot-extend-" + System.nanoTime());
        String tenantId = String.valueOf(tenant.get("id"));

        Instant firstEnd = Instant.parse((String) ((Map<String, Object>) postRaw(
                platformAdminToken, String.format(PILOT_URL, tenantId), Map.of()).getBody().get("data")).get("trialEndsAt"));

        Map<String, Object> body = postRaw(platformAdminToken, String.format(PILOT_URL, tenantId), Map.of()).getBody();
        assertThat(body.get("code")).isEqualTo("OK");
        Instant secondEnd = Instant.parse((String) ((Map<String, Object>) body.get("data")).get("trialEndsAt"));

        // extension must never shorten the current trial end
        assertThat(secondEnd).isAfterOrEqualTo(firstEnd);
    }

    @Test
    @SuppressWarnings("unchecked")
    void activeSubscriptionTenantIsRejectedWithStateConflict() {
        // Demo Ranch (seed tenant 1) ships with an ACTIVE subscription
        Map<String, Object> body = postRaw(platformAdminToken, String.format(PILOT_URL, 1), Map.of()).getBody();
        assertThat(body.get("code")).isEqualTo("STATE_CONFLICT");
    }

    private Map<String, Object> createTenant(String name) {
        Map<String, Object> body = postRaw(platformAdminToken, "/api/v1/admin/tenants",
                Map.of("name", name, "contactName", "journey", "contactPhone", "13900000000")).getBody();
        assertThat(body.get("code")).isEqualTo("OK");
        return (Map<String, Object>) body.get("data");
    }
}
