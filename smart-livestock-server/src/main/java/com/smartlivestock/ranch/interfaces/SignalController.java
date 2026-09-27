package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.signal.SignalDtos.LivestockSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalDtos.MapSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalQueryService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/signals")
@RequiredArgsConstructor
public class SignalController {

    private final SignalQueryService signalQueryService;

    @GetMapping("/livestock")
    public ResponseEntity<ApiResponse<LivestockSignalResponse>> livestockSignals(
            @PathVariable Long farmId,
            @RequestParam List<Long> livestockIds,
            @RequestParam(defaultValue = "0") String cursor) {
        return ResponseEntity.ok(ApiResponse.ok(signalQueryService.getLivestockSignals(
                farmId, livestockIds, cursor, currentUserId()
        )));
    }

    @GetMapping("/map")
    public ResponseEntity<ApiResponse<MapSignalResponse>> mapSignals(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "0:0:0") String cursor,
            @RequestParam(defaultValue = "false") boolean includeGeometry) {
        return ResponseEntity.ok(ApiResponse.ok(signalQueryService.getMapSignals(
                farmId, cursor, includeGeometry, currentUserId()
        )));
    }

    private Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof Long userId)) {
            return null;
        }
        return userId;
    }
}
