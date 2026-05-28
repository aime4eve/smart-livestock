package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

public class User extends AggregateRoot {

    private String username;
    private String passwordHash;
    private String name;
    private String phone;
    private Role role;
    private Long tenantId;
    private boolean active;
    private Instant lastLoginAt;

    public User() {
        this.active = true;
    }

    public User(String username, String passwordHash, String name, Role role, Long tenantId) {
        this.username = username;
        this.passwordHash = passwordHash;
        this.name = name;
        this.role = role;
        this.tenantId = tenantId;
        this.active = true;
    }

    public void recordLogin() {
        this.lastLoginAt = Instant.now();
    }

    /**
     * Deactivate the user. Once deactivated, the user cannot be reactivated
     * via {@link #activate()} — deactivation is terminal.
     *
     * @throws ApiException if user is already inactive
     */
    public void deactivate() {
        if (!active) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "User is already inactive");
        }
        this.active = false;
    }

    /**
     * Activate is a no-op for active users. Deactivated users cannot be reactivated.
     *
     * @throws ApiException if user has been deactivated
     */
    public void activate() {
        if (!active) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "Cannot activate a deactivated user");
        }
    }

    public boolean isOwner() {
        return role == Role.OWNER;
    }

    public boolean isWorker() {
        return role == Role.WORKER;
    }

    public boolean isPlatformAdmin() {
        return role == Role.PLATFORM_ADMIN;
    }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public boolean isActive() { return active; }

    /**
     * Reconstitute the active state from persistence. Bypasses the state machine validation.
     */
    public void reconstituteActive(boolean active) { this.active = active; }

    public Instant getLastLoginAt() { return lastLoginAt; }

    /**
     * Reconstitute lastLoginAt from persistence.
     */
    public void reconstituteLastLoginAt(Instant lastLoginAt) { this.lastLoginAt = lastLoginAt; }
}
