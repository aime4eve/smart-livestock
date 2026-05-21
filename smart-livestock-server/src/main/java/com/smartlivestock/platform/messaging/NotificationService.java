package com.smartlivestock.platform.messaging;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class NotificationService {

    private final SpringDataNotificationRepository notificationRepository;

    public NotificationService(SpringDataNotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Transactional
    public NotificationJpaEntity createNotification(Long tenantId, Long userId, String type,
                                                     String title, String content) {
        NotificationJpaEntity entity = new NotificationJpaEntity();
        entity.setTenantId(tenantId);
        entity.setUserId(userId);
        entity.setType(type);
        entity.setTitle(title);
        entity.setContent(content);
        entity.setIsRead(false);
        return notificationRepository.save(entity);
    }

    public List<NotificationJpaEntity> findUnreadByTenant(Long tenantId) {
        return notificationRepository.findByTenantIdAndIsReadFalseOrderByCreatedAtDesc(tenantId);
    }

    public List<NotificationJpaEntity> findByTenant(Long tenantId) {
        return notificationRepository.findByTenantIdOrderByCreatedAtDesc(tenantId);
    }
}
