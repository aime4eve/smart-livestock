package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.WorkbenchResponse;
import com.smartlivestock.ranch.application.service.AlertWorkbenchService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class AlertWorkbenchController {

    private static final Set<String> BUCKETS = Set.of("all", "immediate", "field", "observe", "resolved");
    private static final Set<String> ASSETS = Set.of("all", "livestock", "herd", "fence", "device");

    private final AlertWorkbenchService workbenchService;

    @GetMapping("/alerts/workbench")
    public ApiResponse<WorkbenchResponse> workbench(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "all") String bucket,
            @RequestParam(defaultValue = "all") String asset,
            @RequestParam(required = false) Long fenceId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "50") int pageSize) {
        if (!BUCKETS.contains(bucket)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "validation.bucket.invalid");
        }
        List<String> assets = Arrays.stream(asset.split(","))
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .toList();
        if (assets.isEmpty()) assets = List.of("all");
        if (assets.stream().anyMatch(value -> !ASSETS.contains(value))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "validation.asset.invalid");
        }
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        Long userId = authentication == null || !(authentication.getPrincipal() instanceof Long id) ? null : id;
        return ApiResponse.ok(workbenchService.workbench(
                farmId, userId, bucket, assets, fenceId, page, pageSize));
    }
}
