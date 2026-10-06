package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventListResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventRequest;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventUpdateRequest;
import com.smartlivestock.health.application.service.PhysiologyEventService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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

/**
 * Manual physiology event stream endpoints (NIX-256 Task 1a).
 * GET is open to any authenticated farm member (FarmScopeInterceptor
 * validates tenant/farm ownership); writes are guarded by @PreAuthorize
 * and require OWNER / B2B_ADMIN / WORKER roles (NIX-258 m-k, same
 * convention as AlertController).
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
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN', 'WORKER')")
    public ResponseEntity<ApiResponse<PhysiologyEventResponse>> createEvent(
            @PathVariable Long farmId, @PathVariable Long livestockId,
            @RequestBody PhysiologyEventRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                physiologyEventService.createEvent(farmId, livestockId, request, currentUserId())));
    }

    @PutMapping("/{eventId}")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN', 'WORKER')")
    public ResponseEntity<ApiResponse<PhysiologyEventResponse>> updateEvent(
            @PathVariable Long farmId, @PathVariable Long livestockId, @PathVariable Long eventId,
            @RequestBody PhysiologyEventUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                physiologyEventService.updateEvent(farmId, livestockId, eventId, request, currentUserId())));
    }

    @DeleteMapping("/{eventId}")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN', 'WORKER')")
    public ResponseEntity<ApiResponse<Void>> deleteEvent(
            @PathVariable Long farmId, @PathVariable Long livestockId, @PathVariable Long eventId) {
        physiologyEventService.deleteEvent(farmId, livestockId, eventId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getPrincipal() instanceof Long id ? id : null;
    }
}
