package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingDaily;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingDayCount;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingDayEvent;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingPeerComparisonResponse;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingRollingBaseline;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingSummaryResponse;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingWeekly;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.ExclusionWindow;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyStage;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyStageType;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.TreeMap;

/**
 * Aggregation service for the drinking UI (NIX-256 Task 5a): the
 * three-layer per-cow summary (spec §4/F4) and the Premium peer
 * comparison (§4 group definition).
 *
 * <p><b>Cow-day</b> = Asia/Shanghai calendar day (F5), shared with the
 * detector via {@link DrinkingEventDetectionService#COW_DAY_ZONE}. All
 * counting views filter rows through {@link DrinkingEventService#isCounted}
 * (§15.3 revised: detected count by default, REJECTED never counts, manual
 * back-fills count, candidates count only after confirmation).
 *
 * <p><b>Two aggregation layers (F4)</b>: weekly bars/sums add each day's
 * counted events directly (fever-day lows stay — that is real physiology,
 * the context note explains it); the 30-day baseline and the peer average
 * instead average over <b>sample days</b> only.
 *
 * <p><b>Sample day</b> (pinned in this task, threshold configurable): a
 * cow-day with at least {@code health.drinking.sample-day-min-points}
 * temperature points (all devices of the livestock) and fever coverage
 * strictly below 50%. Fever coverage reuses the detector's buffered
 * exclusion windows (physiology windows ∪ TEMPERATURE_ABNORMAL alerts +
 * 6h defervescence buffer) via {@link DrinkingEventDetectionService#feverWindowsForLivestock}
 * — one assembly, so detection and statistics cannot drift.
 *
 * <p>The judging pieces are package-visible static pure functions (no
 * Spring, no IO) — same convention as the detection kernel — while the
 * instance methods are a thin query shell.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DrinkingSummaryService {

    /** Ranch operating timezone; cow-day boundary (F5). */
    private static final ZoneId COW_DAY_ZONE = DrinkingEventDetectionService.COW_DAY_ZONE;
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ISO_LOCAL_DATE;

    /** Fever coverage at/above which a day leaves the baseline (F4: 剔除 ≥50%). */
    static final double FEVER_EXCLUDED_PERCENT = 50.0;

    /** Sample days a peer must contribute before joining the average (§4). */
    static final int MIN_SAMPLE_DAYS = 5;

    private final DrinkingEventJpaRepository eventRepository;
    private final TemperatureLogJpaRepository temperatureLogRepository;
    private final DrinkingEventDetectionService detectionService;
    private final DrinkingPeerAccessGuard peerAccessGuard;
    private final RanchQueryPort ranchQueryPort;
    private final PhysiologyQueryPort physiologyQueryPort;

    /**
     * Minimum temperature points for a cow-day to count as a sample day
     * (task-pinned definition, made configurable): 24 points ≈ hourly
     * sampling, i.e. the day is actually observable.
     */
    @Value("${health.drinking.sample-day-min-points:24}")
    int sampleDayMinPoints = 24;

    /**
     * Sample days a cow needs before the 30-day baseline counts as
     * established (spec §4 {@code baseline-min-days}); served on every
     * summary response so the Flutter "baseline building n/3" chip reads
     * the server threshold instead of a front-end mirror (F3).
     */
    @Value("${health.drinking.baseline-min-days:3}")
    int baselineMinDays = 3;

    // ════════════════════════════════════════════════════════════
    // Kernel — package-visible static pure functions
    // ════════════════════════════════════════════════════════════

    /** Counted (§15.3) events per cow-day of {@code event_start_at}. */
    static Map<LocalDate, Integer> countedPerDay(List<DrinkingEventJpaEntity> rows, ZoneId zone) {
        Map<LocalDate, Integer> counts = new TreeMap<>();
        for (DrinkingEventJpaEntity row : rows) {
            if (!DrinkingEventService.isCounted(row)) {
                continue;
            }
            LocalDate day = LocalDate.ofInstant(row.getEventStartAt(), zone);
            counts.merge(day, 1, Integer::sum);
        }
        return counts;
    }

    /**
     * Merge overlapping/adjacent windows so overlapping physiology and
     * alert windows cannot double-count coverage minutes; an open window
     * ({@code end == null}) swallows everything after its start.
     */
    static List<ExclusionWindow> mergeWindows(List<ExclusionWindow> windows) {
        if (windows.size() <= 1) {
            return windows;
        }
        List<ExclusionWindow> sorted = windows.stream()
                .sorted(Comparator.comparing(ExclusionWindow::start))
                .toList();
        List<ExclusionWindow> merged = new ArrayList<>();
        for (ExclusionWindow window : sorted) {
            ExclusionWindow last = merged.isEmpty() ? null : merged.get(merged.size() - 1);
            if (last != null && (last.end() == null || !window.start().isAfter(last.end()))) {
                merged.set(merged.size() - 1, new ExclusionWindow(last.start(), latestEnd(last, window)));
            } else {
                merged.add(window);
            }
        }
        return merged;
    }

    private static Instant latestEnd(ExclusionWindow a, ExclusionWindow b) {
        if (a.end() == null || b.end() == null) {
            return null;
        }
        return a.end().isAfter(b.end()) ? a.end() : b.end();
    }

    /**
     * Fever coverage of one cow-day: merged buffered-window minutes
     * intersecting the day over 1440, in percent. Open windows clamp at
     * the day boundary.
     */
    static double feverCoveredPercent(List<ExclusionWindow> bufferedWindows, LocalDate day, ZoneId zone) {
        if (bufferedWindows.isEmpty()) {
            return 0.0;
        }
        Instant dayStart = day.atStartOfDay(zone).toInstant();
        Instant dayEnd = day.plusDays(1).atStartOfDay(zone).toInstant();
        long coveredMinutes = 0;
        for (ExclusionWindow window : mergeWindows(bufferedWindows)) {
            Instant from = window.start().isBefore(dayStart) ? dayStart : window.start();
            Instant to = window.end() == null || window.end().isAfter(dayEnd) ? dayEnd : window.end();
            if (from.isBefore(to)) {
                coveredMinutes += Duration.between(from, to).toMinutes();
            }
        }
        return coveredMinutes * 100.0 / 1440.0;
    }

    /** Sample-day rule: enough points AND fever coverage strictly below the exclusion line. */
    static boolean isSampleDay(long pointCount, double feverCoveredPercent, int minPoints) {
        return pointCount >= minPoints && feverCoveredPercent < FEVER_EXCLUDED_PERCENT;
    }

    private static BigDecimal scale(double value) {
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP);
    }

    private static BigDecimal percent(double value) {
        return BigDecimal.valueOf(value).setScale(1, RoundingMode.HALF_UP);
    }

    // ════════════════════════════════════════════════════════════
    // Shell — endpoint 2: drinking-summary
    // ════════════════════════════════════════════════════════════

    /**
     * Three-layer summary (3c tracing table). {@code date} defaults to
     * today (Shanghai), {@code days} to 7; valid days are 1 / 7 / 30.
     * Layers are computed independently: daily for the {@code date} cow-day;
     * weekly (days=7) sums the counted events of the last 7 days including
     * {@code date}; rolling30dBaseline (days=30) averages over sample days.
     */
    @Transactional(readOnly = true)
    public DrinkingSummaryResponse summary(Long farmId, Long livestockId, String date, Integer days) {
        requireLivestockInFarm(farmId, livestockId);
        int resolvedDays = resolveDays(days);
        LocalDate targetDay = resolveTargetDay(date);
        LocalDate firstDay = targetDay.minusDays(resolvedDays - 1L);
        Instant windowFrom = dayStart(firstDay);
        Instant windowTo = dayStart(targetDay.plusDays(1));

        List<DrinkingEventJpaEntity> rows = eventRepository
                .findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                        livestockId, windowFrom, windowTo);
        Map<LocalDate, Integer> counts = countedPerDay(rows, COW_DAY_ZONE);

        DrinkingDaily daily = buildDaily(targetDay, rows);

        DrinkingWeekly weekly = null;
        DrinkingRollingBaseline baseline = null;
        List<DrinkingDayCount> dayCounts = null;
        if (resolvedDays == 7) {
            // dayCounts need the fever marker even though the weekly sum
            // itself counts fever days as-is (F4 layer 1).
            List<ExclusionWindow> feverWindows =
                    detectionService.feverWindowsForLivestock(livestockId, windowFrom, windowTo);
            int weekCount = 0;
            List<DrinkingDayCount> bars = new ArrayList<>(7);
            for (LocalDate day = firstDay; !day.isAfter(targetDay); day = day.plusDays(1)) {
                int dayCount = counts.getOrDefault(day, 0);
                weekCount += dayCount; // F4 layer 1: direct sum, fever lows stay
                bars.add(dayBar(day, dayCount, feverWindows));
            }
            weekly = new DrinkingWeekly(weekCount, scale(weekCount / 7.0));
            dayCounts = bars;
        } else if (resolvedDays == 30) {
            List<ExclusionWindow> feverWindows =
                    detectionService.feverWindowsForLivestock(livestockId, windowFrom, windowTo);
            int sampleDays = 0;
            int countedOnSampleDays = 0;
            List<DrinkingDayCount> bars = new ArrayList<>(30);
            for (LocalDate day = firstDay; !day.isAfter(targetDay); day = day.plusDays(1)) {
                int dayCount = counts.getOrDefault(day, 0);
                bars.add(dayBar(day, dayCount, feverWindows));
                double feverPercent = feverCoveredPercent(feverWindows, day, COW_DAY_ZONE);
                long pointCount = temperatureLogRepository
                        .countByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThan(
                                livestockId, dayStart(day), dayStart(day.plusDays(1)));
                if (isSampleDay(pointCount, feverPercent, sampleDayMinPoints)) {
                    sampleDays++;
                    countedOnSampleDays += dayCount;
                }
            }
            baseline = new DrinkingRollingBaseline(
                    sampleDays == 0 ? null : scale(countedOnSampleDays / (double) sampleDays),
                    sampleDays);
            dayCounts = bars;
        }
        return new DrinkingSummaryResponse(targetDay, resolvedDays, daily, weekly, baseline, dayCounts,
                baselineMinDays);
    }

    private static DrinkingDaily buildDaily(LocalDate day, List<DrinkingEventJpaEntity> rows) {
        List<DrinkingEventJpaEntity> counted = rows.stream()
                .filter(DrinkingEventService::isCounted)
                .filter(row -> LocalDate.ofInstant(row.getEventStartAt(), COW_DAY_ZONE).equals(day))
                .sorted(Comparator.comparing(DrinkingEventJpaEntity::getEventStartAt)
                        .thenComparing(DrinkingEventJpaEntity::getEventEndAt))
                .toList();
        List<DrinkingDayEvent> events = counted.stream()
                .map(row -> new DrinkingDayEvent(row.getEventStartAt(), row.getEventEndAt(),
                        row.getTempDrop(), row.getLabel().name(), row.getConfidence(), row.getSource()))
                .toList();
        Instant lastDrinkEndAt = counted.isEmpty() ? null
                : counted.get(counted.size() - 1).getEventEndAt();
        return new DrinkingDaily(counted.size(), events, lastDrinkEndAt);
    }

    private static DrinkingDayCount dayBar(LocalDate day, int count, List<ExclusionWindow> feverWindows) {
        return new DrinkingDayCount(day, count,
                percent(feverCoveredPercent(feverWindows, day, COW_DAY_ZONE)));
    }

    private static Instant dayStart(LocalDate day) {
        return day.atStartOfDay(COW_DAY_ZONE).toInstant();
    }

    private int resolveDays(Integer days) {
        int resolved = days == null ? 7 : days;
        if (resolved != 1 && resolved != 7 && resolved != 30) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.requestInvalid");
        }
        return resolved;
    }

    private static LocalDate resolveTargetDay(String date) {
        LocalDate today = LocalDate.now(COW_DAY_ZONE);
        LocalDate target = today;
        if (date != null && !date.isBlank()) {
            try {
                target = LocalDate.parse(date.trim(), DATE_FORMAT);
            } catch (DateTimeParseException exception) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.rangeInvalid");
            }
        }
        // Same window semantics as the admin recalculation: days that have
        // not happened yet carry no statistics.
        if (target.isAfter(today)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.futureDate");
        }
        return target;
    }

    // ════════════════════════════════════════════════════════════
    // Shell — endpoint 3: drinking-peer-comparison (Premium)
    // ════════════════════════════════════════════════════════════

    /**
     * Premium peer comparison. Group = same farm + same breed
     * ({@code livestock.breed}) + same physiology stage
     * ({@code currentStage} type or null), each peer contributing its last
     * 30 days. A peer joins the average only with ≥{@value MIN_SAMPLE_DAYS}
     * sample days (spec §4 group definition — no member is exempt, the
     * target included): the pool is the qualified peers alone, so the
     * "peer average" never contains the animal it is compared against.
     * With no qualifying peer the endpoint answers 200 with
     * {@code peerAvgPerDay=null, reason=INSUFFICIENT_PEERS} — a degraded
     * state, not an error (the target's own data never rescues the group).
     */
    @Transactional(readOnly = true)
    public DrinkingPeerComparisonResponse peerComparison(Long farmId, Long livestockId) {
        peerAccessGuard.requirePeerComparison();
        LivestockInfo target = requireLivestockInFarm(farmId, livestockId);
        String targetStage = stageName(livestockId).orElse(null);

        LocalDate today = LocalDate.now(COW_DAY_ZONE);
        LocalDate firstDay = today.minusDays(29);
        Instant windowFrom = dayStart(firstDay);
        Instant windowTo = dayStart(today.plusDays(1));

        List<LivestockInfo> group = ranchQueryPort.findAllByFarmId(farmId).stream()
                .filter(info -> Objects.equals(info.breed(), target.breed()))
                .filter(info -> Objects.equals(stageName(info.id()).orElse(null), targetStage))
                .toList();
        Map<Long, List<ExclusionWindow>> feverWindowsByLivestock =
                detectionService.feverWindowsByFarm(farmId, windowFrom, windowTo);

        List<MemberStats> qualifiedPeers = new ArrayList<>();
        for (LivestockInfo member : group) {
            // The target is not a peer of itself: its rows never enter the
            // pool or the denominator ("同类均值" compares against others).
            if (member.id().equals(livestockId)) {
                continue;
            }
            MemberStats stats = memberStats(member.id(), windowFrom, windowTo, today, firstDay,
                    feverWindowsByLivestock.getOrDefault(member.id(), List.of()));
            if (stats.sampleDays() >= MIN_SAMPLE_DAYS) {
                qualifiedPeers.add(stats);
            }
        }

        if (qualifiedPeers.isEmpty()) {
            return new DrinkingPeerComparisonResponse(null, "INSUFFICIENT_PEERS",
                    target.breed(), targetStage, 0, 0, MIN_SAMPLE_DAYS);
        }

        // Pool = qualified peers only; the target's own sample days never
        // dilute or skew the average it is being compared against.
        int sampleDaysTotal = qualifiedPeers.stream().mapToInt(MemberStats::sampleDays).sum();
        int countedTotal = qualifiedPeers.stream().mapToInt(MemberStats::countedOnSampleDays).sum();
        BigDecimal peerAvgPerDay = scale(countedTotal / (double) sampleDaysTotal);
        return new DrinkingPeerComparisonResponse(peerAvgPerDay, null,
                target.breed(), targetStage, qualifiedPeers.size(), sampleDaysTotal, MIN_SAMPLE_DAYS);
    }

    /** Per-member 30-day window statistics: sample days and counted events on them. */
    private MemberStats memberStats(Long livestockId, Instant windowFrom, Instant windowTo,
                                    LocalDate today, LocalDate firstDay, List<ExclusionWindow> feverWindows) {
        Map<LocalDate, Integer> counts = countedPerDay(eventRepository
                .findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                        livestockId, windowFrom, windowTo), COW_DAY_ZONE);
        int sampleDays = 0;
        int countedOnSampleDays = 0;
        for (LocalDate day = firstDay; !day.isAfter(today); day = day.plusDays(1)) {
            double feverPercent = feverCoveredPercent(feverWindows, day, COW_DAY_ZONE);
            long pointCount = temperatureLogRepository
                    .countByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThan(
                            livestockId, dayStart(day), dayStart(day.plusDays(1)));
            if (isSampleDay(pointCount, feverPercent, sampleDayMinPoints)) {
                sampleDays++;
                countedOnSampleDays += counts.getOrDefault(day, 0);
            }
        }
        return new MemberStats(livestockId, sampleDays, countedOnSampleDays);
    }

    /** One group member's contribution to the peer average. */
    private record MemberStats(Long livestockId, int sampleDays, int countedOnSampleDays) {}

    private Optional<String> stageName(Long livestockId) {
        return physiologyQueryPort.currentStage(livestockId)
                .map(PhysiologyStage::type)
                .map(PhysiologyStageType::name);
    }

    // ── Validation helpers ──────────────────────────────────────

    private LivestockInfo requireLivestockInFarm(Long farmId, Long livestockId) {
        return ranchQueryPort.findLivestockById(livestockId)
                .filter(info -> info.farmId().equals(farmId))
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.drinking.livestockNotFound"));
    }
}
