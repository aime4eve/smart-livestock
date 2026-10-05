package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingRecalcResponse;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.RecalcStats;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

/**
 * Recalculation orchestration shared by the nightly batch and the admin
 * manual endpoint (NIX-256 Task 4): resolves the farm universe (farms with
 * active capsule bindings), sweeps them with per-farm failure isolation,
 * and aggregates {@link RecalcStats} into batch summaries.
 *
 * <p>The per-farm loop must live <b>outside</b>
 * {@link DrinkingEventDetectionService}: each {@code recalculateFarm} call
 * needs its own transaction (a same-bean self-invocation would silently
 * bypass the @Transactional proxy), and one farm's failure must not roll
 * back or abort the others.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DrinkingRecalculationService {

    /** Admin request date format: calendar days in Asia/Shanghai. */
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ISO_LOCAL_DATE;

    private final DrinkingEventDetectionService detectionService;
    private final DeviceQueryPort deviceQueryPort;
    private final RanchQueryPort ranchQueryPort;

    /** Half-open recalculation window [from, to). */
    public record RecalcWindow(Instant from, Instant to) {}

    /** Farm-sweep aggregate: farm total, devices/events written, failures. */
    public record FarmSweep(int farms, int devices, int events, int failedFarms) {}

    // ════════════════════════════════════════════════════════════
    // Admin manual entry (synchronous; a 30-day full-herd replay can
    // run for minutes — the caller owns the timeout, T6 included)
    // ════════════════════════════════════════════════════════════

    /**
     * Manual back-computation. With {@code deviceId}: one device (must
     * exist — removed capsules are valid, their history recalculates
     * against the old owner, F6). Without: every farm with active capsule
     * bindings (P5; the T6 30-day replay reuses this mode).
     */
    public DrinkingRecalcResponse recalculate(Long deviceId, String from, String to) {
        RecalcWindow window = parseWindow(from, to);
        long startedAt = System.currentTimeMillis();
        if (deviceId != null) {
            requireDeviceExists(deviceId);
            log.info("Drinking manual recalculation started: mode=device, device={}, window=[{}, {})",
                    deviceId, window.from(), window.to());
            RecalcStats stats = detectionService.recalculateDevice(deviceId, window.from(), window.to());
            log.info("Drinking manual recalculation finished: mode=device, device={}, devices={}, events={}, took {} ms",
                    deviceId, stats.devices(), stats.events(), System.currentTimeMillis() - startedAt);
            return new DrinkingRecalcResponse("DEVICE", null, stats.devices(), stats.events(), 0);
        }
        log.info("Drinking manual recalculation started: mode=all-farms, window=[{}, {})",
                window.from(), window.to());
        FarmSweep sweep = recalculateAllFarms(window.from(), window.to());
        log.info("Drinking manual recalculation finished: mode=all-farms, farms={} (failed={}), devices={}, events={}, took {} ms",
                sweep.farms(), sweep.failedFarms(), sweep.devices(), sweep.events(),
                System.currentTimeMillis() - startedAt);
        return new DrinkingRecalcResponse("ALL_FARMS", sweep.farms(), sweep.devices(), sweep.events(),
                sweep.failedFarms());
    }

    // ════════════════════════════════════════════════════════════
    // Farm sweep — shared by the nightly scheduler and admin replay
    // ════════════════════════════════════════════════════════════

    /**
     * Recalculate {@code [from, to)} on every farm with active capsule
     * bindings. One farm's failure is logged and skipped — a batch must
     * not die of a single farm (each farm runs in its own transaction).
     */
    public FarmSweep recalculateAllFarms(Instant from, Instant to) {
        Set<Long> farmIds = farmsWithActiveCapsuleBindings();
        int devices = 0;
        int events = 0;
        int failed = 0;
        for (Long farmId : farmIds) {
            try {
                RecalcStats stats = detectionService.recalculateFarm(farmId, from, to);
                devices += stats.devices();
                events += stats.events();
            } catch (Exception e) {
                failed++;
                log.error("Drinking recalculation failed for farm {}: {}", farmId, e.getMessage(), e);
            }
        }
        return new FarmSweep(farmIds.size(), devices, events, failed);
    }

    /**
     * Farms having at least one active capsule binding, sorted for a stable
     * batch order. Bindings whose livestock was soft-deleted resolve to no
     * farm — consistent with {@code recalculateFarm}, whose own universe
     * ({@code RanchQueryPort.findAllByFarmId}) also excludes them.
     */
    public Set<Long> farmsWithActiveCapsuleBindings() {
        List<CapsuleBinding> bindings = deviceQueryPort.findAllActiveCapsuleBindings();
        if (bindings.isEmpty()) {
            return Set.of();
        }
        Set<Long> livestockIds = bindings.stream()
                .map(CapsuleBinding::livestockId)
                .collect(Collectors.toSet());
        return ranchQueryPort.findAllById(livestockIds).stream()
                .map(LivestockInfo::farmId)
                .collect(Collectors.toCollection(TreeSet::new));
    }

    // ── Admin request parsing / validation ──────────────────────

    /**
     * {@code from}/{@code to} are calendar days in Asia/Shanghai; the
     * window is the <b>closed date range</b> from-day 00:00 → to+1 day
     * 00:00. Rules: both required and well-formed ({@code from ≤ to}
     * included), and {@code to} must not be in the future (recalculating
     * days that have not happened yet is meaningless).
     */
    static RecalcWindow parseWindow(String from, String to) {
        LocalDate fromDate = parseDay(from);
        LocalDate toDate = parseDay(to);
        if (fromDate == null || toDate == null || fromDate.isAfter(toDate)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.rangeInvalid");
        }
        if (toDate.isAfter(LocalDate.now(DrinkingEventDetectionService.COW_DAY_ZONE))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.futureDate");
        }
        Instant fromInstant = fromDate.atStartOfDay(DrinkingEventDetectionService.COW_DAY_ZONE).toInstant();
        Instant toInstant = toDate.plusDays(1).atStartOfDay(DrinkingEventDetectionService.COW_DAY_ZONE).toInstant();
        return new RecalcWindow(fromInstant, toInstant);
    }

    private static LocalDate parseDay(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim(), DATE_FORMAT);
        } catch (DateTimeParseException exception) {
            return null;
        }
    }

    private void requireDeviceExists(Long deviceId) {
        if (!deviceQueryPort.deviceExists(deviceId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.drinking.deviceNotFound");
        }
    }
}
