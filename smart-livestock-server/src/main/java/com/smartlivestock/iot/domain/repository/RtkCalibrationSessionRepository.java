package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.RtkCalibrationSession;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

public interface RtkCalibrationSessionRepository {
    RtkCalibrationSession save(RtkCalibrationSession session);
    Optional<RtkCalibrationSession> findById(Long id);

    /** Active (IN_PROGRESS) session for a device, if any. */
    Optional<RtkCalibrationSession> findActiveByDeviceId(Long deviceId);

    List<RtkCalibrationSession> findByRtkPointIdOrderByStartedAtDesc(Long rtkPointId);
    List<RtkCalibrationSession> findByDeviceIdOrderByStartedAtDesc(Long deviceId);

    /** Sessions with optional filters, paged (all params nullable). */
    Page<RtkCalibrationSession> findFiltered(Long rtkPointId, Long deviceId, String status, Pageable pageable);

    List<RtkCalibrationSession> findAll();
    void deleteById(Long id);
}
