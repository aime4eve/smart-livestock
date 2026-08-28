package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.TbDeviceBinding;

import java.util.List;
import java.util.Optional;

public interface TbDeviceBindingRepository {

    TbDeviceBinding save(TbDeviceBinding binding);

    Optional<TbDeviceBinding> findById(Long id);

    List<TbDeviceBinding> findByTenantIdAndStatus(Long tenantId, TbDeviceBinding.Status status);

    Optional<TbDeviceBinding> findByDeviceIdAndProvider(Long deviceId, String provider);

    List<TbDeviceBinding> findByTenantIdAndProvider(Long tenantId, String provider);

    Optional<TbDeviceBinding> findByProviderAndExternalDeviceId(String provider, String externalDeviceId);

    boolean existsByDeviceIdAndProvider(Long deviceId, String provider);
}
