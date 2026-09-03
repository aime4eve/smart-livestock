package com.smartlivestock.shared.security;

import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.common.MessageResolver;
import com.smartlivestock.shared.tenant.TenantContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

/**
 * On-premise license enforcement gate (design §11 enforcement matrix,
 * NIX-184 T5).
 * <p>
 * Active only when {@code smartlivestock.license.mode=ONPREM}; in HOSTED mode
 * (the default, and today's dev/test behavior) every request passes through.
 * <p>
 * Per-tenant decision, read from {@code deployment_license_states}:
 * <ul>
 *   <li>{@link LicenseRuntimeStatus#PENDING_ACTIVATION} — block business APIs
 *       (403 LICENSE_REQUIRED, {@code license.pendingActivation})</li>
 *   <li>{@link LicenseRuntimeStatus#SUSPENDED} — protective hold (time
 *       rollback / tamper), block business APIs including
 *       {@code /api/v1/open/**} ({@code license.suspended})</li>
 *   <li>{@code VALID}, {@code EXPIRED} or no state row — pass. EXPIRED
 *       tenants already had their subscription degraded to FREE/BASIC by the
 *       scheduler, so capability limits stay the FeatureGate's job.</li>
 * </ul>
 * Requests without a {@link TenantContext} tenant pass through: platform
 * admins operate cross-tenant and every affected controller keeps its own
 * role guard.
 * <p>
 * Registration lives in {@code WebMvcConfig}; excluded from enforcement:
 * {@code /api/v1/auth/**} (login), {@code /api/v1/me/**} (frontend session
 * bootstrap), {@code /api/v1/admin/deployment-license/**} (license management
 * must survive PENDING_ACTIVATION/SUSPENDED) and
 * {@code /api/v1/admin/tenants/**} (platform operator reach-in). The
 * {@code /api/v1/me/**} exclusion is a deliberate addition beyond the design
 * §11 list: the SPA reads the session bootstrap on every cold start and would
 * otherwise show a dead shell on a pending-activation deployment.
 * <p>
 * The JSON error body mirrors the hand-written format of the SecurityConfig
 * authentication entry point ({@code code/message/requestId/data}).
 */
@Component
public class LicenseEnforcementInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(LicenseEnforcementInterceptor.class);

    private final DeploymentLicenseStateRepository stateRepository;
    private final MessageResolver messageResolver;
    private final String licenseMode;

    public LicenseEnforcementInterceptor(DeploymentLicenseStateRepository stateRepository,
                                         MessageResolver messageResolver,
                                         @Value("${smartlivestock.license.mode:HOSTED}")
                                         String licenseMode) {
        this.stateRepository = stateRepository;
        this.messageResolver = messageResolver;
        this.licenseMode = licenseMode != null ? licenseMode.trim() : "HOSTED";
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws IOException {
        if (!"ONPREM".equalsIgnoreCase(licenseMode)) {
            return true; // HOSTED keeps today's behavior — no host binding (design §2)
        }

        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            return true; // platform admin / unauthenticated — controller guards apply
        }

        LicenseRuntimeStatus status = stateRepository.findByTenantId(tenantId)
                .map(DeploymentLicenseState::getRuntimeStatus)
                .orElse(null);

        if (status == LicenseRuntimeStatus.PENDING_ACTIVATION) {
            return reject(response, "license.pendingActivation",
                    "License pending activation for tenant {}", tenantId);
        }
        if (status == LicenseRuntimeStatus.SUSPENDED) {
            return reject(response, "license.suspended",
                    "License suspended for tenant {}", tenantId);
        }
        // VALID / EXPIRED / no row: allow. EXPIRED tenants run on the degraded
        // FREE/BASIC subscription; capability limits live in the FeatureGate.
        return true;
    }

    /** Write the SecurityConfig entry-point style JSON body and stop the chain. */
    private boolean reject(HttpServletResponse response, String messageKey,
                           String logPattern, Long tenantId) throws IOException {
        String message = messageResolver.resolve(messageKey, null,
                LocaleContextHolder.getLocale());
        log.warn(logPattern, tenantId);

        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        String requestId = MDC.get("requestId") != null
                ? MDC.get("requestId") : UUID.randomUUID().toString();
        String body = "{\"code\":\"" + ErrorCode.LICENSE_REQUIRED.name()
                + "\",\"message\":\"" + escapeJson(message)
                + "\",\"requestId\":\"" + requestId + "\",\"data\":null}";
        response.getWriter().write(body);
        response.getWriter().flush();
        return false;
    }

    /** Minimal JSON escaping for the i18n message payload. */
    private static String escapeJson(String value) {
        StringBuilder sb = new StringBuilder(value.length() + 8);
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
                }
            }
        }
        return sb.toString();
    }
}
