package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;

import java.util.List;
import java.util.Optional;

public interface InstallationRepository {
    Installation save(Installation installation);
    Optional<Installation> findById(Long id);
    Optional<Installation> findActiveByDeviceId(Long deviceId);
    List<Installation> findByLivestockId(Long livestockId);
    Optional<Installation> findActiveByLivestockId(Long livestockId);
    List<Installation> findAllActiveByLivestockId(Long livestockId);
    Optional<Installation> findActiveByLivestockIdAndDeviceType(Long livestockId, DeviceType deviceType);
    List<Installation> findAllActive();
    List<Installation> findByLivestockIdIn(List<Long> livestockIds);
}
