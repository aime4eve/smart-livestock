package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.TbDeviceBindingJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataTbDeviceBindingRepository
        extends JpaRepository<TbDeviceBindingJpaEntity, Long> {

    List<TbDeviceBindingJpaEntity> findByBindingStatus(String bindingStatus);

    Optional<TbDeviceBindingJpaEntity> findByDeviceIdAndProvider(Long deviceId, String provider);

    boolean existsByDeviceIdAndProvider(Long deviceId, String provider);
}
