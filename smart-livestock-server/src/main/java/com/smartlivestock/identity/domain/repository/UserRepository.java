package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.User;

import java.util.List;
import java.util.Optional;

public interface UserRepository {
    User save(User user);
    Optional<User> findById(Long id);
    Optional<User> findByPhone(String phone);

    /** Login lookup by any identifier: account / phone / email (normalized). */
    Optional<User> findByLoginIdentifier(String identifier);
    List<User> findByTenantId(Long tenantId);

    List<User> findAll();
}
