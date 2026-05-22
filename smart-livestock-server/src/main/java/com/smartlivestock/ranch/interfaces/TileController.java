package com.smartlivestock.ranch.interfaces;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class TileController {

    private static final String TILES_DIR = "/data/mbtiles";

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
    public ResponseEntity<Resource> downloadOfflineMap(@PathVariable Long farmId) {
        Path mbtiles = Paths.get(TILES_DIR, "changsha.mbtiles");
        if (!mbtiles.toFile().exists()) return ResponseEntity.notFound().build();
        Resource resource = new FileSystemResource(mbtiles);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=\"changsha.mbtiles\"")
            .header(HttpHeaders.CONTENT_TYPE, "application/x-sqlite3")
            .contentLength(mbtiles.toFile().length())
            .body(resource);
    }
}
