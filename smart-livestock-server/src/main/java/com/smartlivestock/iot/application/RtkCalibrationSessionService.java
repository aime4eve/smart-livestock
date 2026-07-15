package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.CalibrationStatus;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.RtkCalibrationSession;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.RtkCalibrationSessionRepository;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Lifecycle management for RTK calibration sessions.
 * <p>
 * Creation enforces S5 (request validation) and S1 (time-window non-overlap).
 */
@Service
@RequiredArgsConstructor
public class RtkCalibrationSessionService {

    private static final long MAX_BACKFILL_DAYS = 7;

    private final RtkCalibrationSessionRepository sessionRepository;
    private final RtkReferencePointRepository rtkPointRepository;
    private final DeviceRepository deviceRepository;

    public Page<RtkCalibrationSession> findFiltered(Long rtkPointId, Long deviceId, String status, Pageable pageable) {
        return sessionRepository.findFiltered(rtkPointId, deviceId, status, pageable);
    }

    public RtkCalibrationSession findById(Long id) {
        return sessionRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Calibration session not found: " + id));
    }

    public List<Device> listTrackers() {
        return deviceRepository.findAllTrackers();
    }

    public String resolveDeviceCode(Long deviceId) {
        return deviceRepository.findById(deviceId).map(Device::getDeviceCode).orElse(null);
    }

    public Map<Long, String> deviceCodeMap(List<Long> deviceIds) {
        if (deviceIds == null || deviceIds.isEmpty()) {
            return Map.of();
        }
        return deviceRepository.findAllByIdIn(deviceIds).stream()
                .collect(Collectors.toMap(Device::getId, Device::getDeviceCode));
    }

    /**
     * Create a calibration session.
     *
     * @param endedAt null = live session (IN_PROGRESS); non-null = backfill (COMPLETED)
     */
    public RtkCalibrationSession create(Long rtkPointId, Long deviceId, Instant startedAt, Instant endedAt) {
        // --- S5: request validation ---
        if (rtkPointId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "rtkPointId is required");
        }
        if (!rtkPointRepository.existsById(rtkPointId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "RTK point not found: " + rtkPointId);
        }
        if (deviceId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "deviceId is required");
        }
        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Device not found: " + deviceId));
        if (device.getDeviceType() != DeviceType.TRACKER) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Device must be a TRACKER: " + deviceId);
        }
        if (startedAt == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "startedAt is required");
        }

        boolean backfill = endedAt != null;
        if (backfill) {
            if (!endedAt.isAfter(startedAt)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "endedAt must be after startedAt");
            }
            if (Duration.between(startedAt, endedAt).toDays() > MAX_BACKFILL_DAYS) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "Backfill window must not exceed " + MAX_BACKFILL_DAYS + " days");
            }
        } else {
            // live session: device must have no IN_PROGRESS session
            if (sessionRepository.findActiveByDeviceId(deviceId).isPresent()) {
                throw new ApiException(ErrorCode.STATE_CONFLICT,
                        "Device already has an IN_PROGRESS session: " + deviceId);
            }
        }

        // --- S1: time-window overlap check against all existing device sessions ---
        for (RtkCalibrationSession existing : sessionRepository.findByDeviceIdOrderByStartedAtDesc(deviceId)) {
            if (overlaps(startedAt, endedAt, existing.getStartedAt(), existing.getEndedAt())) {
                throw new ApiException(ErrorCode.STATE_CONFLICT,
                        "Time window overlaps existing session #" + existing.getId());
            }
        }

        RtkCalibrationSession session = new RtkCalibrationSession(rtkPointId, deviceId, startedAt);
        if (backfill) {
            session.setEndedAt(endedAt);
            session.setStatus(CalibrationStatus.COMPLETED);
        }
        return sessionRepository.save(session);
    }

    public RtkCalibrationSession end(Long id) {
        RtkCalibrationSession session = findById(id);
        session.end();
        return sessionRepository.save(session);
    }

    public RtkCalibrationSession cancel(Long id) {
        RtkCalibrationSession session = findById(id);
        session.cancel();
        return sessionRepository.save(session);
    }

    /**
     * Half-open interval overlap test. A null end means open-ended (treated as +infinity).
     */
    private boolean overlaps(Instant newStart, Instant newEnd, Instant existStart, Instant existEnd) {
        boolean newStartBeforeExistEnd = (existEnd == null) || newStart.isBefore(existEnd);
        boolean existStartBeforeNewEnd = (newEnd == null) || existStart.isBefore(newEnd);
        return newStartBeforeExistEnd && existStartBeforeNewEnd;
    }
}
