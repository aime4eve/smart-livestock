package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.TileAdminService;
import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.application.dto.TileSourceDto;
import com.smartlivestock.ranch.domain.model.TileDownloadLog;
import com.smartlivestock.ranch.domain.repository.TileDownloadLogRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.identity.domain.repository.FarmRepository;
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
    private final FarmRepository farmRepository;

    private void verifyFarmOwnership(Long farmId) {
        var farm = farmRepository.findById(farmId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + farmId));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.getTenantId().equals(currentTenant)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该牧场");
        }
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
