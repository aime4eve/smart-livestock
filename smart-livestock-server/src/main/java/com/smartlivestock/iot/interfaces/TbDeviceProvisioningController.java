package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.TbDeviceProvisioningService;
import com.smartlivestock.iot.application.TbTelemetryChannel;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.infrastructure.client.ns.NsProperties;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbProperties;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/devices/tb")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
public class TbDeviceProvisioningController {

    private final TbDeviceProvisioningService provisioningService;
    private final NsProperties nsProperties;
    private final TbProperties tbProperties;
    private final ObjectProvider<TbTelemetryChannel> telemetryChannelProvider;

    @GetMapping("/reconcile")
    public ResponseEntity<ApiResponse<TbDeviceProvisioningService.ReconciliationReport>> reconcile(
            @PathVariable Long farmId,
            @RequestParam Integer projectId) {
        requireAutoconfigEnabled();
        return ResponseEntity.ok(ApiResponse.ok(provisioningService.reconcile(
                projectId, TenantContext.getCurrentTenant())));
    }

    @PostMapping("/import")
    public ResponseEntity<ApiResponse<TbDeviceProvisioningService.ImportReport>> importDevices(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        requireAutoconfigEnabled();
        Integer projectId = toInteger(body.get("projectId"));
        List<TbDeviceProvisioningService.ImportItem> items = new ArrayList<>();
        Object rawItems = body.get("items");
        if (!(rawItems instanceof List<?> list)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "iot.tb.importItemsRequired");
        }
        for (Object item : list) {
            if (!(item instanceof Map<?, ?> map)) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "iot.tb.importItemsRequired");
            }
            items.add(new TbDeviceProvisioningService.ImportItem(
                    (String) map.get("eui"),
                    (String) map.get("expectedTbDeviceId"),
                    (String) map.get("deviceCode")));
        }
        TbDeviceProvisioningService.ImportReport report = provisioningService.importDevices(
                projectId, items, TenantContext.getCurrentTenant(), getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(report));
    }

    @GetMapping("/preflight")
    public ResponseEntity<ApiResponse<TbDeviceProvisioningService.Preflight>> preflight(
            @PathVariable Long farmId,
            @RequestParam String eui) {
        requireAutoconfigEnabled();
        return ResponseEntity.ok(ApiResponse.ok(provisioningService.preflight(
                eui, TenantContext.getCurrentTenant())));
    }

    @PostMapping("/provision")
    public ResponseEntity<ApiResponse<Map<String, Object>>> provision(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        requireAutoconfigEnabled();
        DeviceType requestedType = resolveDeviceType((String) body.get("deviceType"));
        TbDeviceProvisioningService.ProvisionResult result = provisioningService.provision(
                new TbDeviceProvisioningService.ProvisionCommand(
                        (String) body.get("eui"),
                        (String) body.get("deviceCode"),
                        requestedType,
                        toLong(body.get("livestockId"))),
                TenantContext.getCurrentTenant(), farmId, getCurrentUserId());

        TbTelemetryChannel channel = telemetryChannelProvider.getIfAvailable();
        String triggerStatus = channel == null
                ? "TB_TRIGGER_SKIPPED_DISABLED"
                : switch (channel.pollDevice(result.localDeviceId())) {
                    case TRIGGERED -> "TB_TRIGGERED";
                    case BINDING_NOT_FOUND -> "TB_TRIGGER_BINDING_NOT_FOUND";
                    case TRIGGER_FAILED -> "TB_TRIGGER_FAILED";
                };
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "result", result,
                "firstTelemetryTrigger", triggerStatus)));
    }

    private void requireAutoconfigEnabled() {
        if (!nsProperties.isEnabled() || !tbProperties.isEnabled()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "iot.tb.autoconfigDisabled");
        }
    }

    private static DeviceType resolveDeviceType(String value) {
        if (value == null || value.isBlank()) return null;
        return DeviceType.valueOf(value.toUpperCase().replace("DEVICE_", ""));
    }

    private static Integer toInteger(Object value) {
        if (value == null) return null;
        if (value instanceof Number number) return number.intValue();
        return Integer.valueOf(value.toString());
    }

    private static Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Number number) return number.longValue();
        return Long.valueOf(value.toString());
    }

    private static Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "auth.unauthorized");
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof Number number) return number.longValue();
        return Long.valueOf(principal.toString());
    }
}
