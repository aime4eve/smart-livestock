package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.TileAdminService;
import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.application.dto.TileSourceDto;
import com.smartlivestock.ranch.domain.model.TileDownloadLog;
import com.smartlivestock.ranch.domain.repository.TileDownloadLogRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class TileAppController {

    private final TileAdminService tileAdminService;
    private final TileDownloadLogRepository tileDownloadLogRepository;
    private final IdentityQueryPort identityQueryPort;

    private FarmInfo verifyFarmOwnership(Long farmId) {
        FarmInfo farm = identityQueryPort.findFarmById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
        return farm;
    }

    /** Owner/App 端触发离线瓦片生成：后端按牧场坐标算 bbox，无需 admin 权限、无需 owner 传区域。 */
    @PostMapping("/tile-tasks")
    public ResponseEntity<ApiResponse<FarmTileStatusDto>> requestTileTask(@PathVariable Long farmId) {
        FarmInfo farm = verifyFarmOwnership(farmId);
        if (farm.latitude() == null || farm.longitude() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "牧场未设置坐标，无法生成离线地图");
        }
        final double buffer = 0.15; // ~16km
        double[] bbox = {
            farm.longitude().doubleValue() - buffer,
            farm.latitude().doubleValue() - buffer,
            farm.longitude().doubleValue() + buffer,
            farm.latitude().doubleValue() + buffer,
        };
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.requestFarmTileGeneration(farmId, bbox)));
    }

    @GetMapping("/tile-status")
    public ResponseEntity<ApiResponse<FarmTileStatusDto>> getTileStatus(@PathVariable Long farmId) {
        verifyFarmOwnership(farmId);
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.getFarmTileStatus(farmId)));
    }

    @GetMapping("/tile-source")
    public ResponseEntity<ApiResponse<List<TileSourceDto>>> getTileSource(@PathVariable Long farmId) {
        verifyFarmOwnership(farmId);
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.getFarmTileSources(farmId)));
    }

    @PostMapping("/tile-download-log")
    public ResponseEntity<ApiResponse<Void>> logDownload(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        verifyFarmOwnership(farmId);
        Long farmTileTaskId = ((Number) body.get("farmTileTaskId")).longValue();
        Long userId = ((Number) body.get("userId")).longValue();
        TileDownloadLog log = new TileDownloadLog(farmTileTaskId, userId);
        log.setDeviceInfo((String) body.get("deviceInfo"));
        log.setBytesDownloaded(body.get("bytesDownloaded") != null
                ? ((Number) body.get("bytesDownloaded")).longValue() : null);
        tileDownloadLogRepository.save(log);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
