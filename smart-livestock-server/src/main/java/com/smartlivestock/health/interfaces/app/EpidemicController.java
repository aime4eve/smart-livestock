package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.HealthDtos.*;
import com.smartlivestock.health.application.service.EpidemicWorkbenchService;
import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.shared.common.ApiResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Locale;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/health")
@RequiredArgsConstructor
public class EpidemicController {

    private final HealthApplicationService healthService;
    private final EpidemicWorkbenchService workbenchService;

    @GetMapping("/epidemic/workbench")
    public ResponseEntity<ApiResponse<EpidemicWorkbenchResponse>> workbench(
            @PathVariable Long farmId,
            @RequestParam(required = false) Long sourceLivestockId,
            @RequestParam(defaultValue = "72") int windowHours,
            @RequestParam(defaultValue = "2") int maxDepth,
            @RequestParam(required = false) String tier) {
        return ResponseEntity.ok(ApiResponse.ok(
                workbenchService.workbench(farmId, sourceLivestockId, windowHours, maxDepth, tier)));
    }

    @PostMapping("/epidemic/dispositions")
    public ResponseEntity<ApiResponse<EpidemicDispositionResponse>> createDisposition(
            @PathVariable Long farmId,
            @RequestBody EpidemicDispositionRequest request) {
        boolean manager = hasManagerRole();
        return ResponseEntity.ok(ApiResponse.ok(
                workbenchService.createDisposition(farmId, request, manager)));
    }

    @PostMapping("/epidemic/dispositions/{dispositionId}/complete")
    public ResponseEntity<ApiResponse<EpidemicDispositionResponse>> completeDisposition(
            @PathVariable Long farmId, @PathVariable Long dispositionId) {
        return ResponseEntity.ok(ApiResponse.ok(workbenchService.completeDisposition(
                farmId, dispositionId, currentUserId(), hasManagerRole())));
    }

    @PostMapping("/epidemic/dispositions/{dispositionId}/cancel")
    public ResponseEntity<ApiResponse<EpidemicDispositionResponse>> cancelDisposition(
            @PathVariable Long farmId,
            @PathVariable Long dispositionId,
            @RequestParam(required = false) String reason) {
        return ResponseEntity.ok(ApiResponse.ok(
                workbenchService.cancelDisposition(farmId, dispositionId, reason)));
    }

    @GetMapping("/epidemic")
    public ResponseEntity<ApiResponse<EpidemicResponse>> getEpidemicOverview(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getEpidemicOverview(farmId)));
    }

    @GetMapping("/epidemic/contacts/{livestockId}")
    public ResponseEntity<ApiResponse<ContactNetworkResponse>> getContactNetwork(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getContactNetwork(farmId, livestockId)));
    }

    @PostMapping("/epidemic/mark")
    public ResponseEntity<ApiResponse<Void>> markDiseased(
            @PathVariable Long farmId, @RequestBody MarkDiseaseRequest request) {
        healthService.markDiseased(farmId, request.livestockId(), request.diseaseType());
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @DeleteMapping("/epidemic/mark/{livestockId}")
    public ResponseEntity<ApiResponse<Void>> unmarkDiseased(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        healthService.unmarkDiseased(farmId, livestockId);
        workbenchService.cancelActiveBySource(livestockId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getPrincipal() instanceof Long id ? id : null;
    }

    private boolean hasManagerRole() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getAuthorities().stream()
                .anyMatch(authority -> Set.of("ROLE_OWNER", "ROLE_B2B_ADMIN", "OWNER", "B2B_ADMIN")
                        .contains(authority.getAuthority().toUpperCase(Locale.ROOT)));
    }
}
