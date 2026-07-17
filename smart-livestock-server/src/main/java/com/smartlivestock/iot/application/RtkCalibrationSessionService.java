package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.CalibrationStatus;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
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
@Service("rtkCalibrationSessionService")
@RequiredArgsConstructor
public class RtkCalibrationSessionService {

    private static final long MAX_BACKFILL_DAYS = 7;

    private final GpsQualityTestRepository sessionRepository;
    private final RtkReferencePointRepository rtkPointRepository;
    private final DynamicTestRouteRepository routeRepository;
    private final DeviceRepository deviceRepository;

    public Page<GpsQualityTest> findFiltered(Long rtkPointId, Long deviceId, String status, String testType, Pageable pageable) {
        return sessionRepository.findFiltered(rtkPointId, deviceId, status, testType, pageable);
    }

    public GpsQualityTest findById(Long id) {
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
     * Create a static calibration session (single RTK truth point).
     *
     * @param endedAt null = live session (IN_PROGRESS); non-null = backfill (COMPLETED)
     */
    public GpsQualityTest create(Long rtkPointId, Long deviceId, Instant startedAt, Instant endedAt) {
        // --- S5: static truth reference validation ---
        if (rtkPointId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "rtkPointId is required");
        }
        if (!rtkPointRepository.existsById(rtkPointId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "RTK point not found: " + rtkPointId);
        }
        // shared device-type + backfill/live + overlap validation
        validateDeviceAndTimeWindow(deviceId, startedAt, endedAt);

        boolean backfill = endedAt != null;
        GpsQualityTest session = new GpsQualityTest(rtkPointId, deviceId, startedAt);
        if (backfill) {
            session.setEndedAt(endedAt);
            session.setStatus(CalibrationStatus.COMPLETED);
        }
        return sessionRepository.save(session);
    }

    /**
     * Create a dynamic test session (device traverses an ordered route).
     *
     * @param routeId   truth route (must exist)
     * @param deviceId  device under test (must be TRACKER)
     * @param startedAt test start
     * @param endedAt   null = live session (IN_PROGRESS); non-null = backfill (COMPLETED)
     */
    public GpsQualityTest createDynamic(Long routeId, Long deviceId, Instant startedAt, Instant endedAt) {
        // --- S5: dynamic truth reference validation ---
        if (routeId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "routeId is required");
        }
        if (!routeRepository.existsById(routeId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Route not found: " + routeId);
        }
        // shared device-type + backfill/live + overlap validation
        validateDeviceAndTimeWindow(deviceId, startedAt, endedAt);

        boolean backfill = endedAt != null;
        GpsQualityTest test = new GpsQualityTest(TestType.DYNAMIC, null, routeId, deviceId, startedAt);
        if (backfill) {
            test.setEndedAt(endedAt);
            test.setStatus(CalibrationStatus.COMPLETED);
        }
        return sessionRepository.save(test);
    }

    public GpsQualityTest end(Long id) {
        GpsQualityTest session = findById(id);
        session.end();
        return sessionRepository.save(session);
    }

    public GpsQualityTest cancel(Long id) {
        GpsQualityTest session = findById(id);
        if (session.getStatus() == CalibrationStatus.IN_PROGRESS) {
            // Live session → soft cancel (preserve audit trail)
            session.cancel();
            return sessionRepository.save(session);
        }
        // COMPLETED or CANCELED → hard delete (admin cleanup)
        sessionRepository.deleteById(id);
        return session;
    }

   /**
    * Shared S5 + S1 validation for device type, started_at, backfill/live rules,
     * and time-window non-overlap. Used by both static ({@code create}) and
     * dynamic ({@code createDynamic}) test creation.
     */
    private void validateDeviceAndTimeWindow(Long deviceId, Instant startedAt, Instant endedAt) {
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
            if (endedAt.isAfter(Instant.now())) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "endedAt cannot be in the future. Use a live session (no endedAt) for ongoing tests.");
            }
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
   }
}
