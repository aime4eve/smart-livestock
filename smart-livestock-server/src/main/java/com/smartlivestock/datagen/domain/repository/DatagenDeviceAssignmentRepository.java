package com.smartlivestock.datagen.domain.repository;

import com.smartlivestock.datagen.domain.model.DatagenDeviceAssignment;

import java.util.List;
import java.util.Optional;

public interface DatagenDeviceAssignmentRepository {
    DatagenDeviceAssignment save(DatagenDeviceAssignment assignment);
    List<DatagenDeviceAssignment> saveAll(Iterable<DatagenDeviceAssignment> assignments);
    List<DatagenDeviceAssignment> findByControlId(Long controlId);
    Optional<DatagenDeviceAssignment> findByControlIdAndDeviceId(Long controlId, Long deviceId);
    List<DatagenDeviceAssignment> findActiveByControlId(Long controlId);
    List<DatagenDeviceAssignment> findActiveByScenarioId(Long scenarioId);
}
