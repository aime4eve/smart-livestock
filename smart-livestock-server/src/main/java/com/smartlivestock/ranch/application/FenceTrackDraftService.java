package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.TrackDraftCandidatesDto;
import com.smartlivestock.ranch.application.dto.TrackDraftSourceDto;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.FenceQuotaPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.DeviceBrief;
import com.smartlivestock.ranch.domain.port.dto.TrackDraftPoint;
import com.smartlivestock.ranch.domain.port.dto.TrackerCandidate;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Read-only orchestration behind the "fence from device track" wizard
 * (spec §4.1/§4.2). No writes, no transactions: candidate listing, hard
 * validation (1-10 devices, farm ownership + TRACKER type, range within 30
 * days), count-then-stride sampling and merge ordering.
 *
 * <p>Cross-context rule: every iot read goes through {@link IoTQueryPort}
 * (the ranch→iot ACL) and the quota limit through {@link FenceQuotaPort}
 * (the ranch→commerce ACL, SceneGatePort pattern); this class never imports
 * iot, commerce or licensing types.</p>
 *
 * <p>Multi-device fetching is deliberately SERIAL (plan ruling ①): at most
 * 10 devices × 2 index-backed queries each, far inside the 15 s budget,
 * avoiding executor lifecycle / transaction boundary / exception wrapping
 * risks of a fan-out.</p>
 */
@Service
public class FenceTrackDraftService {

    static final int MAX_DEVICES = 10;
    static final int MAX_RANGE_DAYS = 30;
    static final long MAX_RETURNED_POINTS = 5000;

    private final IoTQueryPort ioTQueryPort;
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;
    private final FenceQuotaPort fenceQuotaPort;

    public FenceTrackDraftService(IoTQueryPort ioTQueryPort,
                                  LivestockRepository livestockRepository,
                                  FenceRepository fenceRepository,
                                  FenceQuotaPort fenceQuotaPort) {
        this.ioTQueryPort = ioTQueryPort;
        this.livestockRepository = livestockRepository;
        this.fenceRepository = fenceRepository;
        this.fenceQuotaPort = fenceQuotaPort;
    }

    /**
     * Tracker candidates for the wizard's first step, plus the farm fence
     * quota (current count + tier/license limit, null = unlimited).
     */
    public TrackDraftCandidatesDto candidates(Long farmId, int days) {
        List<TrackerCandidate> devices = ioTQueryPort.findTrackerCandidates(farmId, days);
        long current = fenceRepository.countByFarmId(farmId);
        Integer limit = fenceQuotaPort.resolveFenceManagementLimitForCurrentTenant();
        return new TrackDraftCandidatesDto(
                devices, new TrackDraftCandidatesDto.FenceQuota(current, limit));
    }

    /**
     * Merged, stride-sampled track points for the selected devices.
     * Validation order: device count → ownership/type → time range.
     */
    public TrackDraftSourceDto source(Long farmId, List<Long> deviceIds, Instant from, Instant to) {
        if (deviceIds == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftTooManyDevices");
        }
        List<Long> distinctIds = deviceIds.stream().distinct().toList();
        if (distinctIds.isEmpty() || distinctIds.size() > MAX_DEVICES) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftTooManyDevices");
        }

        Map<Long, DeviceBrief> farmDevices = farmActiveDeviceMap(farmId);
        for (Long deviceId : distinctIds) {
            DeviceBrief brief = deviceId != null ? farmDevices.get(deviceId) : null;
            if (brief == null || !"TRACKER".equals(brief.deviceType())) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftDeviceNotFound");
            }
        }

        if (from == null || to == null || !from.isBefore(to)
                || Duration.between(from, to).compareTo(Duration.ofDays(MAX_RANGE_DAYS)) > 0) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.trackDraftRangeTooLong");
        }

        List<TrackDraftSourceDto.DeviceRaw> perDevice = new ArrayList<>(distinctIds.size());
        long totalRaw = 0;
        for (Long deviceId : distinctIds) {
            long raw = ioTQueryPort.countTrackPoints(deviceId, from, to);
            perDevice.add(new TrackDraftSourceDto.DeviceRaw(deviceId, raw));
            totalRaw += raw;
        }

        // Ceil division: 5499 raw points need stride 2 so the merged payload
        // stays under the 5000-point transport cap (mirrors NIX-213).
        long stride = Math.max(1, (totalRaw + MAX_RETURNED_POINTS - 1) / MAX_RETURNED_POINTS);

        List<TrackDraftPoint> sampled = new ArrayList<>();
        if (totalRaw > 0) {
            for (Long deviceId : distinctIds) {
                sampled.addAll(ioTQueryPort.sampleTrackPoints(deviceId, from, to, stride));
            }
            sampled.sort(Comparator.comparing(TrackDraftPoint::recordedAt));
        }

        List<TrackDraftSourceDto.Point> points = sampled.stream()
                .map(p -> new TrackDraftSourceDto.Point(p.lat(), p.lng(), p.accuracyM(), p.recordedAt()))
                .toList();
        return new TrackDraftSourceDto(points, totalRaw, perDevice, stride > 1, stride);
    }

    /**
     * Active-installation devices of the farm keyed by deviceId. Ownership
     * and type are judged by the installation chain (installation →
     * livestock → farm), per spec §4.1.
     */
    private Map<Long, DeviceBrief> farmActiveDeviceMap(Long farmId) {
        List<Long> livestockIds = livestockRepository.findByFarmId(farmId).stream()
                .map(Livestock::getId)
                .toList();
        Map<Long, DeviceBrief> byDeviceId = new HashMap<>();
        ioTQueryPort.findActiveDevicesByLivestockIds(livestockIds).values()
                .forEach(briefs -> briefs.forEach(b -> byDeviceId.putIfAbsent(b.deviceId(), b)));
        return byDeviceId;
    }
}
