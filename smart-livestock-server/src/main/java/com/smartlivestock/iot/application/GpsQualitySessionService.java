package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.GpsQualitySession;
import com.smartlivestock.iot.domain.model.SessionStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GpsQualitySessionRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;

@Service
@RequiredArgsConstructor
public class GpsQualitySessionService {

    private static final int MAX_BACKFILL_DAYS = 30;

    private final GpsQualitySessionRepository sessionRepository;
    private final DeviceRepository deviceRepository;

    public GpsQualitySession create(Long deviceId, Instant startedAt, Instant endedAt) {
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

        GpsQualitySession session = new GpsQualitySession(deviceId, startedAt);
        if (backfill) {
            session.setEndedAt(endedAt);
            session.setStatus(SessionStatus.COMPLETED);
        }
        return sessionRepository.save(session);
    }

    public GpsQualitySession findById(Long id) {
        return sessionRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Session not found: " + id));
    }

    public GpsQualitySession end(Long id) {
        GpsQualitySession session = findById(id);
        session.end();
        return sessionRepository.save(session);
    }

    public GpsQualitySession cancel(Long id) {
        GpsQualitySession session = findById(id);
        if (session.getStatus() == SessionStatus.IN_PROGRESS) {
            session.cancel();
            return sessionRepository.save(session);
        }
        sessionRepository.deleteById(id);
        return session;
    }

    public Page<GpsQualitySession> findFiltered(Long deviceId, String status, Pageable pageable) {
        return sessionRepository.findFiltered(deviceId, status, pageable);
    }
}
