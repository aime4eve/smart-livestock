package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.TileAdminService;
import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.application.dto.TileSourceDto;
import com.smartlivestock.ranch.domain.model.TileDownloadLog;
import com.smartlivestock.ranch.domain.repository.TileDownloadLogRepository;
import com.smartlivestock.shared.common.ApiResponse;
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

    @GetMapping("/tile-status")
    public ResponseEntity<ApiResponse<FarmTileStatusDto>> getTileStatus(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.getFarmTileStatus(farmId)));
    }

    @GetMapping("/tile-source")
    public ResponseEntity<ApiResponse<List<TileSourceDto>>> getTileSource(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(tileAdminService.getFarmTileSources(farmId)));
    }

    @PostMapping("/tile-download-log")
    public ResponseEntity<ApiResponse<Void>> logDownload(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
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
