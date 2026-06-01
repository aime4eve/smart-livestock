package com.smartlivestock.identity.interfaces.b2b;

import com.smartlivestock.commerce.application.dto.ContractResponse;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.identity.application.FarmApplicationService;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.application.dto.UserDto;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.InstallationApplicationService;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.ranch.application.dto.LivestockDto;
import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.LivestockApplicationService;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * B2B Admin API — aggregates data across Identity, Ranch, IoT, Commerce contexts.
 * All endpoints require B2B_ADMIN role and operate within the authenticated tenant.
 */
@RestController
@RequestMapping("/api/v1/b2b")
@RequiredArgsConstructor
public class B2bController {

    private final FarmRepository farmRepository;
    private final FarmApplicationService farmApplicationService;
    private final UserRepository userRepository;
    private final UserFarmAssignmentRepository assignmentRepository;
    private final LivestockRepository livestockRepository;
    private final LivestockApplicationService livestockApplicationService;
    private final AlertApplicationService alertApplicationService;
    private final DeviceApplicationService deviceApplicationService;
    private final InstallationApplicationService installationApplicationService;
    private final SubscriptionQueryService subscriptionQueryService;

    // ── Dashboard ───────────────────────────────────────────────

    /**
     * GET /api/v1/b2b/dashboard
     * B端控制台概览：牧场列表、汇总统计、合同状态。
     */
    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<Map<String, Object>>> dashboard() {
        Long tenantId = requireTenantId();

        List<FarmDto> farms = farmApplicationService.listFarms(tenantId);

        int totalLivestock = 0;
        int pendingAlerts = 0;
        List<Map<String, Object>> farmSummaries = new ArrayList<>();
        List<Map<String, Object>> alertSummary = new ArrayList<>();

        int totalWorkers = 0;
        for (FarmDto farm : farms) {
            long livestockCount = livestockRepository.countByFarmId(farm.id());
            long workerCount = assignmentRepository.countByFarmIdAndStatus(farm.id(), "ACTIVE");
            long alertCount = alertApplicationService.listByFarm(farm.id()).stream()
                    .filter(a -> "PENDING".equals(a.status()) || "ACKNOWLEDGED".equals(a.status()))
                    .count();

            totalLivestock += livestockCount;
            pendingAlerts += (int) alertCount;
            totalWorkers += (int) workerCount;

            // Find owner for this farm
            String ownerName = assignmentRepository.findByFarmIdAndRoleAndStatus(farm.id(), "OWNER", "ACTIVE")
                    .map(assignment -> userRepository.findById(assignment.getUserId())
                            .map(User::getName).orElse(""))
                    .orElse("");

            // Count devices installed on this farm's livestock
            long deviceCount = countDevicesForFarm(farm.id());

            Map<String, Object> farmMap = new LinkedHashMap<>();
            farmMap.put("id", farm.id());
            farmMap.put("name", farm.name());
            farmMap.put("status", "active");
            farmMap.put("ownerName", ownerName);
            farmMap.put("livestockCount", livestockCount);
            farmMap.put("workerCount", workerCount);
            farmMap.put("deviceCount", deviceCount);
            farmMap.put("region", "");
            farmSummaries.add(farmMap);
        }

        long totalDevices = farmSummaries.stream()
                .mapToLong(m -> ((Number) m.get("deviceCount")).longValue())
                .sum();

        // Contract status
        String contractStatus = null;
        String contractExpiresAt = null;
        String billingModel = null;
        try {
            ContractResponse contract = subscriptionQueryService.findContractByTenantId(tenantId).orElse(null);
            if (contract != null) {
                contractStatus = contract.getStatus();
                contractExpiresAt = contract.getExpiresAt() != null ? contract.getExpiresAt().toString() : null;
                billingModel = contract.getBillingModel();
            }
        } catch (Exception ignored) {}

        // Alert severity summary
        for (FarmDto farm : farms) {
            alertApplicationService.listByFarm(farm.id()).stream()
                    .filter(a -> "PENDING".equals(a.status()))
                    .forEach(a -> {
                        Map<String, Object> item = new LinkedHashMap<>();
                        item.put("farmId", farm.id());
                        item.put("farmName", farm.name());
                        item.put("severity", a.severity());
                        item.put("type", a.type());
                        alertSummary.add(item);
                    });
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("totalFarms", farms.size());
        data.put("totalLivestock", totalLivestock);
        data.put("totalDevices", totalDevices);
        data.put("totalWorkers", totalWorkers);
        data.put("pendingAlerts", pendingAlerts);
        data.put("farms", farmSummaries);
        data.put("alertSummary", alertSummary);
        data.put("contractStatus", contractStatus);
        data.put("contractExpiresAt", contractExpiresAt);
        data.put("billingModel", billingModel);
        data.put("partnerName", null);
        data.put("monthlyRevenue", 0.0);
        data.put("deviceOnlineRate", 0.0);
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    // ── Contract ────────────────────────────────────────────────

    /**
     * GET /api/v1/b2b/contract
     * B端查看当前租户的合同与订阅信息。
     */
    @GetMapping("/contract")
    public ResponseEntity<ApiResponse<Map<String, Object>>> contract() {
        Long tenantId = requireTenantId();

        Map<String, Object> data = new LinkedHashMap<>();
        try {
            ContractResponse contract = subscriptionQueryService.findContractByTenantId(tenantId).orElse(null);
            if (contract != null) {
                data.put("id", String.valueOf(contract.getId()));
                data.put("status", contract.getStatus());
                data.put("effectiveTier", contract.getEffectiveTier());
                data.put("revenueShareRatio", contract.getRevenueShareRatio() != null
                        ? contract.getRevenueShareRatio().doubleValue() : null);
                data.put("startedAt", contract.getStartedAt() != null ? contract.getStartedAt().toString() : null);
                data.put("expiresAt", contract.getExpiresAt() != null ? contract.getExpiresAt().toString() : null);
                data.put("signedBy", contract.getSignedBy() != null ? String.valueOf(contract.getSignedBy()) : null);
                data.put("billingModel", contract.getBillingModel());
                data.put("contractId", contract.getContractNumber());
            }
        } catch (Exception ignored) {}

        // Subscription info
        try {
            var sub = subscriptionQueryService.findByTenantId(tenantId).orElse(null);
            if (sub != null) {
                data.put("serviceTier", sub.getEffectiveTier() != null ? sub.getEffectiveTier() : sub.getTier());
                data.put("serviceStatus", sub.getStatus());
                data.put("serviceExpiresAt", sub.getExpiresAt() != null ? sub.getExpiresAt().toString() : null);
            }
        } catch (Exception ignored) {}

        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    // ── Farms (B2B view) ────────────────────────────────────────

    /**
     * GET /api/v1/b2b/farms
     * 列出当前租户所有牧场（含 worker/livestock/device 统计）。
     */
    @GetMapping("/farms")
    public ResponseEntity<ApiResponse<Map<String, Object>>> farms() {
        Long tenantId = requireTenantId();

        List<FarmDto> farmDtos = farmApplicationService.listFarms(tenantId);
        List<Map<String, Object>> items = new ArrayList<>();
        int totalWorkers = 0;

        for (FarmDto farm : farmDtos) {
            long livestockCount = livestockRepository.countByFarmId(farm.id());
            long workerCount = assignmentRepository.countByFarmIdAndStatus(farm.id(), "ACTIVE");
            long deviceCount = countDevicesForFarm(farm.id());
            totalWorkers += workerCount;

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", String.valueOf(farm.id()));
            item.put("name", farm.name());
            item.put("workerCount", workerCount);
            item.put("livestockCount", livestockCount);
            item.put("deviceCount", deviceCount);
            items.add(item);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", items);
        data.put("totalWorkers", totalWorkers);
        data.put("offlineWorkerCount", 0);
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    // ── Farm Workers ────────────────────────────────────────────

    /**
     * GET /api/v1/b2b/farms/{farmId}/workers
     * 列出指定牧场的所有 ACTIVE 成员。
     */
    @GetMapping("/farms/{farmId}/workers")
    public ResponseEntity<ApiResponse<Map<String, Object>>> farmWorkers(@PathVariable Long farmId) {
        Long tenantId = requireTenantId();
        verifyFarmBelongsToTenant(farmId, tenantId);

        List<UserFarmAssignmentJpaEntity> assignments =
                assignmentRepository.findByFarmIdAndStatus(farmId, "ACTIVE");

        List<Map<String, Object>> items = assignments.stream().map(a -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", String.valueOf(a.getUserId()));
            item.put("role", a.getRole());
            item.put("status", a.getStatus());
            item.put("assignedAt", a.getCreatedAt() != null ? a.getCreatedAt().toString() : null);
            userRepository.findById(a.getUserId()).ifPresent(user -> {
                item.put("name", user.getName());
            });
            return item;
        }).toList();

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", items);
        data.put("total", items.size());
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/b2b/farms/{farmId}/workers
     * 分配牧工到指定牧场。
     */
    @PostMapping("/farms/{farmId}/workers")
    public ResponseEntity<ApiResponse<Map<String, Object>>> assignWorker(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = requireTenantId();
        verifyFarmBelongsToTenant(farmId, tenantId);

        Long workerId = requireLong(body, "workerId");

        // Verify worker belongs to same tenant
        User worker = userRepository.findById(workerId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "用户不存在: " + workerId));
        if (!tenantId.equals(worker.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "不能跨租户分配牧工");
        }

        if (assignmentRepository.existsByUserIdAndFarmId(workerId, farmId)) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE, "牧工已在该牧场中");
        }

        assignmentRepository.save(workerId, farmId, "WORKER", "ACTIVE");

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("userId", workerId);
        data.put("farmId", farmId);
        data.put("role", "WORKER");
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * DELETE /api/v1/b2b/farms/{farmId}/workers/{workerId}
     * 从指定牧场移除牧工。
     */
    @DeleteMapping("/farms/{farmId}/workers/{workerId}")
    public ResponseEntity<ApiResponse<Void>> removeWorker(
            @PathVariable Long farmId,
            @PathVariable Long workerId) {
        Long tenantId = requireTenantId();
        verifyFarmBelongsToTenant(farmId, tenantId);

        if (!assignmentRepository.existsByUserIdAndFarmId(workerId, farmId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "该牧工不在此牧场中");
        }
        assignmentRepository.updateStatus(workerId, farmId, "DISABLED");
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    // ── Available Workers ───────────────────────────────────────

    /**
     * GET /api/v1/b2b/available-workers
     * 列出当前租户内未分配到任何 ACTIVE 牧场的 worker。
     */
    @GetMapping("/available-workers")
    public ResponseEntity<ApiResponse<Map<String, Object>>> availableWorkers() {
        Long tenantId = requireTenantId();

        List<User> allWorkers = userRepository.findByTenantId(tenantId).stream()
                .filter(u -> "WORKER".equals(u.getRole().name()) && u.isActive())
                .toList();

        // Get all active assignments for this tenant
        List<UserFarmAssignmentJpaEntity> activeAssignments =
                assignmentRepository.findByTenantIdAndStatus(tenantId, "ACTIVE");
        Set<Long> assignedUserIds = new HashSet<>();
        for (UserFarmAssignmentJpaEntity a : activeAssignments) {
            assignedUserIds.add(a.getUserId());
        }

        List<Map<String, Object>> items = allWorkers.stream()
                .filter(w -> !assignedUserIds.contains(w.getId()))
                .map(w -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("id", String.valueOf(w.getId()));
                    item.put("name", w.getName());
                    item.put("role", "worker");
                    item.put("status", "active");
                    return item;
                }).toList();

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", items);
        data.put("total", items.size());
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    // ── Users ───────────────────────────────────────────────────

    /**
     * GET /api/v1/b2b/users
     * 列出当前租户的所有用户。
     */
    @GetMapping("/users")
    public ResponseEntity<ApiResponse<Map<String, Object>>> users(
            @RequestParam(required = false) String role) {
        Long tenantId = requireTenantId();

        List<UserDto> allUsers = userRepository.findByTenantId(tenantId).stream()
                .map(UserDto::from)
                .filter(u -> role == null || role.equalsIgnoreCase(u.role()))
                .toList();

        List<Map<String, Object>> items = allUsers.stream().map(u -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", u.id());
            item.put("name", u.name());
            item.put("phone", u.phone());
            item.put("role", u.role());
            return item;
        }).toList();

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", items);
        data.put("total", items.size());
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    // ── Device count helper ─────────────────────────────────────

    private long countDevicesForFarm(Long farmId) {
        List<LivestockDto> livestock = livestockApplicationService.listByFarm(farmId);
        if (livestock.isEmpty()) return 0;
        List<Long> livestockIds = livestock.stream().map(LivestockDto::id).toList();
        List<InstallationDto> installations = installationApplicationService.findByLivestockIds(livestockIds);
        return installations.stream().map(InstallationDto::deviceId).distinct().count();
    }

    // ── Helpers ─────────────────────────────────────────────────

    private Long requireTenantId() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证或缺少租户信息");
        }
        requireB2bAdmin();
        return tenantId;
    }

    private void requireB2bAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        boolean isB2bAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_B2B_ADMIN"));
        if (!isB2bAdmin) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "需要 B2B_ADMIN 角色");
        }
    }

    private void verifyFarmBelongsToTenant(Long farmId, Long tenantId) {
        Farm farm = farmRepository.findById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        if (!tenantId.equals(farm.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
    }

    private Long requireLong(Map<String, Object> body, String field) {
        Object value = body.get(field);
        if (value == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return ((Number) value).longValue();
    }
}
