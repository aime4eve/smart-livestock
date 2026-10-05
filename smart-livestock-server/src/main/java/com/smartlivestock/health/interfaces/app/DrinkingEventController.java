package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingEventResponse;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingLabelRequest;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingManualRequest;
import com.smartlivestock.health.application.service.DrinkingEventService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Locale;
import java.util.Set;

/**
 * Drinking-event marking endpoints (NIX-256 Task 3, spec §15.2). Reads are
 * open to any authenticated farm member (FarmScopeInterceptor validates
 * tenant/farm ownership); writes require OWNER / B2B_ADMIN / WORKER — the
 * same three-role convention as PhysiologyEventController. Read/query
 * endpoints for the UI are Task 5.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/livestock/{livestockId}/drinking-events")
@RequiredArgsConstructor
public class DrinkingEventController {

    private final DrinkingEventService drinkingEventService;

    /** Confirm / reject / reset the label of one drinking event row. */
    @PatchMapping("/{eventId}/label")
    public ResponseEntity<ApiResponse<DrinkingEventResponse>> updateLabel(
            @PathVariable Long farmId, @PathVariable Long livestockId, @PathVariable Long eventId,
            @RequestBody DrinkingLabelRequest request) {
        requireWriteRole();
        String label = request == null ? null : request.label();
        return ResponseEntity.ok(ApiResponse.ok(
                drinkingEventService.updateLabel(farmId, livestockId, eventId, label)));
    }

    /** Back-fill a missed drinking event (source=MANUAL, label=CONFIRMED). */
    @PostMapping("/manual")
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
