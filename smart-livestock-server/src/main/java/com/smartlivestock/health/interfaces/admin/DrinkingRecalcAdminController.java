package com.smartlivestock.health.interfaces.admin;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingRecalcRequest;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingRecalcResponse;
import com.smartlivestock.health.application.service.DrinkingRecalculationService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Manual drinking-event back-computation (NIX-256 Task 4, spec P5).
 * Platform/B2B admins re-run the detector over an explicit date range —
 * after a parameter change, a data back-fill, or for the T6 30-day replay.
 *
 * <p>Execution is synchronous by design: a 30-day full-herd sweep can run
 * for minutes, so start/finish (with duration) is logged server-side and
 * the HTTP timeout is owned by the caller. Class-level @PreAuthorize
 * mirrors the TileAdminController convention.
 */
@RestController
@RequestMapping("/api/v1/admin/drinking-recalculate")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class DrinkingRecalcAdminController {

    private final DrinkingRecalculationService recalculationService;

    /**
     * Recalculate drinking events. Body:
     * {@code {deviceId?: Long, from: "yyyy-MM-dd", to: "yyyy-MM-dd"}} —
     * a <b>closed date range</b> interpreted in Asia/Shanghai: from-day
     * 00:00 → to+1-day 00:00 (to is recalculated through its day end).
     * With {@code deviceId} one device is recalculated (removed capsules
     * allowed — history keeps its old owner, F6); without it, every farm
     * with active capsule bindings.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<DrinkingRecalcResponse>> recalculate(
            @RequestBody DrinkingRecalcRequest request) {
        Long deviceId = request == null ? null : request.deviceId();
        String from = request == null ? null : request.from();
        String to = request == null ? null : request.to();
        return ResponseEntity.ok(ApiResponse.ok(recalculationService.recalculate(deviceId, from, to)));
    }
}
