package com.smartlivestock.identity.infrastructure.acl;

import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataUserRepository;
import com.smartlivestock.licensing.domain.port.DeploymentAdminProvisioningPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * NIX-191 ACL: licensing asks, identity executes. The deployment
 * administrator account is born here when the first signed activation
 * certificate is imported on a fresh install.
 */
@Component
@RequiredArgsConstructor
public class DeploymentAdminProvisioningAdapter implements DeploymentAdminProvisioningPort {

    private static final String ADMIN_NAME = "管理员";

    private final UserRepository userRepository;
    private final SpringDataUserRepository springDataUsers;
    private final SpringDataTenantRepository springDataTenants;

    @Override
    public boolean hasActivePlatformAdmin() {
        return springDataUsers.existsByRoleAndIsActive(Role.PLATFORM_ADMIN.name(), true);
    }

    @Override
    public Long firstTenantId() {
        return springDataTenants.findAll().stream()
                .map(t -> t.getId())
                .min(Long::compareTo)
                .orElse(null);
    }

    @Override
    public Long provisionAdmin(String phone, String bcryptHash, boolean mustChangePassword) {
        User existing = userRepository.findByPhone(phone).orElse(null);
        if (existing != null) {
            // Idempotent: renewals must never reset an administrator the
            // customer already controls.
            return existing.getId();
        }
        User admin = new User(bcryptHash, ADMIN_NAME, Role.PLATFORM_ADMIN, null, mustChangePassword);
        admin.setPhone(phone);
        return userRepository.save(admin).getId();
    }
}
