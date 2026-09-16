package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DeviceProfileRule;

import java.util.List;
import java.util.Optional;

public interface DeviceProfileRuleRepository {

    DeviceProfileRule save(DeviceProfileRule rule);

    Optional<DeviceProfileRule> findById(Long id);

    List<DeviceProfileRule> findAllOrderedByName();

    Optional<DeviceProfileRule> findByProfileName(String profileName);

    boolean existsByProfileName(String profileName);

    void deleteById(Long id);
}
