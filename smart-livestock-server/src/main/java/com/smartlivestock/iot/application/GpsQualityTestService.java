package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GpsQualitySession;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.SessionStatus;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.domain.repository.GpsQualitySessionRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service("gpsQualityTestService")
@RequiredArgsConstructor
public class GpsQualityTestService {

    private final GpsQualityTestRepository testRepository;
    private final GpsQualitySessionRepository sessionRepository;
    private final DynamicTestRouteRepository routeRepository;

    public GpsQualityTest create(Long sessionId, TestType testType, Long rtkPointId, Long routeId,
                                  Instant testStartedAt, Instant testEndedAt) {
        GpsQualitySession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Session not found: " + sessionId));

        if (testType == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "testType is required");
        }
        if (testStartedAt == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "testStartedAt is required");
        }

        // Validate sub-range is within session window
        if (testStartedAt.isBefore(session.getStartedAt())) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "testStartedAt is before session start: " + session.getStartedAt());
        }
        if (session.getEndedAt() != null && testEndedAt != null && testEndedAt.isAfter(session.getEndedAt())) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "testEndedAt is after session end: " + session.getEndedAt());
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

        GpsQualityTest test = new GpsQualityTest(sessionId, testType, rtkPointId, routeId, testStartedAt);
        test.setTestEndedAt(testEndedAt);
        return testRepository.save(test);
    }

    public GpsQualityTest findById(Long id) {
        return testRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "Test not found: " + id));
    }

    public List<GpsQualityTest> findBySessionId(Long sessionId) {
        return testRepository.findBySessionId(sessionId);
    }

    public Page<GpsQualityTest> findFiltered(Long rtkPointId, Long routeId, String testType, Pageable pageable) {
        return testRepository.findFiltered(rtkPointId, routeId, testType, pageable);
    }

    public void deleteById(Long id) {
        testRepository.deleteById(id);
    }
}
