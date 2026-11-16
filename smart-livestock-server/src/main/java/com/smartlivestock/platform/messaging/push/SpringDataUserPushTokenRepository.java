package com.smartlivestock.platform.messaging.push;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface SpringDataUserPushTokenRepository
        extends JpaRepository<UserPushTokenJpaEntity, Long> {

    Optional<UserPushTokenJpaEntity> findByToken(String token);

    List<UserPushTokenJpaEntity> findByUserId(Long userId);

    List<UserPushTokenJpaEntity> findByUserIdInAndPlatform(Collection<Long> userIds, String platform);
}
