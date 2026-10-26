package com.smartlivestock.iot.interfaces.open;

import com.smartlivestock.commerce.application.service.FeatureGateQueryService;
import com.smartlivestock.commerce.application.service.FeatureGateQueryService.GateConfig;
import com.smartlivestock.health.application.dto.OpenTelemetryDtos.DeviceHealthTelemetry;
import com.smartlivestock.health.application.dto.OpenTelemetryDtos.LivestockTelemetry;
import com.smartlivestock.health.application.service.OpenTelemetryQueryService;
import com.smartlivestock.identity.application.TenantSubscriptionResolver.SubscriptionSnapshot;
import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.iot.application.dto.OpenDeviceTelemetryDtos.DeviceTelemetry;
import com.smartlivestock.iot.application.service.OpenDeviceTelemetryQueryService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.ratelimit.RateLimitService;
import com.smartlivestock.shared.security.ApiKeyAuthFilter;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Open API — Telemetry history &amp; export, 2 endpoints (NIX-323).
 *
 * Access model (ruling 2026-10-26, "degrade, don't reject"):
 * the tenant's subscription snapshot is attached by ApiKeyAuthFilter; expired
 * tenants resolve to the basic tier. Every tier can export telemetry — tiers
 * differ in the queryable window (feature_gates.retention_days) and the 24h
 * call budget (feature_gates.limit_value, enforced via a Redis sliding
 * window, NOT QuotaCheckService whose isActiveOrTrial gate would reject
 * expired tenants outright).
 */
@RestController
@RequestMapping("/api/v1/open/farms/{farmId}")
@RequiredArgsConstructor
public class OpenTelemetryController {

    private static final int MAX_PAGE_SIZE = 100;

    private final ApiKeyAuthService apiKeyAuthService;
    private final FeatureGateQueryService featureGateQueryService;
    private final OpenDeviceTelemetryQueryService openDeviceTelemetryQueryService;
    private final OpenTelemetryQueryService openTelemetryQueryService;
    private final DeviceRepository deviceRepository;
    private final LivestockRepository livestockRepository;

    /**
     * GET /api/v1/open/farms/{farmId}/livestock/{livestockId}/telemetry
     * Query: types (temperature,motility,activity), startTime, endTime, page, pageSize.
     */
    @GetMapping("/livestock/{livestockId}/telemetry")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLivestockTelemetry(
            @PathVariable Long farmId,
            @PathVariable Long livestockId,
            @RequestParam(required = false) String types,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "100") int pageSize,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);
        requireLivestockInFarm(livestockId, farmId);

        GateConfig gate = enforceGateAndBudget(request);
        Set<String> typeSet = parseTypes(types);
        int effectivePageSize = clampPageSize(pageSize);
        Window window = resolveWindow(startTime, endTime, gate.retentionDays());

        LivestockTelemetry telemetry = openTelemetryQueryService.queryByLivestock(
                livestockId, null, typeSet, window.from(), window.to(), page, effectivePageSize);

        Map<String, Object> data = new HashMap<>();
        data.put("livestockId", livestockId);
        data.put("windowFrom", window.from().toString());
        data.put("windowTo", window.to().toString());
        data.put("windowDays", gate.retentionDays());
        data.put("temperature", telemetry.temperature());
        data.put("motility", telemetry.motility());
        data.put("activity", telemetry.activity());
        return ResponseEntity.ok().body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/open/farms/{farmId}/devices/{deviceId}/telemetry
     * Query: types (frames,temperature,motility), startTime, endTime, page, pageSize.
     */
    @GetMapping("/devices/{deviceId}/telemetry")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDeviceTelemetry(
            @PathVariable Long farmId,
            @PathVariable Long deviceId,
            @RequestParam(required = false) String types,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "100") int pageSize,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);
        requireDeviceInTenant(deviceId, request);

        GateConfig gate = enforceGateAndBudget(request);
        Set<String> typeSet = parseTypes(types);
        int effectivePageSize = clampPageSize(pageSize);
        Window window = resolveWindow(startTime, endTime, gate.retentionDays());

        Map<String, Object> data = new HashMap<>();
        data.put("deviceId", deviceId);
        data.put("windowFrom", window.from().toString());
        data.put("windowTo", window.to().toString());
        data.put("windowDays", gate.retentionDays());

        boolean wantFrames = typeSet.isEmpty() || typeSet.contains("frames");
        if (wantFrames) {
            DeviceTelemetry frames = openDeviceTelemetryQueryService.queryByDevice(
                    deviceId, window.from(), window.to(), page, effectivePageSize);
            data.put("deviceCode", frames.deviceCode());
            data.put("frames", frames.frames());
        }
        DeviceHealthTelemetry health = openTelemetryQueryService.queryByDevice(
                deviceId, typeSet, window.from(), window.to(), page, effectivePageSize);
        data.put("temperature", health.temperature());
        data.put("motility", health.motility());

        return ResponseEntity.ok().body(ApiResponse.ok(data));
    }

    // ── helpers ────────────────────────────────────────────────

    /** Livestock must belong to the path farm (cross-farm IDs are a 404). */
    private void requireLivestockInFarm(Long livestockId, Long farmId) {
        Livestock livestock = livestockRepository.findById(livestockId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "牲畜不存在: " + livestockId));
        if (!farmId.equals(livestock.getFarmId())) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "牲畜不存在于该牧场: " + livestockId);
        }
    }

    /** Devices are tenant-scoped; the requesting key's tenant must own it. */
    private void requireDeviceInTenant(Long deviceId, HttpServletRequest request) {
        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "设备不存在: " + deviceId));
        ApiKey key = requireApiKeyEntity(request);
        if (device.getTenantId() == null || !device.getTenantId().equals(key.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该设备");
        }
    }

    /**
     * Gate + budget. Degrade-don't-reject: the tier is already degraded by the
     * resolver (expired → basic); a disabled gate is the only 403 path, and the
     * 24h budget throws QUOTA_EXCEEDED once exhausted.
     */
    private GateConfig enforceGateAndBudget(HttpServletRequest request) {
        SubscriptionSnapshot snapshot = resolveSnapshot(request);
        String tier = snapshot != null ? snapshot.tier() : "basic";
        GateConfig gate = featureGateQueryService.getGate(
                tier, OpenDeviceTelemetryQueryService.TELEMETRY_EXPORT_FEATURE);
        if (!gate.enabled()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN,
                    "当前订阅档位 (" + tier + ") 不可用遥测导出");
        }
        ApiKey key = requireApiKeyEntity(request);
        RateLimitService.RateLimitResult budget =
                openDeviceTelemetryQueryService.consumeExportBudget(key.getTenantId(), gate.limitValue());
        if (!budget.allowed()) {
            throw new ApiException(ErrorCode.QUOTA_EXCEEDED,
                    "遥测导出配额已用尽（24h 滚动窗口上限 " + gate.limitValue() + " 次）");
        }
        return gate;
    }

    private SubscriptionSnapshot resolveSnapshot(HttpServletRequest request) {
        Object attr = request.getAttribute(ApiKeyAuthFilter.ATTR_SUBSCRIPTION);
        return attr instanceof SubscriptionSnapshot snapshot ? snapshot : null;
    }

    private ApiKey requireApiKeyEntity(HttpServletRequest request) {
        Object attr = request.getAttribute(ApiKeyAuthFilter.ATTR_API_KEY);
        if (attr instanceof ApiKey key) {
            return key;
        }
        throw new ApiException(ErrorCode.AUTH_API_KEY_INVALID, "API Key 上下文缺失");
    }

    private static int clampPageSize(int pageSize) {
        return Math.min(Math.max(1, pageSize), MAX_PAGE_SIZE);
    }

    private static Set<String> parseTypes(String types) {
        if (types == null || types.isBlank()) {
            return Set.of();
        }
        return Arrays.stream(types.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(s -> s.toLowerCase(Locale.ROOT))
                .collect(Collectors.toUnmodifiableSet());
    }

    private record Window(Instant from, Instant to) {}

    /**
     * Clamps the requested window to the tier's retention:
     * [max(startTime, now-retentionDays), min(endTime, now)]; default last
     * retentionDays. The effective window is echoed in the response.
     */
    private static Window resolveWindow(String startTime, String endTime, int retentionDays) {
        Instant now = Instant.now();
        Instant floor = now.minus(Duration.ofDays(retentionDays));
        Instant from = (startTime != null && !startTime.isBlank()) ? parseInstant(startTime) : floor;
        Instant to = (endTime != null && !endTime.isBlank()) ? parseInstant(endTime) : now;
        if (from.isBefore(floor)) {
            from = floor;
        }
        if (to.isAfter(now)) {
            to = now;
        }
        if (!to.isAfter(from)) {
            to = from.plusSeconds(1);
        }
        return new Window(from, to);
    }

    private static Instant parseInstant(String value) {
        String normalized = value.trim().replace(" ", "+");
        return Instant.parse(normalized);
    }
}
