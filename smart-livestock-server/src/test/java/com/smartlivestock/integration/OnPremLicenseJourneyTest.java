package com.smartlivestock.integration;

import com.smartlivestock.licensing.application.LicenseTimeGuardService;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.testsupport.LicenseTestSupport;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Journey verification of the on-premise sales commitment from the
 * 2026-09-10 inquiry reply: "you may provide your own server deployment
 * resources; after the first year the subscription/license fee is confirmed
 * by deployment scale and project needs."
 * <p>
 * Runs a second Spring context with {@code smartlivestock.license.mode=ONPREM}
 * against the same real database and walks the customer-machine lifecycle:
 * <ol>
 *   <li>before activation every business API is locked (403 LICENSE_REQUIRED)
 *       — the deployment cannot be used without a license;</li>
 *   <li>enrollment returns the installation id + host fingerprint that the
 *       offline issuer binds the certificate to;</li>
 *   <li>a license bound to a different machine is refused
 *       (LICENSE_BINDING_MISMATCH) — the license really ties to the
 *       customer's server;</li>
 *   <li>a correctly bound trial license activates the deployment (validity
 *       compressed to seconds so expiry can be observed);</li>
 *   <li>on expiry the scheduled revalidation degrades the subscription to
 *       FREE/BASIC while the produced data is retained;</li>
 *   <li>a renewed ACTIVE license (fresh validity, paid tier) restores
 *       activation — the "renew by importing a new license file" path.</li>
 * </ol>
 */
class OnPremLicenseJourneyTest extends AbstractJourneyTest {

    /** Admin-provisioned accounts start with must_change_password (NIX-191). */
    private static final String INITIAL_PASSWORD = "Test@" + "123";
    private static final String TENANT_PASSWORD = "Renew" + "Pass" + "123";

    private static Path machineIdFile;

    @BeforeAll
    static void prepareHostIdentity() throws IOException {
        // HostFingerprintReader fails fast on a missing/blank source file, so
        // the ONPREM context needs a real host identity file to hash.
        machineIdFile = Files.createTempFile("onprem-journey-machine-id", ".txt");
        Files.writeString(machineIdFile, "onprem-journey-" + UUID.randomUUID());
    }

    @DynamicPropertySource
    static void onPremLicenseProperties(DynamicPropertyRegistry registry) {
        registry.add("smartlivestock.license.mode", () -> "ONPREM");
        registry.add("smartlivestock.license.host-fingerprint-file",
                () -> machineIdFile.toString());
    }

    @Autowired
    private LicenseTimeGuardService timeGuardService;

    @Test
    @SuppressWarnings("unchecked")
    void offlineLicense_hostBinding_expiry_renewalJourney() throws InterruptedException {
        // ── 1. the customer's server = brand-new tenant, locked ────────
        Map<String, Object> tenant = createTenant("onprem-journey-" + uniqueSuffix());
        String tenantId = extractId(tenant);
        long tenantIdLong = Long.parseLong(tenantId);
        String tenantToken = createTenantAdminAndLogin(tenantId);

        ResponseEntity<Map> locked = getRaw(tenantToken, "/api/v1/farms");
        assertThat(locked.getStatusCode().value()).isEqualTo(403);
        assertThat(locked.getBody().get("code")).isEqualTo("LICENSE_REQUIRED");

        // ── 2. enrollment: installation id + host fingerprint ──────────
        Map<String, Object> enrollment = getApi(platformAdminToken,
                "/api/v1/admin/deployment-license/enrollment?tenantId=" + tenantId);
        String installationId = (String) enrollment.get("installationId");
        String fingerprintHash = (String) enrollment.get("fingerprintHash");
        assertThat(installationId).isNotBlank();
        assertThat(fingerprintHash).hasSize(64);

        // ── 3. a license bound to another machine is refused ───────────
        String wrongMachineLicense = signedEnvelope(tenantIdLong,
                UUID.randomUUID().toString(), fingerprintHash,
                "TRIAL", "BASIC", Instant.now().plus(365, ChronoUnit.DAYS));
        ResponseEntity<Map> mismatch =
                importLicense(tenantIdLong, wrongMachineLicense);
        assertThat(mismatch.getStatusCode().value()).isEqualTo(403);
        assertThat(mismatch.getBody().get("code")).isEqualTo("LICENSE_BINDING_MISMATCH");

        // ── 4. correctly bound trial license activates the deployment ──
        Instant trialExpiry = Instant.now().plusSeconds(4);
        String trialLicense = signedEnvelope(tenantIdLong, installationId, fingerprintHash,
                "TRIAL", "BASIC", trialExpiry);
        ResponseEntity<Map> imported = importLicense(tenantIdLong, trialLicense);
        assertThat(imported.getStatusCode().value()).isEqualTo(200);
        assertThat(((Map<String, Object>) imported.getBody().get("data")).get("runtimeStatus"))
                .isEqualTo("VALID");

        Map<String, Object> current = currentStatus(tenantId);
        assertThat(current.get("runtimeStatus")).isEqualTo("VALID");
        assertThat(current.get("licenseType")).isEqualTo("TRIAL");
        assertThat(current.get("subscriptionStatus")).isEqualTo("TRIAL");

        // ── 5. unlocked: the customer produces real data ───────────────
        assertThat(getRaw(tenantToken, "/api/v1/farms").getStatusCode().value()).isEqualTo(200);
        String farmName = "地端试点牧场-" + uniqueSuffix();
        ResponseEntity<Map> farmResp = postRaw(tenantToken, "/api/v1/farms",
                Map.of("name", farmName, "latitude", 28.25, "longitude", 112.85));
        assertCreated(farmResp);
        String farmId = extractId((Map<String, Object>) farmResp.getBody().get("data"));

        String livestockCode = "SL-OP-" + uniqueSuffix();
        ResponseEntity<Map> livestockResp = postRaw(tenantToken,
                "/api/v1/farms/" + farmId + "/livestock",
                Map.of("livestockCode", livestockCode, "breed", "SIMMENTAL",
                        "healthStatus", "HEALTHY"));
        assertCreated(livestockResp);

        // ── 6. license expires: revalidation degrades to the free tier ─
        Thread.sleep(Duration.between(Instant.now(), trialExpiry).toMillis() + 1500);
        assertThat(timeGuardService.validateTenant(tenantIdLong))
                .contains(LicenseRuntimeStatus.EXPIRED);

        Map<String, Object> expiredStatus = currentStatus(tenantId);
        assertThat(expiredStatus.get("runtimeStatus")).isEqualTo("EXPIRED");
        assertThat(expiredStatus.get("subscriptionStatus")).isEqualTo("FREE");

        Map<String, Object> subAfterExpiry = getSubscription(tenantToken);
        assertThat(subAfterExpiry.get("status")).isEqualTo("FREE");
        assertThat(subAfterExpiry.get("tier")).isEqualTo("BASIC");
        assertThat(subAfterExpiry.get("effectiveTier")).isEqualTo("BASIC");
        assertThat(listLivestockCodes(tenantToken, farmId)).contains(livestockCode);

        // ── 7. renewal: fresh ACTIVE license restores the paid tier ────
        String renewalLicense = signedEnvelope(tenantIdLong, installationId, fingerprintHash,
                "ACTIVE", "PREMIUM", Instant.now().plus(365, ChronoUnit.DAYS));
        ResponseEntity<Map> renewed = importLicense(tenantIdLong, renewalLicense);
        assertThat(renewed.getStatusCode().value()).isEqualTo(200);
        assertThat(((Map<String, Object>) renewed.getBody().get("data")).get("runtimeStatus"))
                .isEqualTo("VALID");

        Map<String, Object> renewedStatus = currentStatus(tenantId);
        assertThat(renewedStatus.get("runtimeStatus")).isEqualTo("VALID");
        assertThat(renewedStatus.get("subscriptionStatus")).isEqualTo("ACTIVE");

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

    private String createTenantAdminAndLogin(String tenantId) {
        String phone = uniquePhone();
        assertCreated(postRaw(platformAdminToken, "/api/v1/admin/users",
                Map.of("phone", phone, "name", "onprem-admin",
                        "role", "B2B_ADMIN", "tenantId", tenantId,
                        "password", INITIAL_PASSWORD)));
        String token = login(phone, INITIAL_PASSWORD);
        // complete the forced password change, then re-login
        putApi(token, "/api/v1/me/password",
                Map.of("oldPassword", INITIAL_PASSWORD, "newPassword", TENANT_PASSWORD));
        return login(phone, TENANT_PASSWORD);
    }

    /** Sign a license envelope with the test key, bound to the given host triple. */
    private String signedEnvelope(long tenantId, String installationId, String fingerprintHash,
                                  String licenseType, String tier, Instant expiresAt) {
        Map<String, Object> payload = LicenseTestSupport.validPayloadMap();
        payload.put("licenseId", UUID.randomUUID().toString());
        payload.put("tenantId", tenantId);
        payload.put("installationId", installationId);
        payload.put("fingerprintHash", fingerprintHash);
        payload.put("licenseType", licenseType);
        payload.put("tier", tier);
        payload.put("effectiveTier", "TRIAL".equals(licenseType) ? "PREMIUM" : tier);
        payload.put("expiresAt", expiresAt);
        return LicenseTestSupport.buildEnvelopeJson(payload);
    }

    private ResponseEntity<Map> importLicense(long tenantId, String envelope) {
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new ByteArrayResource(envelope.getBytes(StandardCharsets.UTF_8)) {
            @Override
            public String getFilename() {
                return "license.sllicense";
            }
        });
        body.add("confirm", "true");
        HttpHeaders headers = authHeaders(platformAdminToken);
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        return restTemplate.exchange("/api/v1/admin/deployment-license?tenantId=" + tenantId,
                HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> currentStatus(String tenantId) {
        return getApi(platformAdminToken,
                "/api/v1/admin/deployment-license/current?tenantId=" + tenantId);
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
        return "137" + String.format("%08d", 20_000_000 + (System.nanoTime() % 79_999_999));
    }
}
