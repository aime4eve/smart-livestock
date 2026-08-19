package com.smartlivestock.datagen.interfaces.admin;

import com.smartlivestock.datagen.application.DatagenClearService;
import com.smartlivestock.datagen.application.DatagenControlService;
import com.smartlivestock.datagen.application.dto.*;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/datagen")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")
public class DataGenConsoleController {
    private final DatagenControlService controlService;
    private final DatagenClearService clearService;

    @GetMapping("/farms")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listFarms() {
        List<DatagenFarmDto> items = controlService.listFarms();
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "items", items,
                "total", items.size()
        )));
    }

    @GetMapping("/console")
    public ResponseEntity<ApiResponse<DatagenConsoleDto>> console(
            @RequestParam Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(controlService.getConsole(farmId)));
    }

    @PutMapping("/control/{farmId}")
    public ResponseEntity<ApiResponse<DatagenControlResponse>> updateControl(
            @PathVariable Long farmId,
            @RequestBody DatagenControlRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                controlService.updateControl(farmId, request)));
    }

    @PutMapping("/rules/{farmId}")
    public ResponseEntity<ApiResponse<DatagenRulesDto>> updateRules(
            @PathVariable Long farmId,
            @RequestBody DatagenRulesDto request) {
        return ResponseEntity.ok(ApiResponse.ok(
                controlService.updateRules(farmId, request)));
    }

    @PostMapping("/clear/preview")
    public ResponseEntity<ApiResponse<DatagenClearResultDto>> previewClear(
            @RequestBody DatagenClearRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(clearService.preview(request)));
    }

    @PostMapping("/clear")
    public ResponseEntity<ApiResponse<DatagenClearResultDto>> clear(
            @RequestBody DatagenClearRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(clearService.clear(request)));
    }
}
