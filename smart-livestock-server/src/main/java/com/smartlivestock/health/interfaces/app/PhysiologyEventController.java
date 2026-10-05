package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventListResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventRequest;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventUpdateRequest;
import com.smartlivestock.health.application.service.PhysiologyEventService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Locale;
import java.util.Set;

/**
 * Manual physiology event stream endpoints (NIX-256 Task 1a).
 * GET is open to any authenticated farm member (FarmScopeInterceptor
 * validates tenant/farm ownership); writes require OWNER / B2B_ADMIN /
 * WORKER roles.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/livestock/{livestockId}/physiology-events")
@RequiredArgsConstructor
public class PhysiologyEventController {

    private final PhysiologyEventService physiologyEventService;

    @GetMapping
    public ResponseEntity<ApiResponse<PhysiologyEventListResponse>> listEvents(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(
                physiologyEventService.listEvents(farmId, livestockId)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PhysiologyEventResponse>> createEvent(
            @PathVariable Long farmId, @PathVariable Long livestockId,
            @RequestBody PhysiologyEventRequest request) {
        requireWriteRole();
        return ResponseEntity.ok(ApiResponse.ok(
                physiologyEventService.createEvent(farmId, livestockId, request, currentUserId())));
    }

    @PutMapping("/{eventId}")
    public ResponseEntity<ApiResponse<PhysiologyEventResponse>> updateEvent(
            @PathVariable Long farmId, @PathVariable Long livestockId, @PathVariable Long eventId,
            @RequestBody PhysiologyEventUpdateRequest request) {
        requireWriteRole();
        return ResponseEntity.ok(ApiResponse.ok(
                physiologyEventService.updateEvent(farmId, livestockId, eventId, request, currentUserId())));
    }

    @DeleteMapping("/{eventId}")
    public ResponseEntity<ApiResponse<Void>> deleteEvent(
            @PathVariable Long farmId, @PathVariable Long livestockId, @PathVariable Long eventId) {
        requireWriteRole();
        physiologyEventService.deleteEvent(farmId, livestockId, eventId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private void requireWriteRole() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean allowed = authentication != null && authentication.getAuthorities().stream()
                .anyMatch(authority -> Set.of(
                                "ROLE_OWNER", "ROLE_B2B_ADMIN", "ROLE_WORKER",
                                "OWNER", "B2B_ADMIN", "WORKER")
                        .contains(authority.getAuthority().toUpperCase(Locale.ROOT)));
        if (!allowed) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.physiology.writeForbidden");
        }
    }

    private Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getPrincipal() instanceof Long id ? id : null;
    }
}
