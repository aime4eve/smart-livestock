package com.smartlivestock.ranch.interfaces.open.support;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.stream.Collectors;

/**
 * Open API resource-in-farm checks (NIX-333).
 *
 * {@code ApiKeyAuthService.validateFarmAccess} only proves farm ∈ tenant; these
 * prove the addressed resource ∈ path farm. Cross-farm ids answer 404 so the
 * response does not reveal that the id exists elsewhere — the same semantics
 * the NIX-323 telemetry endpoints established.
 */
@Component
@RequiredArgsConstructor
public class OpenOwnershipGuard {

    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;
    private final AlertRepository alertRepository;

    public Livestock requireLivestockInFarm(Long livestockId, Long farmId) {
        Livestock livestock = livestockRepository.findById(livestockId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "牲畜不存在: " + livestockId));
        if (!farmId.equals(livestock.getFarmId())) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "牲畜不存在于该牧场: " + livestockId);
        }
        return livestock;
    }

    public Fence requireFenceInFarm(Long fenceId, Long farmId) {
        Fence fence = fenceRepository.findById(fenceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "围栏不存在: " + fenceId));
        if (!farmId.equals(fence.getFarmId())) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "围栏不存在于该牧场: " + fenceId);
        }
        return fence;
    }

    public Alert requireAlertInFarm(Long alertId, Long farmId) {
        Alert alert = alertRepository.findById(alertId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "告警不存在: " + alertId));
        if (!farmId.equals(alert.getFarmId())) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "告警不存在于该牧场: " + alertId);
        }
        return alert;
    }

    /** Ids of every livestock in the farm, for scoping farm-wide reads. */
    public Set<Long> livestockIdsOf(Long farmId) {
        return livestockRepository.findByFarmId(farmId).stream()
                .map(Livestock::getId)
                .collect(Collectors.toSet());
    }
}
