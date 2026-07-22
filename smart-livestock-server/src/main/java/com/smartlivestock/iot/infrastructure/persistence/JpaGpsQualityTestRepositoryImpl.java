package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityTestJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualityTestRepositoryImpl implements GpsQualityTestRepository {

    private final SpringDataGpsQualityTestRepository springDataRepo;

    @Override
    public GpsQualityTest save(GpsQualityTest test) {
        GpsQualityTestJpaEntity jpa = toJpa(test);
        if (test.getId() != null) {
            springDataRepo.findById(test.getId())
                    .ifPresent(existing -> jpa.setCreatedAt(existing.getCreatedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<GpsQualityTest> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public List<GpsQualityTest> findByRtkPointId(Long rtkPointId) {
        return springDataRepo.findByRtkPointId(rtkPointId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityTest> findByDeviceIdOrderByStartedAt(Long deviceId) {
        return springDataRepo.findByDeviceIdOrderByStartedAt(deviceId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public boolean existsByEuiAndTimeRange(String eui, Instant startedAt, String testType) {
        return springDataRepo.existsByEuiAndTimeRange(eui, startedAt, testType);
    }

    @Override
    public boolean existsTrajectoryWindow(String deviceCode, Instant startedAt, Instant endedAt) {
        return springDataRepo.existsByDeviceCodeAndTestTypeAndStartedAtAndEndedAt(
                deviceCode, "TRAJECTORY", startedAt, endedAt);
    }


    @Override
    public List<GpsQualityTest> findByBatchImportId(Long batchImportId) {
        return springDataRepo.findByBatchImportId(batchImportId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityTest> findByStatus(String status) {
        return springDataRepo.findByStatus(status).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityTest> findByStatusAndTenantId(String status, Long tenantId) {
        return springDataRepo.findByStatusAndTenantId(status, tenantId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityTest> findByRouteIdAndStatus(Long routeId, String status) {
        return springDataRepo.findByRouteIdAndStatus(routeId, status).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public void deleteById(Long id) { springDataRepo.deleteById(id); }

    @Override
    public int deleteByDeviceId(Long deviceId) { return springDataRepo.deleteByDeviceId(deviceId); }

    @Override
    public List<GpsQualityTest> findFiltered(String status, String eui, Long deviceId, int offset, int limit) {
        String safeStatus = (status != null && !status.isBlank()) ? status : "";
        String safeEui = (eui != null && !eui.isBlank()) ? eui : "";
        Long safeDeviceId = deviceId != null ? deviceId : 0L;
        PageRequest pageable = PageRequest.of(limit > 0 ? offset / limit : 0, Math.max(1, limit));
        return springDataRepo.findByFilters(safeStatus, safeDeviceId, safeEui, pageable).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public long countFiltered(String status, String eui, Long deviceId) {
        String safeStatus = (status != null && !status.isBlank()) ? status : "";
        String safeEui = (eui != null && !eui.isBlank()) ? eui : "";
        Long safeDeviceId = deviceId != null ? deviceId : 0L;
        return springDataRepo.countByFilters(safeStatus, safeDeviceId, safeEui);
    }

    private GpsQualityTestJpaEntity toJpa(GpsQualityTest t) {
        GpsQualityTestJpaEntity jpa = new GpsQualityTestJpaEntity();
        jpa.setId(t.getId());
        jpa.setDeviceCode(t.getDeviceCode());
        jpa.setDeviceId(t.getDeviceId());
        jpa.setTestType(t.getTestType() != null ? t.getTestType().name() : TestType.STATIC.name());
        jpa.setRtkPointId(t.getRtkPointId());
        jpa.setRouteId(t.getRouteId());
        jpa.setStartedAt(t.getStartedAt());
        jpa.setEndedAt(t.getEndedAt());
        jpa.setStatus(t.getStatus());
        jpa.setErrorMessage(t.getErrorMessage());
        jpa.setNote(t.getNote());
        jpa.setBatchImportId(t.getBatchImportId());
        return jpa;
    }

    private GpsQualityTest toDomain(GpsQualityTestJpaEntity jpa) {
        GpsQualityTest t = new GpsQualityTest();
        t.setId(jpa.getId());
        t.setDeviceCode(jpa.getDeviceCode());
        t.setDeviceId(jpa.getDeviceId());
        t.setTestType(jpa.getTestType() != null ? TestType.valueOf(jpa.getTestType()) : TestType.STATIC);
        t.setRtkPointId(jpa.getRtkPointId());
        t.setRouteId(jpa.getRouteId());
        t.setStartedAt(jpa.getStartedAt());
        t.setEndedAt(jpa.getEndedAt());
        t.setStatus(jpa.getStatus());
        t.setErrorMessage(jpa.getErrorMessage());
        t.setNote(jpa.getNote());
        t.setBatchImportId(jpa.getBatchImportId());
        t.setCreatedAt(jpa.getCreatedAt());
        t.setUpdatedAt(jpa.getUpdatedAt());
        return t;
    }
}
