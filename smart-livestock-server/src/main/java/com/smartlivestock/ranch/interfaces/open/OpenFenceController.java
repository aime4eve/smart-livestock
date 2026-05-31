package com.smartlivestock.ranch.interfaces.open;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Open API — Fence (read-only), 2 endpoints.
 * Third-party developers access fence data via API Key authentication.
 */
@RestController
@RequestMapping("/api/v1/open/farms/{farmId}/fences")
@RequiredArgsConstructor
public class OpenFenceController {

    private final FenceApplicationService fenceApplicationService;
    private final ApiKeyAuthService apiKeyAuthService;

    /**
     * GET /api/v1/open/farms/{farmId}/fences
     * Paginated fence list.
     * pageSize max 100 for Open API.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFences(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        // Open API: pageSize capped at 100
        int effectivePageSize = Math.min(pageSize, 100);

        List<FenceDto> fences = fenceApplicationService.listByFarm(farmId);
        Map<String, Object> data = Map.of(
                "items", fences,
                "page", page,
                "pageSize", effectivePageSize,
                "total", fences.size()
        );

        return ResponseEntity.ok()
                .body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/open/farms/{farmId}/fences/{fenceId}
     * Fence detail with vertices.
     */
    @GetMapping("/{fenceId}")
    public ResponseEntity<ApiResponse<FenceDto>> getFence(
            @PathVariable Long farmId,
            @PathVariable Long fenceId,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        FenceDto fence = fenceApplicationService.getFence(fenceId);
        return ResponseEntity.ok()
                .body(ApiResponse.ok(fence));
    }

}
