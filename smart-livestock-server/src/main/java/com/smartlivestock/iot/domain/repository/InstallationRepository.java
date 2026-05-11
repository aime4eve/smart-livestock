package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.Installation;

import java.util.List;
import java.util.Optional;

public interface InstallationRepository {
    Installation save(Installation installation);
    Optional<Installation> findActiveByDeviceId(Long deviceId);
    List<Installation> findByLivestockId(Long livestockId);
    Optional<Installation> findActiveByLivestockId(Long livestockId);
}
