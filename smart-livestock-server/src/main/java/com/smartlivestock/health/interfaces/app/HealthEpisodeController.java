package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.HealthDtos.EpisodeBoard;
import com.smartlivestock.health.application.service.HealthEpisodeService;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

/**
 * Per-scene health workbench board (NIX-245): one endpoint feeds the fever /
 * digestive / estrus / epidemic workbenches, the reconciling header and the
 * alert-center notifications — same numbers everywhere.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/health")
@RequiredArgsConstructor
public class HealthEpisodeController {

    private final HealthEpisodeService episodeService;

    @GetMapping("/episodes")
    public ResponseEntity<ApiResponse<EpisodeBoard>> board(
            @PathVariable Long farmId,
            @RequestParam String scene) {
        if (!scene.equals(HealthEpisodeService.SCENE_FEVER)
                && !scene.equals(HealthEpisodeService.SCENE_DIGESTIVE)
                && !scene.equals(HealthEpisodeService.SCENE_ESTRUS)
                && !scene.equals(HealthEpisodeService.SCENE_EPIDEMIC)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.health.unknownScene");
        }
        return ResponseEntity.ok(ApiResponse.ok(episodeService.board(farmId, scene, currentUserId())));
    }

    private Long currentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth == null || auth.getPrincipal() == null || !(auth.getPrincipal() instanceof Long)
                ? null : (Long) auth.getPrincipal();
    }
}
