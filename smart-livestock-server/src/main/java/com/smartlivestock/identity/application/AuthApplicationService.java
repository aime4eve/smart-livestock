package com.smartlivestock.identity.application;

import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.identity.application.command.LoginCommand;
import com.smartlivestock.identity.application.command.SwitchContextCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.identity.application.dto.EntryContextsDto;
import com.smartlivestock.identity.application.dto.UserDto;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.model.Role;
import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.JwtTokenProvider;
import com.smartlivestock.shared.security.PasswordHasher;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthApplicationService {

    private final UserRepository userRepository;
    private final PasswordHasher passwordHasher;
    private final JwtTokenProvider jwtTokenProvider;
    private final TenantRepository tenantRepository;
    private final SpringDataTenantRepository springDataTenantRepository;
    private final SpringDataFarmRepository springDataFarmRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final AuditLogRepository auditLogRepository;

    /** Switch whitelist (design §4.3): API_CONSUMER has no interactive
     *  surface (verified: zero references outside the enum), SUPER_ADMIN
     *  itself is not a switch target (anti escalation). */
    private static final List<EntryContextsDto.EntryContextDto> SELECTABLE_CONTEXT_ROLES = List.of(
            new EntryContextsDto.EntryContextDto(Role.PLATFORM_ADMIN.name(), false),
            new EntryContextsDto.EntryContextDto(Role.B2B_ADMIN.name(), true),
            new EntryContextsDto.EntryContextDto(Role.OWNER.name(), true),
            new EntryContextsDto.EntryContextDto(Role.WORKER.name(), true));

    // 写事务：recordLogin 需要落库（last_login_at）；readOnly 会让 save 静默不 flush。
    @Transactional
    public AuthTokenDto login(LoginCommand command) {
        // Identifier routing (ruling 2026-10-12): email → phone (E.164 +
        // legacy bare-number fallback) → account. Message stays generic
        // ("账号或密码错误") so login probing learns nothing.
        User user = resolveLoginUser(command.identifier())
                .orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "auth.invalidIdentifierOrPassword"));
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "用户已停用");
        }
        // Tenant lifecycle gate (ruling 2026-10-14): disabled/deleted tenants
        // reject login for every member.
        if (user.getTenantId() != null) {
            tenantRepository.findById(user.getTenantId()).ifPresent(tenant -> {
                if (tenant.isDeleted()) {
                    throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "auth.tenantDeleted");
                }
                if ("disabled".equals(tenant.getStatus())) {
                    throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "auth.tenantDisabled");
                }
            });
        }
        if (!passwordHasher.matches(command.password(), user.getPasswordHash())) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "auth.invalidIdentifierOrPassword");
        }
        user.recordLogin();
        userRepository.save(user);
        String token = jwtTokenProvider.generateToken(user.getId(), user.getTenantId(), user.getRole().name());
        return new AuthTokenDto(token, UserDto.from(user));
    }

    /** Account / email are case-insensitive; phone tries E.164 first, then
     *  the raw string so legacy bare 11-digit numbers keep working. */
    private java.util.Optional<User> resolveLoginUser(String raw) {
        String v = raw == null ? "" : raw.trim();
        if (v.isEmpty()) return java.util.Optional.empty();
        switch (com.smartlivestock.identity.application.LoginIdentifiers.classify(v)) {
            case EMAIL: return userRepository.findByLoginIdentifier(
                    com.smartlivestock.identity.application.LoginIdentifiers.normalizeEmail(v));
            case PHONE: {
                for (String candidate : com.smartlivestock.identity.application.LoginIdentifiers
                        .phoneCandidates(v)) {
                    var hit = userRepository.findByLoginIdentifier(candidate);
                    if (hit.isPresent()) return hit;
                }
                return java.util.Optional.empty();
            }
            default: return userRepository.findByLoginIdentifier(
                    com.smartlivestock.identity.application.LoginIdentifiers.normalizeAccount(v));
        }
    }

    /**
     * Refresh: validate current access token (grace period for recently expired),
     * look up user, and issue a new access token. For switched context tokens
     * the act claim survives refresh (JwtTokenProvider) and the response user
     * mirrors the token's effective identity instead of the stored row.
     */
    @Transactional(readOnly = true)
    public AuthTokenDto refresh(String currentToken) {
        String newToken = jwtTokenProvider.refreshToken(currentToken);
        if (newToken == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "Token 无法刷新，请重新登录");
        }
        Long userId = jwtTokenProvider.getUserIdFromToken(newToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "用户不存在"));
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "用户已停用");
        }
        Claims claims = jwtTokenProvider.parseToken(newToken);
        if (claims.get("act") != null) {
            return new AuthTokenDto(newToken, effectiveContextUser(user, claims), true);
        }
        return new AuthTokenDto(newToken, UserDto.from(user), false);
    }

    /**
     * Selectable entry contexts for the super-admin picker (design §4.3):
     * static role whitelist + non-deleted tenants with status/trial flags.
     */
    @Transactional(readOnly = true)
    public EntryContextsDto listEntryContexts() {
        List<EntryContextsDto.TenantOptionDto> tenants = springDataTenantRepository.findAll().stream()
                .filter(t -> t.getDeletedAt() == null)
                .sorted(Comparator.comparing(TenantJpaEntity::getName))
                .map(t -> new EntryContextsDto.TenantOptionDto(
                        t.getId(),
                        t.getName(),
                        "disabled".equals(t.getStatus()) ? "disabled" : "active",
                        t.getPhase(),
                        t.getTimezone(),
                        springDataFarmRepository.findByTenantIdAndDeletedAtIsNull(t.getId()).size(),
                        trialExpired(t.getId())))
                .toList();
        return new EntryContextsDto(SELECTABLE_CONTEXT_ROLES, tenants);
    }

    /**
     * Switch the super admin's session into a target role/tenant context
     * (design §4.2/§4.3): issues a token structurally identical to a real
     * user's (role/tid = target) plus the RFC 8693 style act marker, after
     * the five gates. Every switch is audited.
     */
    @Transactional
    public AuthTokenDto switchContext(Long superAdminUserId, SwitchContextCommand command) {
        User user = userRepository.findById(superAdminUserId)
                .orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "用户不存在"));
        if (user.getRole() != Role.SUPER_ADMIN) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "auth.contextSwitchForbidden");
        }
        // /api/v1/auth/** sits on the password-change whitelist, so the
        // switch itself must re-check the lock — it must not become a
        // bypass into business APIs (design §4.8).
        if (user.isMustChangePassword()) {
            throw new ApiException(ErrorCode.PASSWORD_CHANGE_REQUIRED, "error.passwordChangeRequired");
        }
        String targetRoleName = command.role() == null ? "" : command.role().trim();
        if (SELECTABLE_CONTEXT_ROLES.stream().noneMatch(r -> r.role().equals(targetRoleName))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "auth.roleNotSelectable");
        }
        Role targetRole = Role.valueOf(targetRoleName);

        Long targetTenantId = null;
        if (targetRole != Role.PLATFORM_ADMIN) {
            targetTenantId = command.tenantId();
            if (targetTenantId == null) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "auth.tenantRequired");
            }
            Tenant tenant = tenantRepository.findById(targetTenantId)
                    .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "auth.tenantNotFound"));
            // Deleted tenants are unreachable at all; disabled tenants stay
            // enterable for support triage (ruling 2026-10-19 #1); trial-
            // expired tenants refuse here instead of per-request (#4).
            if (tenant.isDeleted()) {
                throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "auth.tenantNotFound");
            }
            if (trialExpired(targetTenantId)) {
                throw new ApiException(ErrorCode.LICENSE_EXPIRED, "auth.tenantTrialExpired");
            }
        }

        String token = jwtTokenProvider.generateToken(
                user.getId(), targetTenantId, targetRole.name(),
                Map.of("sub", user.getId(), "role", Role.SUPER_ADMIN.name()));

        auditContextSwitch(user.getId(), targetTenantId, targetRole);

        UserDto effective = new UserDto(
                user.getId(), user.getName(), user.getPhone(), user.getAccount(),
                user.getUsername(), user.getEmail(),
                targetRole.name(), targetTenantId, user.isActive(), false);
        return new AuthTokenDto(token, effective, true);
    }

    /** Terminal trial-expiry semantics mirror the hourly TrialExpiryJob
     *  (TRIAL -> FREE): FREE counts as expired, plus an overdue TRIAL as
     *  belt-and-braces before the job flips it. */
    private boolean trialExpired(Long tenantId) {
        return subscriptionRepository.findByTenantId(tenantId)
                .map(s -> s.getStatus() == SubscriptionStatus.FREE
                        || (s.getStatus() == SubscriptionStatus.TRIAL
                            && s.getTrialEndsAt() != null
                            && s.getTrialEndsAt().isBefore(Instant.now())))
                .orElse(false);
    }

    /** Switched context token: the response user mirrors the token claims
     *  (effective role/tenant), never the super admin's stored row. */
    private UserDto effectiveContextUser(User user, Claims claims) {
        return new UserDto(
                user.getId(),
                user.getName(),
                user.getPhone(),
                user.getAccount(),
                user.getUsername(),
                user.getEmail(),
                claims.get("role", String.class),
                claims.get("tid", Long.class),
                user.isActive(),
                false);
    }

    private void auditContextSwitch(Long superAdminUserId, Long tenantId, Role targetRole) {
        try {
            Map<String, Object> details = new HashMap<>();
            details.put("targetRole", targetRole.name());
            details.put("switchedBy", "SUPER_ADMIN");
            auditLogRepository.save(new AuditLog(
                    UUID.randomUUID().toString(),
                    "AUTH_CONTEXT_SWITCHED",
                    tenantId,
                    superAdminUserId,
                    "AUTH_CONTEXT_SWITCHED",
                    details,
                    Instant.now(),
                    null,
                    targetRole.name()));
        } catch (Exception e) {
            log.error("Failed to audit context switch by user {} to {}@tenant{}",
                    superAdminUserId, targetRole, tenantId, e);
        }
    }
}
