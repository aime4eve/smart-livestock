package com.smartlivestock.integration;

import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * NIX-256 Task 4 — admin manual recalculation API (Testcontainers; not
 * runnable on machines without Docker — compile-only here, executed in
 * CI/dev). Covers: PLATFORM_ADMIN single-device and all-farms bodies,
 * B2B_ADMIN access, OWNER/WORKER 403, the closed-date-range validations
 * (missing / inverted range → rangeInvalid, future "to" → futureDate) and
 * the unknown-device 404. The endpoint is synchronous; response stats are
 * asserted structurally (counts depend on seed temperature logs, the sweep
 * semantics are unit-tested in DrinkingRecalculationServiceTest).
 */
public class DrinkingRecalculateAdminApiTest extends AbstractJourneyTest {

    private static final String PATH = "/api/v1/admin/drinking-recalculate";
    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

    @Autowired
    private DrinkingEventJpaRepository eventRepository;

    @Autowired
    private DeviceQueryPort deviceQueryPort;

    private Long capsuleDeviceId;
    private String yesterday;
    private Instant windowFrom;
    private Instant windowTo;

    @BeforeEach
    void setUpRecalcAdmin() {
        yesterday = LocalDate.now(ZONE).minusDays(1).toString();
        capsuleDeviceId = deviceQueryPort.findAllActiveCapsuleBindings().stream()
                .map(CapsuleBinding::deviceId)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException(
                        "Seed data has no livestock with an active capsule"));
        windowFrom = LocalDate.parse(yesterday).atStartOfDay(ZONE).toInstant();
        windowTo = windowFrom.plus(Duration.ofDays(1));
    }

    @AfterEach
    void tearDownRecalcAdmin() {
        // Remove the algorithm rows this test wrote (any recalculated
        // device, overlap-extended window ±2h). MANUAL rows never come from
        // this endpoint and are left alone.
        Instant sweepFrom = windowFrom.minus(Duration.ofHours(2));
        Instant sweepTo = windowTo.plus(Duration.ofHours(2));
        List<DrinkingEventJpaEntity> doomed = new ArrayList<>();
        for (CapsuleBinding binding : deviceQueryPort.findAllActiveCapsuleBindings()) {
            eventRepository.findByDeviceIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThan(
                            binding.deviceId(), sweepFrom, sweepTo).stream()
                    .filter(row -> !DrinkingEventSources.MANUAL.equals(row.getSource()))
                    .forEach(doomed::add);
        }
        eventRepository.deleteAll(doomed);
    }

    private ResponseEntity<Map> post(String token, Map<String, Object> body) {
        return postRaw(token, PATH, body);
    }

    private Map<String, Object> deviceBody() {
        Map<String, Object> body = new HashMap<>();
        body.put("deviceId", capsuleDeviceId);
        body.put("from", yesterday);
        body.put("to", yesterday);
        return body;
    }

    private Map<String, Object> farmBody() {
        Map<String, Object> body = new HashMap<>();
        body.put("from", yesterday);
        body.put("to", yesterday);
        return body;
    }

    // ── Happy paths ──────────────────────────────────────────────

    @Test
    @SuppressWarnings("unchecked")
    void platformAdminRecalculatesSingleDevice() {
        ResponseEntity<Map> response = post(platformAdminToken, deviceBody());
        assertOk(response);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("scope")).isEqualTo("DEVICE");
        assertThat(((Number) data.get("devices")).intValue()).isEqualTo(1);
        assertThat(data.get("farms")).isNull();
    }

    @Test
    @SuppressWarnings("unchecked")
    void platformAdminRecalculatesAllFarms() {
        ResponseEntity<Map> response = post(platformAdminToken, farmBody());
        assertOk(response);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("scope")).isEqualTo("ALL_FARMS");
        assertThat(((Number) data.get("farms")).intValue()).isGreaterThanOrEqualTo(1);
        assertThat(((Number) data.get("devices")).intValue()).isGreaterThanOrEqualTo(1);
        assertThat(((Number) data.get("failedFarms")).intValue()).isZero();
    }

    @Test
    @SuppressWarnings("unchecked")
    void b2bAdminRecalculatesSingleDevice() {
        ResponseEntity<Map> response = post(b2bAdminToken, deviceBody());
        assertOk(response);
        Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
        assertThat(data.get("scope")).isEqualTo("DEVICE");
    }

    // ── Authorization ────────────────────────────────────────────

    @Test
    void ownerAndWorkerAreForbidden() {
        assertError(post(ownerToken, deviceBody()), HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");
        assertError(post(workerToken, farmBody()), HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");
    }

    // ── Validation ───────────────────────────────────────────────

    @Test
    void invertedMissingAndMalformedRangesAreRejected() {
        Map<String, Object> inverted = new HashMap<>();
        inverted.put("from", "2026-10-05");
        inverted.put("to", "2026-10-03");
        assertError(post(platformAdminToken, inverted), HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");

        Map<String, Object> missingFrom = new HashMap<>(farmBody());
        missingFrom.remove("from");
        assertError(post(platformAdminToken, missingFrom), HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");

        Map<String, Object> malformed = new HashMap<>();
        malformed.put("from", "2026/10/03");
        malformed.put("to", "2026-10-03");
        assertError(post(platformAdminToken, malformed), HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
    }

    @Test
    void futureToIsRejected() {
        Map<String, Object> future = new HashMap<>();
        future.put("from", LocalDate.now(ZONE).toString());
        future.put("to", LocalDate.now(ZONE).plusDays(1).toString());
        assertError(post(platformAdminToken, future), HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
    }

    @Test
    void unknownDeviceIsRejectedWith404() {
        Map<String, Object> body = deviceBody();
        body.put("deviceId", 999999L);
        assertError(post(platformAdminToken, body), HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
    }
}
