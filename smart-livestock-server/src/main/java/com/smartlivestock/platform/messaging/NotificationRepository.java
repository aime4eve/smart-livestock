package com.smartlivestock.platform.messaging;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<NotificationJpaEntity, Long> {

    List<NotificationJpaEntity> findByTenantIdAndIsReadFalseOrderByCreatedAtDesc(Long tenantId);

    List<NotificationJpaEntity> findByTenantIdOrderByCreatedAtDesc(Long tenantId);
}
