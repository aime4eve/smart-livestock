package com.smartlivestock.integration;

import com.smartlivestock.commerce.application.job.CommerceScheduler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Journey verification of the hosted (cloud) sales commitment from the
 * 2026-09-10 inquiry reply: "the software service is free for the first
 * year; after that, subscription pricing is confirmed by deployment scale
 * and project needs."
 * <p>
 * Walks the real hosted lifecycle against the real database:
 * <ol>
 *   <li>a brand-new tenant (the inquiry) is opened a 365-day pilot license —
 *       TRIAL subscription with PREMIUM effective tier, i.e. the
 *       "first year free at full capability" promise;</li>
 *   <li>the customer produces real data during the pilot (farm + livestock);</li>
 *   <li>when the trial runs out, the production hourly expiry job degrades
 *       the subscription to the free tier (FREE/BASIC) while every produced
 *       record is retained;</li>
 *   <li>renewal (contract signed → self-service checkout) restores the paid
 *       tier, and the data survives the entire cycle.</li>
 * </ol>
 */
class HostedFirstYearFreeJourneyTest extends AbstractJourneyTest {

    /** Admin-provisioned accounts start with must_change_password (NIX-191). */
    private static final String INITIAL_PASSWORD = "Test@" + "123";
    private static final String TENANT_PASSWORD = "Renew" + "Pass" + "123";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private CommerceScheduler commerceScheduler;

    @Test
    @SuppressWarnings("unchecked")
    void pilotFirstYearFree_expiryDowngrade_renewalRestoreJourney() {
        // ── 1. inquiry → brand-new tenant without any subscription ──────
        Map<String, Object> tenant = createTenant("hosted-free-year-" + uniqueSuffix());
        String tenantId = extractId(tenant);

        // ── 2. we open the 365-day pilot = "first year free" ────────────
        Map<String, Object> body = postRaw(platformAdminToken,
                "/api/v1/admin/tenants/" + tenantId + "/pilot-license", Map.of()).getBody();
        assertThat(body.get("code")).isEqualTo("OK");
        Map<String, Object> pilot = (Map<String, Object>) body.get("data");
        assertThat(pilot.get("status")).isEqualTo("TRIAL");
        Instant trialEndsAt = Instant.parse((String) pilot.get("trialEndsAt"));
        assertThat(trialEndsAt).isAfter(Instant.now().plus(364, ChronoUnit.DAYS));

        Map<String, Object> subDuringTrial = findSubscriptionRow(tenantId);
        assertThat(subDuringTrial.get("tier")).isEqualTo("BASIC");
        assertThat(subDuringTrial.get("effectiveTier")).isEqualTo("PREMIUM");

        // ── 3. the customer really uses the platform during the pilot ───
        String adminPhone = uniquePhone();
        assertCreated(postRaw(platformAdminToken, "/api/v1/admin/users",
                Map.of("phone", adminPhone, "name", "first-year-admin",
                        "role", "B2B_ADMIN", "tenantId", tenantId,
                        "password", INITIAL_PASSWORD)));
        String tenantToken = login(adminPhone, INITIAL_PASSWORD);
        // complete the forced password change, then re-login
        putApi(tenantToken, "/api/v1/me/password",
                Map.of("oldPassword", INITIAL_PASSWORD, "newPassword", TENANT_PASSWORD));
        tenantToken = login(adminPhone, TENANT_PASSWORD);

        String farmName = "试点牧场-" + uniqueSuffix();
        ResponseEntity<Map> farmResp = postRaw(tenantToken, "/api/v1/farms",
                Map.of("name", farmName, "latitude", 28.25, "longitude", 112.85));
        assertCreated(farmResp);
        String farmId = extractId((Map<String, Object>) farmResp.getBody().get("data"));

        String livestockCode = "SL-FY-" + uniqueSuffix();
        ResponseEntity<Map> livestockResp = postRaw(tenantToken,
                "/api/v1/farms/" + farmId + "/livestock",
                Map.of("livestockCode", livestockCode, "breed", "SIMMENTAL",
                        "healthStatus", "HEALTHY"));
        assertCreated(livestockResp);

        // ── 4. the trial runs out: shift trial_ends_at into the past, then
        //       run the exact hourly job the production scheduler executes ─
        jdbcTemplate.update("UPDATE subscriptions SET trial_ends_at = ? WHERE tenant_id = ?",
                Timestamp.from(Instant.now().minusSeconds(3600)), Long.parseLong(tenantId));
        commerceScheduler.expireTrials();

        // ── 5. degraded to the free tier, all pilot data retained ───────
        Map<String, Object> subAfterExpiry = getSubscription(tenantToken);
        assertThat(subAfterExpiry.get("status")).isEqualTo("FREE");
        assertThat(subAfterExpiry.get("tier")).isEqualTo("BASIC");
        assertThat(subAfterExpiry.get("effectiveTier")).isEqualTo("BASIC");
        assertThat(listLivestockCodes(tenantToken, farmId)).contains(livestockCode);

        // ── 6. renewal restores the paid tier; data still intact ────────
        Map<String, Object> checkoutData = postApi(tenantToken, "/api/v1/subscription/checkout",
                Map.of("tier", "PREMIUM", "billingCycle", "monthly"));
        assertThat(checkoutData.get("status")).isEqualTo("ACTIVE");

        Map<String, Object> subAfterRenewal = getSubscription(tenantToken);
        assertThat(subAfterRenewal.get("status")).isEqualTo("ACTIVE");
        assertThat(subAfterRenewal.get("tier")).isEqualTo("PREMIUM");
        assertThat(subAfterRenewal.get("effectiveTier")).isEqualTo("PREMIUM");
        assertThat(listLivestockCodes(tenantToken, farmId)).contains(livestockCode);
    }

    // ── helpers ──────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private Map<String, Object> createTenant(String name) {
        Map<String, Object> body = postRaw(platformAdminToken, "/api/v1/admin/tenants",
                Map.of("name", name, "contactName", "journey", "contactPhone", "13900000000")).getBody();
        assertThat(body.get("code")).isEqualTo("OK");
        return (Map<String, Object>) body.get("data");
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> findSubscriptionRow(String tenantId) {
        Map<String, Object> data = getApi(platformAdminToken,
                "/api/v1/admin/subscriptions?tenantId=" + tenantId);
        List<Map<String, Object>> items = (List<Map<String, Object>>) data.get("items");
        return items.stream()
                .filter(it -> tenantId.equals(String.valueOf(it.get("tenantId"))))
                .findFirst().orElseThrow();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> getSubscription(String token) {
        return getApi(token, "/api/v1/subscription");
    }

    @SuppressWarnings("unchecked")
    private List<String> listLivestockCodes(String token, String farmId) {
        Map<String, Object> data = getApi(token,
                "/api/v1/farms/" + farmId + "/livestock?page=0&pageSize=100");
        List<Map<String, Object>> items = (List<Map<String, Object>>) data.get("items");
        return items.stream().map(it -> String.valueOf(it.get("livestockCode"))).toList();
    }

    private String uniqueSuffix() {
        return Long.toString(System.nanoTime(), 36);
    }

    private String uniquePhone() {
        return "138" + String.format("%08d", 20_000_000 + (System.nanoTime() % 79_999_999));
    }
}
