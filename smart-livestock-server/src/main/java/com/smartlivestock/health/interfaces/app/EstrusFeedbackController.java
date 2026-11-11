package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.service.EstrusFeedbackService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Human-verdict endpoint on a candidate ESTRUS alert (NIX-286 contract v2).
 * The verdict writes two health-owned tables (ALERT_CONFIRM physiology audit
 * row + MANUAL ground-truth label), so the controller lives in the health
 * context; no ranch controller injects a health application service today,
 * and rather than opening that boundary the route still addresses the alert
 * operation family: {@code /api/v1/farms/{farmId}/alerts/{alertId}/estrus-feedback}.
 * The role guard mirrors the alert-action endpoints (OWNER / B2B_ADMIN /
 * WORKER, same convention as AlertController dismiss/handle); farm-scoping,
 * alert-type and error mapping (404 / 400 / 403) are owned end-to-end by
 * {@link EstrusFeedbackService#submitFeedback} via ApiException.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class EstrusFeedbackController {

    private final EstrusFeedbackService estrusFeedbackService;

    @PostMapping("/alerts/{alertId}/estrus-feedback")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN', 'WORKER')")
    public ResponseEntity<ApiResponse<EstrusFeedbackService.FeedbackResult>> submitFeedback(
            @PathVariable Long farmId,
            @PathVariable Long alertId,
            @RequestBody EstrusFeedbackRequest request) {
        if (request == null || request.confirmed() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.estrusFeedback.requestInvalid");
        }
        return ResponseEntity.ok(ApiResponse.ok(estrusFeedbackService.submitFeedback(
                farmId, alertId, request.confirmed(), getCurrentUserId())));
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }

    /** Request body of a verdict submission: {@code {"confirmed": true|false}}. */
    public record EstrusFeedbackRequest(Boolean confirmed) {
    }
}
