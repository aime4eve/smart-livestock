package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.TbDeviceBinding;

import java.util.List;
import java.util.Optional;

public interface TbDeviceBindingRepository {

    TbDeviceBinding save(TbDeviceBinding binding);

    Optional<TbDeviceBinding> findById(Long id);

    List<TbDeviceBinding> findByTenantIdAndStatus(Long tenantId, TbDeviceBinding.Status status);

    /**
     * All bindings in the given status regardless of tenant — the telemetry
     * polling channel is tenant-agnostic (ruling 2026-10-12: every device is
     * collected through the single shared TB tenant; ownership stays on the
     * device row).
     */
    List<TbDeviceBinding> findByStatus(TbDeviceBinding.Status status);

    Optional<TbDeviceBinding> findByDeviceIdAndProvider(Long deviceId, String provider);

    List<TbDeviceBinding> findByTenantIdAndProvider(Long tenantId, String provider);

    Optional<TbDeviceBinding> findByProviderAndExternalDeviceId(String provider, String externalDeviceId);

    Optional<TbDeviceBinding> findByProviderAndDeviceEui(String provider, String deviceEui);

    boolean existsByDeviceIdAndProvider(Long deviceId, String provider);
}
