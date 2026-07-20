package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.interfaces.admin.dto.GpsQualityTestDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Manages GpsQualityTest entities directly (no session indirection).
 */
@Service("gpsQualityTestService")
@RequiredArgsConstructor
public class GpsQualityTestService {

    private final GpsQualityTestRepository testRepository;
    private final DynamicTestRouteRepository routeRepository;

    public GpsQualityTest create(String deviceCode, Long deviceId, TestType testType,
                                  Long rtkPointId, Long routeId,
                                  Instant startedAt, Instant endedAt) {
        if (deviceCode == null || deviceCode.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "deviceCode is required");
        }
        if (testType == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "testType is required");
        }
        if (startedAt == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "startedAt is required");
        }

        // Validate truth reference
        if (testType == TestType.STATIC) {
            if (rtkPointId == null) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "rtkPointId is required for STATIC test");
            }
        } else {
            if (routeId == null) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "routeId is required for DYNAMIC test");
            }
            if (!routeRepository.existsById(routeId)) {
                throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Route not found: " + routeId);
            }
        }

        GpsQualityTest test = new GpsQualityTest(deviceCode, testType, rtkPointId, routeId, startedAt);
        test.setDeviceId(deviceId);
        test.setEndedAt(endedAt);
        return testRepository.save(test);
    }

    public GpsQualityTest findById(Long id) {
        return testRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Test not found: " + id));
    }

    public List<GpsQualityTest> findByDeviceId(Long deviceId) {
        return testRepository.findByDeviceIdOrderByStartedAt(deviceId);
    }

    public void deleteById(Long id) {
        testRepository.deleteById(id);
    }

    /**
     * Delete all quality tests of one device (any status). The device record
     * itself is kept; reports are computed on the fly from gps_logs, so no
     * child-table references need cleanup.
     */
    @Transactional
    public int deleteByDeviceId(Long deviceId) {
        return testRepository.deleteByDeviceId(deviceId);
    }

    /**
     * Paginated check list with optional filters.
     */
    public GpsQualityTestPage findChecks(String status, String eui, Long deviceId,
                                          int page, int size) {
        int safePage = Math.max(0, page);
        int safeSize = Math.max(1, Math.min(100, size));
        int offset = safePage * safeSize;
        List<GpsQualityTest> items = testRepository.findFiltered(status, eui, deviceId, offset, safeSize);
        long total = testRepository.countFiltered(status, eui, deviceId);
        return new GpsQualityTestPage(
                items.stream().map(GpsQualityTestDto::from).toList(),
                safePage, safeSize, total);
    }

    public record GpsQualityTestPage(List<GpsQualityTestDto> items, int page, int pageSize, long total) {}
}
