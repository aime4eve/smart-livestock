package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingEventResponse;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingLabelRequest;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingManualRequest;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingPeerComparisonResponse;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingSummaryResponse;
import com.smartlivestock.health.application.service.DrinkingEventService;
import com.smartlivestock.health.application.service.DrinkingSummaryService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Drinking-event endpoints (NIX-256 Task 3 marking loop + Task 5a reads),
 * all farm-scoped under {@code /api/v1/farms/{farmId}/livestock/{livestockId}}:
 * the row list ({@code drinking-events}), the three-layer summary
 * ({@code drinking-summary}), and the Premium peer comparison
 * ({@code drinking-peer-comparison}). Reads are open to any authenticated
 * farm member (FarmScopeInterceptor validates tenant/farm ownership;
 * the peer comparison additionally checks the subscription tier
 * server-side); writes require OWNER / B2B_ADMIN / WORKER — the same
 * three-role convention as PhysiologyEventController.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/livestock/{livestockId}")
@RequiredArgsConstructor
public class DrinkingEventController {

    private final DrinkingEventService drinkingEventService;
    private final DrinkingSummaryService drinkingSummaryService;

    // ── Task 5a read endpoints ─────────────────────────────────

    /**
     * Event detail rows of the livestock in {@code [from, to]} (closed
     * Shanghai date range, both optional, default the recent 7 days):
     * every row including candidates and REJECTED, newest first.
     */
    @GetMapping("/drinking-events")
    public ResponseEntity<ApiResponse<List<DrinkingEventResponse>>> listEvents(
            @PathVariable Long farmId, @PathVariable Long livestockId,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to) {
        return ResponseEntity.ok(ApiResponse.ok(
                drinkingEventService.listEvents(farmId, livestockId, from, to)));
    }

    /**
     * Three-layer per-cow summary: {@code days=1} daily only,
     * {@code days=7} daily + weekly + 7-day bars, {@code days=30} daily +
     * rolling 30-day baseline + 30-day bars (shapes pinned by the 3c table).
     */
    @GetMapping("/drinking-summary")
    public ResponseEntity<ApiResponse<DrinkingSummaryResponse>> summary(
            @PathVariable Long farmId, @PathVariable Long livestockId,
            @RequestParam(required = false) String date,
            @RequestParam(required = false) Integer days) {
        return ResponseEntity.ok(ApiResponse.ok(
                drinkingSummaryService.summary(farmId, livestockId, date, days)));
    }

    /**
     * Peer average of the same breed + physiology stage group (Premium —
     * server-side subscription check; non-premium gets 403
     * error.drinking.premiumRequired).
     */
    @GetMapping("/drinking-peer-comparison")
    public ResponseEntity<ApiResponse<DrinkingPeerComparisonResponse>> peerComparison(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(
                drinkingSummaryService.peerComparison(farmId, livestockId)));
    }

    // ── Task 3 marking loop (write) ────────────────────────────

    /**
     * Flip the label of one drinking event row. Spec §15.2 body contract:
     * CONFIRMED | REJECTED only (no reset to UNLABELED).
     */
    @PatchMapping("/drinking-events/{eventId}/label")
    public ResponseEntity<ApiResponse<DrinkingEventResponse>> updateLabel(
            @PathVariable Long farmId, @PathVariable Long livestockId, @PathVariable Long eventId,
            @RequestBody DrinkingLabelRequest request) {
        requireWriteRole();
        String label = request == null ? null : request.label();
        return ResponseEntity.ok(ApiResponse.ok(
                drinkingEventService.updateLabel(farmId, livestockId, eventId, label)));
    }

    /** Back-fill a missed drinking event (source=MANUAL, label=CONFIRMED). */
    @PostMapping("/drinking-events/manual")
    public ResponseEntity<ApiResponse<DrinkingEventResponse>> createManual(
            @PathVariable Long farmId, @PathVariable Long livestockId,
            @RequestBody DrinkingManualRequest request) {
        requireWriteRole();
        String eventStartAt = request == null ? null : request.eventStartAt();
        String note = request == null ? null : request.note();
        return ResponseEntity.ok(ApiResponse.ok(
                drinkingEventService.createManual(farmId, livestockId, eventStartAt, note)));
    }

    private void requireWriteRole() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean allowed = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(authority -> Set.of(
                                "ROLE_OWNER", "ROLE_B2B_ADMIN", "ROLE_WORKER",
                                "OWNER", "B2B_ADMIN", "WORKER")
                        .contains(authority.getAuthority().toUpperCase(Locale.ROOT)));
        if (!allowed) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.drinking.writeForbidden");
        }
    }
}
