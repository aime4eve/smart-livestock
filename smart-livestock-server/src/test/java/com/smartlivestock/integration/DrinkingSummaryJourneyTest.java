package com.smartlivestock.integration;

import com.smartlivestock.health.domain.model.DrinkingAlgorithmVersion;
import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * NIX-256 Task 5a — drinking read endpoints journey (Testcontainers;
 * compile-only on machines without Docker — GitHub CI excludes the
 * integration package via -PexcludeIntegrationTests=true, so actual
 * execution happens in Docker environments: local Docker runs /
 * post-dev-deploy smoke, bound to the NIX-256 T7 checklist). Covers the
 * three farm-scoped GET endpoints end to end:
 * the event list with the closed Shanghai date range, the three-layer
 * summary (daily §15.3 filtering, weekly direct sum, 30-day baseline over
 * sample days — expected values recomputed from the repositories), the
 * Premium gate (403 on a downgraded tier, bilingual message), and the
 * INSUFFICIENT_PEERS degradation. The counting predicate itself is
 * unit-tested in {@code DrinkingEventServiceTest}/{@code DrinkingSummaryServiceTest}.
 */
public class DrinkingSummaryJourneyTest extends AbstractJourneyTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final String PREFIX = "/api/v1/farms/1/livestock/%s";

    @Autowired
    private DrinkingEventJpaRepository eventRepository;

    @Autowired
    private TemperatureLogJpaRepository temperatureLogRepository;

    @Autowired
    private DeviceQueryPort deviceQueryPort;

    @Autowired
    private RanchQueryPort ranchQueryPort;

    private Long livestockId;
    private Long deviceId;

    /** Previous Shanghai day — one complete, deterministic cow-day. */
    private LocalDate fixtureDay;

    private final List<Long> createdEventIds = new ArrayList<>();
    private final List<TemperatureLogJpaEntity> createdTemperatureLogs = new ArrayList<>();

    @BeforeEach
    void setUpSummary() {
        List<Long> farmLivestockIds = ranchQueryPort.findAllByFarmId(1L).stream()
                .map(LivestockInfo::id)
                .toList();
        CapsuleBinding chosen = deviceQueryPort.findActiveCapsuleBindings(farmLivestockIds).stream()
                .findFirst()
                .orElseThrow(() -> new IllegalStateException(
                        "Seed data has no farm-1 livestock with an active capsule"));
        livestockId = chosen.livestockId();
        deviceId = chosen.deviceId();
        fixtureDay = LocalDate.now(ZONE).minusDays(1);
    }

    @AfterEach
    void tearDownSummary() {
        createdEventIds.forEach(id -> eventRepository.findById(id).ifPresent(eventRepository::delete));
        createdEventIds.clear();
        temperatureLogRepository.deleteAll(createdTemperatureLogs);
        createdTemperatureLogs.clear();
    }

    private String base() {
        return String.format(PREFIX, livestockId);
    }

    private Instant wall(LocalDate day, String wallClock) {
        return day.atTime(LocalTime.parse(wallClock)).atZone(ZONE).toInstant();
    }

    // ── Fixture helpers ─────────────────────────────────────────

    private Long insertEvent(LocalDate day, String startClock, String endClock,
                             String source, DrinkingEventLabel label, String algorithmVersion) {
        return insertEvent(day, startClock, endClock, source, label, algorithmVersion,
                new BigDecimal("0.850"));
    }

    private Long insertEvent(LocalDate day, String startClock, String endClock,
                             String source, DrinkingEventLabel label, String algorithmVersion,
                             BigDecimal confidence) {
        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setDeviceId(deviceId);
        entity.setLivestockId(livestockId);
        entity.setEventStartAt(wall(day, startClock));
        entity.setEventEndAt(wall(day, endClock));
        entity.setTempDrop(new BigDecimal("2.20"));
        entity.setMinTemp(new BigDecimal("36.80"));
        entity.setSource(source);
        entity.setLabel(label);
        entity.setConfidence(confidence);
        entity.setAlgorithmVersion(algorithmVersion);
        DrinkingEventJpaEntity saved = eventRepository.save(entity);
        createdEventIds.add(saved.getId());
        return saved.getId();
    }

    /** 48 half-hourly points (≥ the 24-point sample-day floor) on one day. */
    private void insertPointGrid(LocalDate day) {
        for (int minute = 0; minute < 24 * 60; minute += 30) {
            TemperatureLogJpaEntity entity = new TemperatureLogJpaEntity();
            entity.setLivestockId(livestockId);
            entity.setDeviceId(deviceId);
            entity.setTemperature(BigDecimal.valueOf(38.5 + (minute % 60 == 0 ? 0.05 : -0.05))
                    .setScale(2, RoundingMode.HALF_UP));
            entity.setBaselineTemp(new BigDecimal("38.50"));
            entity.setRecordedAt(day.atTime(LocalTime.MIN).plusMinutes(minute).atZone(ZONE).toInstant());
            entity.setSource("DATAGEN");
            createdTemperatureLogs.add(temperatureLogRepository.save(entity));
        }
    }

    private long pointsOn(LocalDate day) {
        return temperatureLogRepository.countByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThan(
                livestockId, day.atStartOfDay(ZONE).toInstant(),
                day.plusDays(1).atStartOfDay(ZONE).toInstant());
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> getData(ResponseEntity<Map> response) {
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        return (Map<String, Object>) response.getBody().get("data");
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> getDataList(ResponseEntity<Map> response) {
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        return (List<Map<String, Object>>) response.getBody().get("data");
    }

    // ── 1. Three endpoints, three layers ────────────────────────

    @Test
    void summaryEndpointsServeTracingTableShapes() {
        insertPointGrid(fixtureDay);
        // 4 counted rows (2 detected + 1 promoted candidate + 1 manual),
        // 2 rows that must stay outside every statistic.
        insertEvent(fixtureDay, "09:00", "09:10", "DATAGEN",
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1);
        insertEvent(fixtureDay, "10:30", "10:40", "DATAGEN",
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1);
        insertEvent(fixtureDay, "12:00", "12:08", "DATAGEN",
                DrinkingEventLabel.REJECTED, DrinkingAlgorithmVersion.V1);
        insertEvent(fixtureDay, "14:00", "14:06", DrinkingEventSources.ALGORITHM_CANDIDATE,
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1);
        insertEvent(fixtureDay, "15:30", "15:36", DrinkingEventSources.ALGORITHM_CANDIDATE,
                DrinkingEventLabel.CONFIRMED, DrinkingAlgorithmVersion.V1);
        insertEvent(fixtureDay, "17:00", "17:10", DrinkingEventSources.MANUAL,
                DrinkingEventLabel.CONFIRMED, DrinkingAlgorithmVersion.MANUAL);

        // days=1: daily only.
        Map<String, Object> daily = getData(getRaw(ownerToken,
                base() + "/drinking-summary?date=" + fixtureDay + "&days=1"));
        assertThat(daily.get("weekly")).isNull();
        assertThat(daily.get("rolling30dBaseline")).isNull();
        assertThat(daily.get("dayCounts")).isNull();
        // Every layer variant carries the server-side baseline threshold
        // (spec §4 baseline-min-days, M5) — the client chip reads this.
        assertThat(daily.get("baselineMinDays")).isEqualTo(3);
        Map<String, Object> dailyLayer = (Map<String, Object>) daily.get("daily");
        assertThat(dailyLayer.get("count")).isEqualTo(4);
        List<Map<String, Object>> events = (List<Map<String, Object>>) dailyLayer.get("events");
        assertThat(events).hasSize(4);
        assertThat(events.get(0).get("startAt")).isEqualTo(wall(fixtureDay, "09:00").toString());
        assertThat(events.get(3).get("startAt")).isEqualTo(wall(fixtureDay, "17:00").toString());
        assertThat(events.get(3).get("source")).isEqualTo(DrinkingEventSources.MANUAL);
        assertThat(dailyLayer.get("lastDrinkEndAt")).isEqualTo(wall(fixtureDay, "17:10").toString());

        // days=7: weekly direct sum over [fixtureDay-6, fixtureDay] — the
        // other six days have no events, so the week total is the day's 4.
        Map<String, Object> week = getData(getRaw(ownerToken,
                base() + "/drinking-summary?date=" + fixtureDay + "&days=7"));
        assertThat(week.get("baselineMinDays")).isEqualTo(3);
        Map<String, Object> weekly = (Map<String, Object>) week.get("weekly");
        assertThat(weekly.get("count")).isEqualTo(4);
        assertThat(new BigDecimal(String.valueOf(weekly.get("avgPerDay"))))
                .isEqualByComparingTo(BigDecimal.valueOf(4.0 / 7).setScale(2, RoundingMode.HALF_UP));
        List<Map<String, Object>> bars = (List<Map<String, Object>>) week.get("dayCounts");
        assertThat(bars).hasSize(7);
        assertThat(bars.get(6).get("date")).isEqualTo(fixtureDay.toString());
        assertThat(bars.get(6).get("count")).isEqualTo(4);
        assertThat(bars.get(0).get("date")).isEqualTo(fixtureDay.minusDays(6).toString());

        // days=30: baseline over sample days — expected values recomputed
        // straight from the repositories (points ≥24 rule; seed data may
        // contribute extra sample days beyond the fixture grid).
        int expectedSampleDays = 0;
        for (int offset = 29; offset >= 0; offset--) {
            LocalDate day = fixtureDay.minusDays(offset);
            if (pointsOn(day) >= 24) {
                expectedSampleDays++;
            }
        }
        Map<String, Object> month = getData(getRaw(ownerToken,
                base() + "/drinking-summary?date=" + fixtureDay + "&days=30"));
        assertThat(month.get("baselineMinDays")).isEqualTo(3);
        Map<String, Object> baseline = (Map<String, Object>) month.get("rolling30dBaseline");
        assertThat(baseline.get("sampleDays")).isEqualTo(expectedSampleDays);
        // Only the fixture day carries counted events → 4/sampleDays.
        assertThat(new BigDecimal(String.valueOf(baseline.get("avgPerDay"))))
                .isEqualByComparingTo(BigDecimal.valueOf(4.0 / expectedSampleDays)
                        .setScale(2, RoundingMode.HALF_UP));
        assertThat((List<Map<String, Object>>) month.get("dayCounts")).hasSize(30);
    }

    // ── 2. Event list: closed Shanghai range + DESC + full rows ─

    @Test
    void eventsListHonorsClosedRangeAndOrdersNewestFirst() {
        Long firstMinute = insertEvent(fixtureDay, "00:00", "00:05", "DATAGEN",
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1);
        Long lastMinute = insertEvent(fixtureDay, "23:55", "23:59", "DATAGEN",
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1);
        Long nextDayStart = insertEvent(fixtureDay.plusDays(1), "00:00", "00:05", "DATAGEN",
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1);

        // Closed range [from 00:00, to+1 00:00): both day edges included,
        // the next day's midnight excluded.
        List<Map<String, Object>> rows = getDataList(getRaw(ownerToken,
                base() + "/drinking-events?from=" + fixtureDay + "&to=" + fixtureDay));
        assertThat(rows).hasSize(2);
        // Newest first.
        assertThat(rows.get(0).get("eventStartAt")).isEqualTo(wall(fixtureDay, "23:55").toString());
        assertThat(rows.get(1).get("eventStartAt")).isEqualTo(wall(fixtureDay, "00:00").toString());
        assertThat(rows.get(0).get("id")).isEqualTo(lastMinute);
        assertThat(rows.get(1).get("id")).isEqualTo(firstMinute);

        // The next day's row is served by its own window.
        List<Map<String, Object>> nextRows = getDataList(getRaw(ownerToken,
                base() + "/drinking-events?from=" + fixtureDay.plusDays(1) + "&to=" + fixtureDay.plusDays(1)));
        assertThat(nextRows).hasSize(1);
        assertThat(nextRows.get(0).get("id")).isEqualTo(nextDayStart);

        // Bad range / future day rejected.
        assertError(getRaw(ownerToken, base() + "/drinking-events?from=2026-02-30&to=2026-03-01"),
                HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        assertError(getRaw(ownerToken, base() + "/drinking-events?to=" + LocalDate.now(ZONE).plusDays(2)),
                HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
    }

    // ── 2b. Event list: server-derived lowConfidence flag (M5) ──

    @Test
    void eventsListServesDerivedLowConfidenceFlag() {
        // 0.400 < health.drinking.low-confidence:0.5 → flagged; 0.850 → not.
        insertEvent(fixtureDay, "09:00", "09:10", "DATAGEN",
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1, new BigDecimal("0.400"));
        insertEvent(fixtureDay, "10:00", "10:10", DrinkingEventSources.ALGORITHM_CANDIDATE,
                DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1, new BigDecimal("0.850"));

        List<Map<String, Object>> rows = getDataList(getRaw(ownerToken,
                base() + "/drinking-events?from=" + fixtureDay + "&to=" + fixtureDay));
        assertThat(rows).hasSize(2);
        Map<String, Object> low = rows.stream()
                .filter(r -> String.valueOf(r.get("eventStartAt")).equals(wall(fixtureDay, "09:00").toString()))
                .findFirst().orElseThrow();
        Map<String, Object> normal = rows.stream()
                .filter(r -> String.valueOf(r.get("eventStartAt")).equals(wall(fixtureDay, "10:00").toString()))
                .findFirst().orElseThrow();
        assertThat(low.get("lowConfidence")).isEqualTo(true);
        assertThat(normal.get("lowConfidence")).isEqualTo(false);
    }

    // ── 3. Premium 403 + bilingual message ──────────────────────

    @Test
    void peerComparisonReturns403ForNonPremiumTier() {
        // baseSetUp ensures PREMIUM; downgrade and expect the gate.
        try {
            ResponseEntity<Map> downgraded = putRaw(ownerToken, "/api/v1/subscription/tier",
                    Map.of("tier", "STANDARD"));
            assertThat(downgraded.getStatusCode().is2xxSuccessful()).isTrue();

            ResponseEntity<Map> denied = getRaw(ownerToken, base() + "/drinking-peer-comparison");
            assertError(denied, HttpStatus.FORBIDDEN, "AUTH_FORBIDDEN");
            assertThat(String.valueOf(denied.getBody().get("message")))
                    .isEqualTo("饮水同类对比为 Premium 权益");
        } finally {
            putRaw(ownerToken, "/api/v1/subscription/tier", Map.of("tier", "PREMIUM"));
        }

        // Back on PREMIUM the endpoint answers (200), even if degraded.
        ResponseEntity<Map> allowed = getRaw(ownerToken, base() + "/drinking-peer-comparison");
        assertThat(allowed.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    // ── 4. INSUFFICIENT_PEERS degradation ───────────────────────

    @Test
    void peerComparisonDegradesToInsufficientPeersWithoutQualifiedGroup() {
        // Seed herds carry <5 well-observed days per head, so no peer
        // reaches the MIN_SAMPLE_DAYS=5 bar: a 200 + degraded payload, not
        // an error. (The averaging math is pinned in the unit tests.)
        Map<String, Object> data = getData(getRaw(ownerToken, base() + "/drinking-peer-comparison"));

        assertThat(data.get("peerAvgPerDay")).isNull();
        assertThat(data.get("reason")).isEqualTo("INSUFFICIENT_PEERS");
        assertThat(data.get("minSampleDays")).isEqualTo(5);
        assertThat(data.get("groupBreed")).isNotNull();
    }

    // ── 5. Farm-scope ownership ─────────────────────────────────

    @Test
    void endpointsRejectLivestockOfAnotherFarmOrUnknown() {
        // Sanity: the normal path works for the fixture livestock.
        assertOk(getRaw(ownerToken, base() + "/drinking-summary"));
        // Unknown / foreign livestock id → 404 on every read endpoint.
        Long unknownId = ranchQueryPort.findAllByFarmId(1L).stream()
                .mapToLong(LivestockInfo::id).max().orElse(1L) + 10_000L;
        assertError(getRaw(ownerToken, String.format(PREFIX, unknownId) + "/drinking-summary"),
                HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
        assertError(getRaw(ownerToken, String.format(PREFIX, unknownId) + "/drinking-events"),
                HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
        assertError(getRaw(ownerToken, String.format(PREFIX, unknownId) + "/drinking-peer-comparison"),
                HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
    }
}
