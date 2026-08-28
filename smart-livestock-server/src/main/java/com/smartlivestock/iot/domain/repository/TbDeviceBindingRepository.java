package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.TbDeviceBinding;

import java.util.List;
import java.util.Optional;

public interface TbDeviceBindingRepository {

    TbDeviceBinding save(TbDeviceBinding binding);

    Optional<TbDeviceBinding> findById(Long id);

    List<TbDeviceBinding> findByStatus(TbDeviceBinding.Status status);

    Optional<TbDeviceBinding> findByDeviceIdAndProvider(Long deviceId, String provider);

    boolean existsByDeviceIdAndProvider(Long deviceId, String provider);
}
