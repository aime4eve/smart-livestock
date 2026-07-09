package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;

import java.util.List;
import java.util.Optional;

public interface AlertRepository {
    Alert save(Alert alert);
    Optional<Alert> findById(Long id);
    List<Alert> findByFarmId(Long farmId);
    List<Alert> findByFarmIdAndStatus(Long farmId, AlertStatus status);
    List<Alert> findByLivestockIdAndTypeAndStatus(Long livestockId, AlertType type, AlertStatus status);
    List<Alert> findByDeviceIdAndTypeAndStatus(Long deviceId, AlertType type, AlertStatus status);
}
