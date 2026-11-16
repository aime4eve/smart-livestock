package com.smartlivestock.platform.messaging.push;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;

/**
 * NIX-430: a device push token owned by one user. One row per token — a
 * re-install mints a new token, an uninstalled app's token is reaped by the
 * dispatch feedback loop (APNs BadDeviceToken / Unregistered).
 */
@Entity
@Table(name = "user_push_tokens")
public class UserPushTokenJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** ios | android (android rows arrive with the deferred FCM phase). */
    @Column(name = "platform", nullable = false, length = 16)
    private String platform;

    /** APNs device token (hex), unique across users. */
    @Column(name = "token", nullable = false, unique = true, columnDefinition = "TEXT")
    private String token;

    /** sandbox | production — stamped from the server config at registration. */
    @Column(name = "apns_env", nullable = false, length = 16)
    private String apnsEnv;

    @Column(name = "app_version", length = 32)
    private String appVersion;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
    public String getApnsEnv() { return apnsEnv; }
    public void setApnsEnv(String apnsEnv) { this.apnsEnv = apnsEnv; }
    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
