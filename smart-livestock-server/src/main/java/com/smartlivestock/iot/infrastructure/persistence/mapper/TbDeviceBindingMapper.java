package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.infrastructure.persistence.entity.TbDeviceBindingJpaEntity;

public final class TbDeviceBindingMapper {

    private TbDeviceBindingMapper() {}

    public static TbDeviceBindingJpaEntity toJpaEntity(TbDeviceBinding binding) {
        TbDeviceBindingJpaEntity jpa = new TbDeviceBindingJpaEntity();
        jpa.setId(binding.getId());
        jpa.setTenantId(binding.getTenantId());
        jpa.setDeviceId(binding.getDeviceId());
        jpa.setProvider(binding.getProvider());
        jpa.setDeviceEui(binding.getDeviceEui());
        jpa.setExternalDeviceId(binding.getExternalDeviceId());
        jpa.setExternalDeviceName(binding.getExternalDeviceName());
        jpa.setBindingStatus(binding.getStatus() != null ? binding.getStatus().name() : null);
        jpa.setTelemetryCursorMs(binding.getTelemetryCursorMs());
        jpa.setLastEventAt(binding.getLastEventAt());
        jpa.setLastVerifiedAt(binding.getLastVerifiedAt());
        jpa.setLastPollAt(binding.getLastPollAt());
        jpa.setConsecutiveFailures(binding.getConsecutiveFailures());
        return jpa;
    }

    public static TbDeviceBinding toDomain(TbDeviceBindingJpaEntity jpa) {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setId(jpa.getId());
        binding.setTenantId(jpa.getTenantId());
        binding.setDeviceId(jpa.getDeviceId());
        binding.setProvider(jpa.getProvider());
        binding.setDeviceEui(jpa.getDeviceEui());
        binding.setExternalDeviceId(jpa.getExternalDeviceId());
        binding.setExternalDeviceName(jpa.getExternalDeviceName());
        binding.setStatus(jpa.getBindingStatus() != null
                ? TbDeviceBinding.Status.valueOf(jpa.getBindingStatus()) : null);
        binding.setTelemetryCursorMs(jpa.getTelemetryCursorMs());
        binding.setLastEventAt(jpa.getLastEventAt());
        binding.setLastVerifiedAt(jpa.getLastVerifiedAt());
        binding.setLastPollAt(jpa.getLastPollAt());
        binding.setConsecutiveFailures(jpa.getConsecutiveFailures());
        return binding;
    }
}
