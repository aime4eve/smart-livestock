package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.service.BaselineExclusionWindow;
import com.smartlivestock.health.domain.service.BaselineLearningInput;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

/**
 * Assembles the self-contained {@link BaselineLearningInput} of one
 * individual baseline learning run (plan 2026-11-03 §1.2): the exclusion
 * windows (illness +fever buffer, fever alerts +fever buffer, drinking
 * +recovery window) and every kernel tuning from
 * {@link BaselineLearningProperties}.
 *
 * <p>Shared by the write path
 * ({@link IndividualBaselineLearningService#recalculate}) and the read-only
 * admin A/B evaluation ({@link BaselineEvaluationService#evaluate}) so a
 * learned candidate can never drift from what a production learning run
 * would compute — the two callers issue the same window queries and feed
 * this one assembly (reuse, not copy). The window temperatures/activities
 * are fetched by the callers (both need the raw lists: the learning service
 * for the kernel, the evaluation also for the scoring replay) and passed in.</p>
 */
@Service
@RequiredArgsConstructor
public class BaselineLearningInputAssembler {

    private static final String SOURCE_DEFAULT = "DEFAULT";
    private static final List<String> FEVER_ALERT_TYPES = List.of("TEMPERATURE_ABNORMAL");

    private final BaselineLearningProperties properties;
    private final DrinkingEventJpaRepository drinkingEventJpaRepository;
    private final PhysiologyQueryPort physiologyQueryPort;
    private final RanchQueryPort ranchQueryPort;

    /**
     * Build the kernel input for one livestock from pre-fetched window data.
     * {@code previousSource}/{@code previousBaselineTemp} come from the
     * snapshot's current values; every tuning parameter comes from the
     * properties; the exclusion windows are queried here.
     */
    public BaselineLearningInput assemble(Long livestockId, HealthSnapshot snapshot,
                                          Instant asOf, int windowDays, ZoneId farmZone,
                                          List<TemperatureLog> temperatures, List<ActivityLog> activities) {
        Instant windowStart = asOf.minus(Duration.ofDays(windowDays));
        String previousSource = snapshot.getBaselineSource() != null
                ? snapshot.getBaselineSource() : SOURCE_DEFAULT;
        return BaselineLearningInput.builder()
                .livestockId(livestockId)
                .asOf(asOf)
                .farmZone(farmZone)
                .previousSource(previousSource)
                .previousBaselineTemp(snapshot.getBaselineTemp())
                .windowDays(windowDays)
                .minQualifiedDays(properties.getMinQualifiedDays())
                .minSamplesPerDay(properties.getMinSamplesPerDay())
                .madFloor(properties.getMadFloor())
                .feverBufferHours(properties.getFeverBufferHours())
                .drinkingRecoveryWindowMin(properties.getDrinkingRecoveryWindowMin())
                .activityToleranceMin(properties.getActivityToleranceMin())
                .allowedSources(properties.getAllowedSources())
                .temperatures(temperatures)
                .activities(activities)
                .illnessWindows(illnessWindows(livestockId, windowStart, asOf))
                .feverAlertWindows(feverAlertWindows(snapshot.getFarmId(), livestockId, windowStart))
                .drinkingWindows(drinkingWindows(livestockId, windowStart, asOf))
                .build();
    }

    /**
     * Manual ILLNESS/RECOVERY pairs (plus epidemic dispositions merged at
     * read time) as raw exclusion windows — the ILLNESS half of the old
     * merged "fever window" assembly, split per plan Task 3. The lower bound
     * is widened by the fever buffer so windows that ended just before the
     * window still reach into it after the kernel buffers their ends; the
     * kernel itself applies the buffer, so windows are passed unbuffered.
     */
    private List<BaselineExclusionWindow> illnessWindows(Long livestockId, Instant windowStart, Instant asOf) {
        Instant from = windowStart.minus(Duration.ofHours(properties.getFeverBufferHours()));
        return physiologyQueryPort.activeWindows(livestockId, from, asOf).stream()
                .map(w -> new BaselineExclusionWindow(w.occurredAt(), w.endedAt()))
                .toList();
    }

    /**
     * TEMPERATURE_ABNORMAL alert windows of this livestock as raw intervals
     * — the alert half of the old merged assembly, split per plan Task 3.
     * ACTIVE alerts are open-ended {@code [created_at, ∞)}; resolved alerts
     * close at {@code resolved_at}. Resolved alerts are fetched since
     * windowStart − fever buffer so the kernel's buffered end still covers
     * window-edge samples (same semantics as the drinking detector).
     */
    private List<BaselineExclusionWindow> feverAlertWindows(Long farmId, Long livestockId, Instant windowStart) {
        List<BaselineExclusionWindow> windows = new ArrayList<>();
        ranchQueryPort.findActiveAlertsByFarmIdAndTypes(farmId, FEVER_ALERT_TYPES).stream()
                .filter(alert -> livestockId.equals(alert.livestockId()))
                .forEach(alert -> windows.add(new BaselineExclusionWindow(alert.createdAt(), alert.resolvedAt())));
        Instant resolvedSince = windowStart.minus(Duration.ofHours(properties.getFeverBufferHours()));
        ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(farmId, FEVER_ALERT_TYPES, resolvedSince).stream()
                .filter(alert -> livestockId.equals(alert.livestockId()))
                .forEach(alert -> windows.add(new BaselineExclusionWindow(alert.createdAt(), alert.resolvedAt())));
        return windows;
    }

    /**
     * Drinking events whose {@code [eventStartAt, eventEndAt]} interval
     * overlaps the window. Intervals are passed raw (start..trough): the
     * kernel appends the post-drinking recovery window itself. The lower
     * bound is widened by the recovery window so an event that troughed just
     * before the window still covers window-edge samples.
     */
    private List<BaselineExclusionWindow> drinkingWindows(Long livestockId, Instant windowStart, Instant asOf) {
        Instant from = windowStart.minus(Duration.ofMinutes(properties.getDrinkingRecoveryWindowMin()));
        return drinkingEventJpaRepository
                .findByLivestockIdAndEventStartAtLessThanAndEventEndAtGreaterThanEqual(livestockId, asOf, from)
                .stream()
                .map(event -> new BaselineExclusionWindow(event.getEventStartAt(), event.getEventEndAt()))
                .toList();
    }
}
