package com.smartlivestock.ranch.interfaces;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class TileController {

    private static final Logger log = LoggerFactory.getLogger(TileController.class);
    private static final String TILES_DIR = "/data/mbtiles";
    private static final String REGIONS_FILE = "/data/mbtiles/regions.json";

    private final IdentityQueryPort identityQueryPort;
    private final ObjectMapper objectMapper;

    public TileController(IdentityQueryPort identityQueryPort, ObjectMapper objectMapper) {
        this.identityQueryPort = identityQueryPort;
        this.objectMapper = objectMapper;
    }

    @GetMapping("/admin/tiles/status")
    public ResponseEntity<List<Map<String, Object>>> getTileStatus() {
        File dir = new File(TILES_DIR);
        if (!dir.exists()) return ResponseEntity.ok(List.of());
        File[] files = dir.listFiles((d, name) -> name.endsWith(".mbtiles"));
        if (files == null) return ResponseEntity.ok(List.of());

        var statuses = Arrays.stream(files)
            .map(f -> Map.<String, Object>of(
                "name", f.getName(),
                "size", f.length(),
                "lastModified", f.lastModified()
            ))
            .toList();
        return ResponseEntity.ok(statuses);
    }

    @GetMapping("/farms/{farmId}/offline-map")
    public ResponseEntity<Resource> downloadOfflineMap(
            @PathVariable Long farmId,
            @RequestParam(required = false) String regionName) {
        FarmInfo farm = identityQueryPort.findFarmById(farmId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Farm not found"));
        Long currentTenant = TenantContext.getCurrentTenant();
        if (currentTenant != null && !farm.tenantId().equals(currentTenant)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        String matchedFile;
        if (regionName != null && !regionName.isBlank()) {
            // Explicit region name: find by MBTiles file name
            String targetFile = regionName.endsWith(".mbtiles") ? regionName : regionName + ".mbtiles";
            Path directPath = Paths.get(TILES_DIR).resolve(targetFile).normalize();
            if (!directPath.startsWith(Paths.get(TILES_DIR).normalize())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Invalid path");
            }
            if (directPath.toFile().exists()) {
                matchedFile = targetFile;
            } else {
                matchedFile = findMatchingMbtilesByRegionName(regionName);
            }
        } else {
            matchedFile = findMatchingMbtiles(farm);
        }
        if (matchedFile == null) return ResponseEntity.notFound().build();

        Path mbtiles = Paths.get(TILES_DIR).resolve(matchedFile).normalize();
        if (!mbtiles.startsWith(Paths.get(TILES_DIR).normalize())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Invalid path");
        }
        if (!mbtiles.toFile().exists()) return ResponseEntity.notFound().build();
        Resource resource = new FileSystemResource(mbtiles);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=\"" + matchedFile + "\"")
            .header(HttpHeaders.CONTENT_TYPE, "application/x-sqlite3")
            .contentLength(mbtiles.toFile().length())
            .body(resource);
    }

    private String findMatchingMbtiles(FarmInfo farm) {
        File regionsFile = new File(REGIONS_FILE);
        if (!regionsFile.exists()) return null;
        if (farm.longitude() == null || farm.latitude() == null) return null;

        try {
            List<Map<String, Object>> regions = objectMapper.readValue(regionsFile, List.class);
            double farmLng = farm.longitude().doubleValue();
            double farmLat = farm.latitude().doubleValue();

            for (Map<String, Object> region : regions) {
                @SuppressWarnings("unchecked")
                List<Number> bounds = (List<Number>) region.get("bounds");
                if (bounds == null || bounds.size() < 4) continue;

                double minLon = bounds.get(0).doubleValue();
                double minLat = bounds.get(1).doubleValue();
                double maxLon = bounds.get(2).doubleValue();
                double maxLat = bounds.get(3).doubleValue();

                if (farmLng >= minLon && farmLat >= minLat && farmLng <= maxLon && farmLat <= maxLat) {
                    return (String) region.get("file");
                }
            }
        } catch (Exception e) {
            log.warn("Failed to read regions file: {}", e.getMessage());
        }
        return null;
    }

    private String findMatchingMbtilesByRegionName(String regionName) {
        File regionsFile = new File(REGIONS_FILE);
        if (!regionsFile.exists()) return null;
        try {
            List<Map<String, Object>> regions = objectMapper.readValue(regionsFile, List.class);
            for (Map<String, Object> region : regions) {
                String file = (String) region.get("file");
                if (file != null && file.startsWith(regionName)) {
                    return file;
                }
            }
        } catch (Exception e) {
            log.warn("Failed to read regions file: {}", e.getMessage());
        }
        return null;
    }
}
