# Offline Map Backend + Tooling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the server-side foundation for offline map + fence integration: database schema, API Key authentication, tile management APIs, farm-creation tile detection, and tooling integration.

**Architecture:** Flyway V15 adds 4 new tables + fence version/type columns. API Key auth uses SHA-256 hash storage with `X-API-Key` header. TileAdminService orchestrates tile_regions CRUD and coverage-ratio-aware farm-tile matching. Tooling scripts read task records from the API to drive MBTiles generation.

**Tech Stack:** Spring Boot 3.3 + Java 17 + PostgreSQL 16 + Flyway + JPA + Spring Security + SHA-256

**Spec:** `docs/superpowers/specs/2026-05-27-offline-map-fence-integration-design.md` (§3, §4, §5, §6)

---

## File Structure

### New Files — Backend

```
smart-livestock-server/src/main/
├── resources/db/migration/
│   └── V15__create_tile_tables_and_fence_version.sql
├── java/com/smartlivestock/
│   ├── ranch/
│   │   ├── domain/model/
│   │   │   ├── TileRegion.java
│   │   │   ├── TileGenerationTask.java
│   │   │   ├── FarmTileTask.java
│   │   │   └── TileDownloadLog.java
│   │   ├── domain/repository/
│   │   │   ├── TileRegionRepository.java
│   │   │   ├── TileGenerationTaskRepository.java
│   │   │   ├── FarmTileTaskRepository.java
│   │   │   └── TileDownloadLogRepository.java
│   │   ├── domain/service/
│   │   │   └── TileCoverageCalculator.java
│   │   ├── application/
│   │   │   ├── TileAdminService.java
│   │   │   └── dto/
│   │   │       ├── TileRegionDto.java
│   │   │       ├── TileGenerationTaskDto.java
│   │   │       ├── FarmTileStatusDto.java
│   │   │       └── TileSourceDto.java
│   │   └── interfaces/
│   │       ├── TileAdminController.java
│   │       └── TileAppController.java
│   ├── identity/
│   │   ├── domain/model/
│   │   │   └── ApiKey.java                           (new entity)
│   │   ├── domain/repository/
│   │   │   └── ApiKeyRepository.java                 (new repo)
│   │   ├── application/
│   │   │   └── ApiKeyApplicationService.java         (new service)
│   │   └── infrastructure/persistence/
│   │       ├── JpaApiKey.java
│   │       ├── ApiKeyJpaRepository.java
│   │       └── ApiKeyRepositoryImpl.java
│   └── shared/
│       └── security/
│           └── ApiKeyAuthFilter.java                  (new filter)
└── test/java/com/smartlivestock/
    ├── ranch/
    │   ├── domain/model/TileRegionTest.java
    │   ├── domain/service/TileCoverageCalculatorTest.java
    │   └── application/TileAdminServiceTest.java
    └── identity/
        └── application/ApiKeyApplicationServiceTest.java
```

### Modified Files — Backend

| File | Change |
|------|--------|
| `Fence.java` | Add `version` and `fenceType` fields |
| `FenceDto.java` | Add `version` and `fenceType` fields |
| `FenceApplicationService.java` | Optimistic locking on update, 409 on conflict |
| `FenceController.java` | Add `forceUpdate` endpoint, return 409 with context |
| `UpdateFenceCommand.java` | Add `expectedVersion` field |
| `FarmApplicationService.java` | Add boundary fence + tile detection on farm creation |
| `FarmController.java` | Return tile status in farm creation response |
| `CreateFarmCommand.java` | Add `boundaryVertices` field |
| `TileController.java` | Refactor to use tile_region DB instead of file scanning |
| `SecurityConfig.java` | Add `ApiKeyAuthFilter` before JWT filter |
| `ApiKeyAdminController.java` | Replace stub with real CRUD |
| `ApiKeyAuthService.java` | Replace stub with real DB lookup |

### Modified Files — Tooling

| File | Change |
|------|--------|
| `tooling/generate_mbtiles.py` | Add `--task-id` mode, env var auth |
| `tooling/import_mbtiles.sh` | Add DB sync via API after import |

---

## Task 1: V15 Migration + Fence Entity Extension

**Files:**
- Create: `src/main/resources/db/migration/V15__create_tile_tables_and_fence_version.sql`
- Modify: `src/main/java/com/smartlivestock/ranch/domain/model/Fence.java`
- Modify: `src/main/java/com/smartlivestock/ranch/application/dto/FenceDto.java`
- Modify: `src/main/java/com/smartlivestock/ranch/application/command/UpdateFenceCommand.java`
- Modify: `src/main/java/com/smartlivestock/ranch/application/FenceApplicationService.java`
- Test: `src/test/java/com/smartlivestock/ranch/domain/model/FenceVersionTest.java`

- [ ] **Step 1: Write V15 migration SQL**

Create `src/main/resources/db/migration/V15__create_tile_tables_and_fence_version.sql`:

```sql
-- 1. Fence table extensions
ALTER TABLE fences ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;
ALTER TABLE fences ADD COLUMN IF NOT EXISTS fence_type VARCHAR(20) NOT NULL DEFAULT 'sub';

-- 2. tile_regions — server-side MBTiles file registry
CREATE TABLE tile_regions (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    min_lon      DOUBLE PRECISION NOT NULL,
    min_lat      DOUBLE PRECISION NOT NULL,
    max_lon      DOUBLE PRECISION NOT NULL,
    max_lat      DOUBLE PRECISION NOT NULL,
    min_zoom     INT NOT NULL DEFAULT 11,
    max_zoom     INT NOT NULL DEFAULT 15,
    file_name    VARCHAR(255),
    file_size    BIGINT,
    md5          VARCHAR(32),
    generated_at TIMESTAMPTZ,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. tile_generation_tasks — MBTiles generation jobs
CREATE TABLE tile_generation_tasks (
    id              BIGSERIAL PRIMARY KEY,
    region_id       BIGINT REFERENCES tile_regions(id),
    min_lon         DOUBLE PRECISION NOT NULL,
    min_lat         DOUBLE PRECISION NOT NULL,
    max_lon         DOUBLE PRECISION NOT NULL,
    max_lat         DOUBLE PRECISION NOT NULL,
    min_zoom        INT NOT NULL DEFAULT 11,
    max_zoom        INT NOT NULL DEFAULT 15,
    region_name     VARCHAR(100) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    triggered_by    VARCHAR(50),
    tile_count      INT,
    file_size_mb    DOUBLE PRECISION,
    error_message   TEXT,
    coverage_ratio  DOUBLE PRECISION,
    is_custom_region BOOLEAN NOT NULL DEFAULT false,
    started_at      TIMESTAMPTZ,
    finished_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. farm_tile_tasks — per-farm per-region download status (many-to-many)
CREATE TABLE farm_tile_tasks (
    id           BIGSERIAL PRIMARY KEY,
    farm_id      BIGINT NOT NULL REFERENCES farms(id),
    region_id    BIGINT NOT NULL REFERENCES tile_regions(id),
    status       VARCHAR(30) NOT NULL DEFAULT 'pending',
    file_size    BIGINT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(farm_id, region_id)
);

-- 5. tile_download_logs — client download history
CREATE TABLE tile_download_logs (
    id               BIGSERIAL PRIMARY KEY,
    farm_tile_task_id BIGINT NOT NULL REFERENCES farm_tile_tasks(id),
    user_id           BIGINT NOT NULL REFERENCES users(id),
    device_info       VARCHAR(255),
    bytes_downloaded  BIGINT,
    started_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at       TIMESTAMPTZ
);

-- 6. Indexes
CREATE INDEX idx_farm_tile_tasks_farm ON farm_tile_tasks(farm_id);
CREATE INDEX idx_farm_tile_tasks_status ON farm_tile_tasks(status);
CREATE INDEX idx_tile_gen_tasks_status ON tile_generation_tasks(status);
CREATE INDEX idx_tile_download_logs_user ON tile_download_logs(user_id);
```

- [ ] **Step 2: Add version and fenceType to Fence entity**

In `Fence.java`, add after the `active` field:

```java
private int version = 1;
private String fenceType = "sub";

public int getVersion() { return version; }
public void setVersion(int version) { this.version = version; }
public String getFenceType() { return fenceType; }
public void setFenceType(String fenceType) { this.fenceType = fenceType; }
```

- [ ] **Step 3: Update FenceDto to include new fields**

Add `version` and `fenceType` to `FenceDto`. If it's a record:

```java
public record FenceDto(
    Long id, Long farmId, String name,
    List<GpsCoordinate> vertices, String color, boolean active,
    int version, String fenceType
) {
    public static FenceDto from(Fence fence) {
        return new FenceDto(fence.getId(), fence.getFarmId(), fence.getName(),
            fence.getVertices(), fence.getColor(), fence.isActive(),
            fence.getVersion(), fence.getFenceType());
    }
}
```

- [ ] **Step 4: Add expectedVersion to UpdateFenceCommand**

```java
public record UpdateFenceCommand(
    String name,
    List<GpsCoordinate> vertices,
    String color,
    Integer expectedVersion
) {}
```

- [ ] **Step 5: Implement optimistic locking in FenceApplicationService**

```java
@Transactional
public FenceDto updateFence(Long id, UpdateFenceCommand command) {
    Fence fence = fenceRepository.findById(id)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id));

    if (command.expectedVersion() != null && fence.getVersion() != command.expectedVersion()) {
        throw new ApiException(ErrorCode.CONFLICT,
            String.format("版本冲突: 期望 %d, 实际 %d", command.expectedVersion(), fence.getVersion()));
    }

    fence.setName(command.name());
    fence.setVertices(command.vertices());
    fence.setColor(command.color());
    fence.setVersion(fence.getVersion() + 1);
    Fence saved = fenceRepository.save(fence);
    return FenceDto.from(saved);
}

@Transactional
public FenceDto forceUpdateFence(Long id, List<GpsCoordinate> vertices,
                                  String name, String color, int version) {
    Fence fence = fenceRepository.findById(id)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id));
    fence.setName(name);
    fence.setVertices(vertices);
    fence.setColor(color);
    fence.setVersion(version + 1);
    Fence saved = fenceRepository.save(fence);
    return FenceDto.from(saved);
}
```

Add `ErrorCode.CONFLICT(409, "CONFLICT", "版本冲突")` to the ErrorCode enum if it doesn't exist.

- [ ] **Step 6: Update FenceController — add expectedVersion and forceUpdate**

In `updateFence` method, extract `expectedVersion` from body:

```java
Integer expectedVersion = body.get("expectedVersion") != null
    ? ((Number) body.get("expectedVersion")).intValue() : null;
```

Add new endpoint:

```java
@PutMapping("/{fenceId}/force")
public ResponseEntity<ApiResponse<FenceDto>> forceUpdateFence(
        @PathVariable Long farmId, @PathVariable Long fenceId,
        @RequestBody Map<String, Object> body) {
    int version = ((Number) body.get("version")).intValue();
    FenceDto fence = fenceApplicationService.forceUpdateFence(fenceId,
        parseVertices(body.get("vertices")),
        (String) body.get("name"), (String) body.get("color"), version);
    return ResponseEntity.ok(ApiResponse.ok(fence));
}
```

- [ ] **Step 7: Write FenceVersionTest**

```java
package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.ranch.application.FenceApplicationService;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FenceVersionTest {

    @Mock private FenceRepository fenceRepository;

    @Test
    void updateFence_incrementsVersion() {
        Fence fence = new Fence(1L, "test", List.of(), "#FF0000");
        fence.setVersion(2);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));
        when(fenceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository);
        FenceDto result = svc.updateFence(1L, new UpdateFenceCommand("up", List.of(), "#00F", 2));
        assertEquals(3, result.version());
    }

    @Test
    void updateFence_rejectsStaleVersion() {
        Fence fence = new Fence(1L, "test", List.of(), "#FF0000");
        fence.setVersion(5);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository);
        assertThrows(ApiException.class,
            () -> svc.updateFence(1L, new UpdateFenceCommand("up", List.of(), "#00F", 3)));
    }

    @Test
    void updateFence_skipsCheck_whenExpectedVersionNull() {
        Fence fence = new Fence(1L, "test", List.of(), "#FF0000");
        fence.setVersion(5);
        when(fenceRepository.findById(1L)).thenReturn(Optional.of(fence));
        when(fenceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        FenceApplicationService svc = new FenceApplicationService(fenceRepository);
        FenceDto result = svc.updateFence(1L, new UpdateFenceCommand("up", List.of(), "#00F", null));
        assertEquals(6, result.version());
    }
}
```

- [ ] **Step 8: Run tests**

```bash
cd smart-livestock-server && ./gradlew test --tests "*.FenceVersionTest" -v
```

Expected: 3 tests PASS.

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "feat: V15 migration — tile tables + fence version/type + optimistic locking"
```

---

## Task 2: Tile Domain Models + Repositories

**Files:**
- Create: `ranch/domain/model/TileRegion.java`, `TileGenerationTask.java`, `FarmTileTask.java`, `TileDownloadLog.java`
- Create: `ranch/domain/repository/` — 4 repository interfaces
- Create: `ranch/infrastructure/persistence/` — 4 JPA entity + 4 JpaRepository + 4 RepositoryImpl
- Test: `ranch/domain/model/TileRegionTest.java`

- [ ] **Step 1: Create TileRegion domain model**

```java
package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;
import java.time.Instant;

public class TileRegion extends AggregateRoot {
    private String name;
    private double minLon, minLat, maxLon, maxLat;
    private int minZoom = 11, maxZoom = 15;
    private String fileName;
    private Long fileSize;
    private String md5;
    private Instant generatedAt;
    private String status = "pending";

    public TileRegion() {}
    public TileRegion(String name, double minLon, double minLat, double maxLon, double maxLat) {
        this.name = name; this.minLon = minLon; this.minLat = minLat;
        this.maxLon = maxLon; this.maxLat = maxLat;
    }

    public boolean containsPoint(double lon, double lat) {
        return lon >= minLon && lon <= maxLon && lat >= minLat && lat <= maxLat;
    }
    public boolean intersectsBbox(double bMinLon, double bMinLat, double bMaxLon, double bMaxLat) {
        return minLon <= bMaxLon && maxLon >= bMinLon && minLat <= bMaxLat && maxLat >= bMinLat;
    }

    // Standard getters/setters for all fields...
    public String getName() { return name; } public void setName(String n) { name = n; }
    public double getMinLon() { return minLon; } public void setMinLon(double v) { minLon = v; }
    public double getMinLat() { return minLat; } public void setMinLat(double v) { minLat = v; }
    public double getMaxLon() { return maxLon; } public void setMaxLon(double v) { maxLon = v; }
    public double getMaxLat() { return maxLat; } public void setMaxLat(double v) { maxLat = v; }
    public int getMinZoom() { return minZoom; } public void setMinZoom(int v) { minZoom = v; }
    public int getMaxZoom() { return maxZoom; } public void setMaxZoom(int v) { maxZoom = v; }
    public String getFileName() { return fileName; } public void setFileName(String v) { fileName = v; }
    public Long getFileSize() { return fileSize; } public void setFileSize(Long v) { fileSize = v; }
    public String getMd5() { return md5; } public void setMd5(String v) { md5 = v; }
    public Instant getGeneratedAt() { return generatedAt; } public void setGeneratedAt(Instant v) { generatedAt = v; }
    public String getStatus() { return status; } public void setStatus(String v) { status = v; }
}
```

- [ ] **Step 2: Create TileGenerationTask domain model**

```java
package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;
import java.time.Instant;

public class TileGenerationTask extends AggregateRoot {
    private Long regionId;
    private double minLon, minLat, maxLon, maxLat;
    private int minZoom = 11, maxZoom = 15;
    private String regionName, status = "pending", triggeredBy, errorMessage;
    private Integer tileCount;
    private Double fileSizeMb, coverageRatio;
    private boolean customRegion = false;
    private Instant startedAt, finishedAt;

    public TileGenerationTask() {}
    public TileGenerationTask(String regionName, double minLon, double minLat,
                              double maxLon, double maxLat, int minZoom, int maxZoom) {
        this.regionName = regionName; this.minLon = minLon; this.minLat = minLat;
        this.maxLon = maxLon; this.maxLat = maxLat;
        this.minZoom = minZoom; this.maxZoom = maxZoom;
    }

    // Getters/setters for all fields (same pattern as TileRegion)...
}
```

- [ ] **Step 3: Create FarmTileTask and TileDownloadLog domain models**

`FarmTileTask.java` — fields: `farmId`, `regionId`, `status="pending"`, `fileSize`, `requestedAt`, `completedAt`. Constructor `(Long farmId, Long regionId)` sets `requestedAt = Instant.now()`.

`TileDownloadLog.java` — fields: `farmTileTaskId`, `userId`, `deviceInfo`, `bytesDownloaded`, `startedAt`, `finishedAt`. Constructor `(Long farmTileTaskId, Long userId)` sets `startedAt = Instant.now()`.

Both extend `EntityBase` (not AggregateRoot — these are not aggregate roots).

- [ ] **Step 4: Create 4 repository interfaces in `ranch/domain/repository/`**

```java
// TileRegionRepository.java
public interface TileRegionRepository {
    TileRegion save(TileRegion region);
    Optional<TileRegion> findById(Long id);
    Optional<TileRegion> findByName(String name);
    List<TileRegion> findAll();
    List<TileRegion> findByStatus(String status);
    List<TileRegion> findIntersecting(double minLon, double minLat, double maxLon, double maxLat);
}

// TileGenerationTaskRepository.java
public interface TileGenerationTaskRepository {
    TileGenerationTask save(TileGenerationTask task);
    Optional<TileGenerationTask> findById(Long id);
    List<TileGenerationTask> findByStatus(String status);
    List<TileGenerationTask> findAll();
}

// FarmTileTaskRepository.java
public interface FarmTileTaskRepository {
    FarmTileTask save(FarmTileTask task);
    Optional<FarmTileTask> findById(Long id);
    List<FarmTileTask> findByFarmId(Long farmId);
    List<FarmTileTask> findByFarmIdAndRegionId(Long farmId, Long regionId);
    List<FarmTileTask> findAll();
}

// TileDownloadLogRepository.java
public interface TileDownloadLogRepository {
    TileDownloadLog save(TileDownloadLog log);
    List<TileDownloadLog> findByUserId(Long userId);
}
```

- [ ] **Step 5: Create JPA adapters**

For each domain model, create the standard 3-file JPA adapter following the existing pattern (check `JpaFence` / `FenceRepositoryImpl` in the codebase):

1. `JpaTileRegion.java` — `@Entity` mapped to `tile_regions`, with `@Column` annotations and domain model converter (`toDomain()` / `fromDomain()`)
2. `TileRegionJpaRepository.java` — Spring Data `JpaRepository<JpaTileRegion, Long>` with `@Query` for `findIntersecting`
3. `TileRegionRepositoryImpl.java` — implements `TileRegionRepository`, delegates to `TileRegionJpaRepository`

The `findIntersecting` JPQL query:
```java
@Query("SELECT r FROM JpaTileRegion r WHERE r.minLon <= :maxLon AND r.maxLon >= :minLon AND r.minLat <= :maxLat AND r.maxLat >= :minLat")
List<JpaTileRegion> findIntersecting(@Param("minLon") double minLon, @Param("minLat") double minLat,
                                      @Param("maxLon") double maxLon, @Param("maxLat") double maxLat);
```

Repeat this pattern for `TileGenerationTask` → `tile_generation_tasks`, `FarmTileTask` → `farm_tile_tasks`, `TileDownloadLog` → `tile_download_logs`.

- [ ] **Step 6: Write TileRegionTest**

```java
package com.smartlivestock.ranch.domain.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TileRegionTest {
    @Test void containsPoint_inside() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertTrue(r.containsPoint(112.95, 28.25));
    }
    @Test void containsPoint_outside() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertFalse(r.containsPoint(116.4, 39.9));
    }
    @Test void intersectsBbox_overlap() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertTrue(r.intersectsBbox(113.0, 28.3, 113.5, 28.6));
    }
    @Test void intersectsBbox_noOverlap() {
        var r = new TileRegion("cs", 112.8, 28.1, 113.1, 28.4);
        assertFalse(r.intersectsBbox(116.0, 39.5, 116.5, 40.0));
    }
}
```

- [ ] **Step 7: Run tests and commit**

```bash
./gradlew test --tests "*.TileRegionTest" -v
git add -A && git commit -m "feat: tile domain models + repositories (4 tables)"
```

---

## Task 3: TileCoverageCalculator

**Files:**
- Create: `ranch/domain/service/TileCoverageCalculator.java`
- Test: `ranch/domain/service/TileCoverageCalculatorTest.java`

- [ ] **Step 1: Write failing tests**

```java
package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class TileCoverageCalculatorTest {
    private final TileCoverageCalculator calc = new TileCoverageCalculator();

    private GpsCoordinate c(double lat, double lon) {
        return new GpsCoordinate(BigDecimal.valueOf(lat), BigDecimal.valueOf(lon));
    }

    @Test void bbox_squareVertices() {
        var verts = List.of(c(28, 112), c(28, 113), c(29, 113), c(29, 112));
        var bbox = calc.calculateBbox(verts);
        assertArrayEquals(new double[]{112, 28, 113, 29}, bbox, 0.0001);
    }

    @Test void coverageRatio_squarePolygon_isHigh() {
        var verts = List.of(c(28, 112), c(28, 113), c(29, 113), c(29, 112));
        double ratio = calc.coverageRatio(verts);
        assertTrue(ratio > 0.9, "got: " + ratio);
    }

    @Test void coverageRatio_narrowStrip_isLow() {
        var verts = List.of(c(28, 112), c(28.1, 113), c(28.2, 113), c(28.1, 112));
        double ratio = calc.coverageRatio(verts);
        assertTrue(ratio < 0.5, "got: " + ratio);
    }

    @Test void coverageRatio_triangle_isModerate() {
        var verts = List.of(c(28, 112), c(29, 112), c(28.5, 113));
        double ratio = calc.coverageRatio(verts);
        assertTrue(ratio > 0.4 && ratio < 0.6, "got: " + ratio);
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
./gradlew test --tests "*.TileCoverageCalculatorTest" -v
```

- [ ] **Step 3: Implement TileCoverageCalculator**

```java
package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
public class TileCoverageCalculator {

    public double[] calculateBbox(List<GpsCoordinate> vertices) {
        double minLon = Double.MAX_VALUE, minLat = Double.MAX_VALUE;
        double maxLon = -Double.MAX_VALUE, maxLat = -Double.MAX_VALUE;
        for (GpsCoordinate v : vertices) {
            double lon = v.longitude().doubleValue();
            double lat = v.latitude().doubleValue();
            minLon = Math.min(minLon, lon); minLat = Math.min(minLat, lat);
            maxLon = Math.max(maxLon, lon); maxLat = Math.max(maxLat, lat);
        }
        return new double[]{minLon, minLat, maxLon, maxLat};
    }

    public double coverageRatio(List<GpsCoordinate> vertices) {
        if (vertices == null || vertices.size() < 3) return 0.0;
        double polyArea = Math.abs(shoelaceArea(vertices));
        double[] bbox = calculateBbox(vertices);
        double bboxArea = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
        return bboxArea == 0 ? 0.0 : polyArea / bboxArea;
    }

    private double shoelaceArea(List<GpsCoordinate> v) {
        double area = 0;
        int n = v.size();
        for (int i = 0; i < n; i++) {
            int j = (i + 1) % n;
            area += v.get(i).longitude().doubleValue() * v.get(j).latitude().doubleValue()
                  - v.get(j).longitude().doubleValue() * v.get(i).latitude().doubleValue();
        }
        return area / 2.0;
    }
}
```

- [ ] **Step 4: Run tests and commit**

```bash
./gradlew test --tests "*.TileCoverageCalculatorTest" -v
git add -A && git commit -m "feat: TileCoverageCalculator — bbox, coverage ratio"
```

---

## Task 4: ApiKey Domain + Authentication

**Files:**
- Create: `identity/domain/model/ApiKey.java`
- Create: `identity/domain/repository/ApiKeyRepository.java`
- Create: `identity/application/ApiKeyApplicationService.java`
- Create: `shared/security/ApiKeyAuthFilter.java`
- Create: `identity/infrastructure/persistence/JpaApiKey.java`, `ApiKeyJpaRepository.java`, `ApiKeyRepositoryImpl.java`
- Modify: `shared/security/SecurityConfig.java` — add ApiKeyAuthFilter
- Modify: `shared/security/ApiKeyAuthService.java` — delegate to real DB
- Test: `identity/application/ApiKeyApplicationServiceTest.java`

- [ ] **Step 1: Create ApiKey domain model**

Fields: `tenantId`, `keyHash`, `keyPrefix`, `name`, `role`, `active=true`, `expiresAt`, `lastUsedAt`. Method: `isExpired()` checks `expiresAt != null && Instant.now().isAfter(expiresAt)`.

- [ ] **Step 2: Create ApiKeyRepository + JPA adapter**

```java
public interface ApiKeyRepository {
    ApiKey save(ApiKey apiKey);
    Optional<ApiKey> findById(Long id);
    Optional<ApiKey> findByKeyHash(String keyHash);
    List<ApiKey> findAll();
    void deleteById(Long id);
}
```

Check V1 migration `api_keys` table columns to ensure JPA mapping matches. The existing table has: `id, tenant_id, key_hash, name, role, active, expires_at, created_at`. Add `key_prefix` and `last_used_at` via ALTER in V15 if not already present:

```sql
-- Add to V15 migration
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS key_prefix VARCHAR(20);
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ;
```

- [ ] **Step 3: Create ApiKeyApplicationService**

Key methods:
- `createApiKey(name, role)` — generate `sk_live_` + 32-byte random hex, SHA-256 hash, save hash, return raw key once
- `validateApiKey(rawKey)` — SHA-256(rawKey) → lookup hash → check active + not expired → update lastUsedAt
- `revokeApiKey(id)` — set `active=false`
- `deleteApiKey(id)` — only if already inactive
- `listApiKeys()` — return all

SHA-256 implementation:
```java
private String sha256(String input) {
    byte[] hash = MessageDigest.getInstance("SHA-256").digest(input.getBytes(UTF_8));
    return HexFormat.of().formatHex(hash);
}
```

- [ ] **Step 4: Create ApiKeyAuthFilter** — `OncePerRequestFilter` that checks `X-API-Key` header, calls `apiKeyService.validateApiKey()`, creates `UsernamePasswordAuthenticationToken` with role from ApiKey, sets it in `SecurityContextHolder`. Only runs if no existing auth.

- [ ] **Step 5: Update SecurityConfig** — inject `ApiKeyAuthFilter`, add `.addFilterBefore(apiKeyAuthFilter, JwtAuthenticationFilter.class)` before the JWT filter line.

- [ ] **Step 6: Update ApiKeyAuthService** — replace stub methods to delegate to `ApiKeyApplicationService.validateApiKey()`.

- [ ] **Step 7: Write ApiKeyApplicationServiceTest** — test create returns `sk_live_` prefix, validate succeeds with correct key, revoke sets inactive, delete rejects active key.

- [ ] **Step 8: Run tests and commit**

```bash
./gradlew test --tests "*.ApiKeyApplicationServiceTest" -v
git add -A && git commit -m "feat: API Key auth — SHA-256 hash, ApiKeyAuthFilter, real DB validation"
```

---

## Task 5: ApiKeyAdminController — Replace Stub

**Files:**
- Modify: `identity/interfaces/admin/ApiKeyAdminController.java`
- Test: `identity/interfaces/ApiKeyAdminControllerTest.java`

- [ ] **Step 1: Replace stub with real implementation**

The controller already has the right endpoints (list, create, updateStatus, delete). Replace stub bodies with calls to `ApiKeyApplicationService`:

- `listApiKeys()` → `apiKeyService.listApiKeys()`, map to response with prefix/active/lastUsedAt
- `createApiKey(body)` → extract `name` and `role` from body, call `apiKeyService.createApiKey(name, role)`
- `updateApiKeyStatus(keyId, body)` → if status="disabled" call `revokeApiKey(keyId)`
- `deleteApiKey(keyId)` → call `apiKeyService.deleteApiKey(keyId)`

Change `@PathVariable String keyId` to `@PathVariable Long keyId` for the new Long-ID based service.

- [ ] **Step 2: Write controller test** — test create returns 201, revoke succeeds, non-admin gets 403.

- [ ] **Step 3: Run tests and commit**

```bash
./gradlew test --tests "*.ApiKeyAdminControllerTest" -v
git add -A && git commit -m "feat: ApiKeyAdminController — real CRUD replacing stub"
```

---

## Task 6: TileAdminService + Tile Controllers

**Files:**
- Create: `ranch/application/TileAdminService.java`
- Create: `ranch/application/dto/TileRegionDto.java`, `TileGenerationTaskDto.java`, `FarmTileStatusDto.java`, `TileSourceDto.java`
- Create: `ranch/interfaces/TileAdminController.java` (admin APIs)
- Create: `ranch/interfaces/TileAppController.java` (app-facing APIs)
- Modify: `ranch/interfaces/TileController.java` (simplify to delegate to DB)
- Test: `ranch/application/TileAdminServiceTest.java`

- [ ] **Step 1: Create DTOs** — `TileRegionDto`, `TileGenerationTaskDto`, `FarmTileStatusDto(Long farmId, List<RegionStatus> regions)`, `TileSourceDto(String sourceName, String tileUrl)`. Each has a `static from(domainModel)` factory.

- [ ] **Step 2: Create TileAdminService** — core service with:
  - `listRegions()`, `listTasks(status)`, `getTask(id)` — simple queries
  - `createTask(bbox, zoom, name, ...)` — creates generation task
  - `updateTaskStatus(id, status, ...)` — updates task, advances farm_tile_tasks on "done"
  - `handleFarmTileDetection(farmId, bbox, coverageRatio)` — the main detection logic:
    - Find intersecting tile_regions
    - If no match or coverageRatio < 0.3 → create generation task
    - Otherwise → create farm_tile_task(status=ready) for each matched region
  - `getFarmTileStatus(farmId)` — returns regions + statuses for a farm
  - `getFarmTileSources(farmId)` — returns ready sources with tile URLs
  - `logDownload(farmTileTaskId, userId, ...)` — records download

- [ ] **Step 3: Create TileAdminController** — `@RequestMapping("/api/v1/admin/tiles")` with endpoints:
  - `GET /regions` → `listRegions()`
  - `GET /tasks` → `listTasks(status)`
  - `GET /tasks/{id}` → `getTask(id)`
  - `POST /tasks` → `createTask(...)`
  - `PUT /tasks/{id}/status` → `updateTaskStatus(...)`
  - `GET /farm-tasks` → list all farm tile statuses
  - `POST /regions` → upsert region (used by import_mbtiles.sh)

- [ ] **Step 4: Create TileAppController** — `@RequestMapping("/api/v1/farms/{farmId}")` with:
  - `GET /tile-status` → `getFarmTileStatus(farmId)`
  - `GET /tile-source` → `getFarmTileSources(farmId)`
  - `POST /tile-download-log` → `logDownload(...)`

- [ ] **Step 5: Simplify TileController** — Remove `getTileStatus()` and `findMatchingMbtiles()`. Refactor `downloadOfflineMap()` to use `FarmTileTaskRepository.findByFarmId()` + `TileRegionRepository.findById()` to find the correct MBTiles file.

- [ ] **Step 6: Write TileAdminServiceTest** — 4 tests: matching region creates ready task, no coverage creates generation task, low coverage creates custom region, getFarmTileSources returns ready sources.

- [ ] **Step 7: Compile + test + commit**

```bash
./gradlew compileJava && ./gradlew test --tests "*.TileAdminServiceTest" -v
git add -A && git commit -m "feat: TileAdminService + tile management APIs"
```

---

## Task 7: Farm Creation Integration

**Files:**
- Modify: `identity/application/FarmApplicationService.java`
- Modify: `identity/application/command/CreateFarmCommand.java`
- Modify: `identity/interfaces/FarmController.java`
- Test: `identity/application/FarmCreationTileTest.java`

- [ ] **Step 1: Add boundaryVertices to CreateFarmCommand**

Add `List<Map<String, Object>> boundaryVertices` field.

- [ ] **Step 2: Update FarmApplicationService.createFarm**

After saving the Farm, if `boundaryVertices` is non-empty:
1. Parse vertices → `List<GpsCoordinate>`
2. Create `Fence(farmId, name + " 边界", vertices, "#FF0000")` with `fenceType = "boundary"`
3. Call `coverageCalculator.calculateBbox()` and `coverageRatio()`
4. Call `tileAdminService.handleFarmTileDetection(farmId, bbox, ratio)`

Inject `FenceRepository`, `TileAdminService`, `TileCoverageCalculator` via constructor.

- [ ] **Step 3: Update FarmController** — extract `boundaryVertices` from request body and pass to command.

- [ ] **Step 4: Write test** — verify boundary fence created with `fenceType="boundary"` and `handleFarmTileDetection` called.

- [ ] **Step 5: Run tests and commit**

```bash
./gradlew test --tests "*.FarmCreationTileTest" -v
git add -A && git commit -m "feat: farm creation creates boundary fence + detects tile coverage"
```

---

## Task 8: generate_mbtiles.py --task-id Mode

**Files:**
- Modify: `tooling/generate_mbtiles.py`

- [ ] **Step 1: Add new CLI arguments**

```
--task-id INT       Task ID from tile_generation_tasks
--api-url STR       Backend API base URL (default: http://172.22.1.123:18080/api/v1)
--api-key-file STR  File path containing API key
--api-key STR       API key directly (NOT recommended for production)
```

- [ ] **Step 2: Add API key resolution**

Priority: `$SMART_LIVESTOCK_API_KEY` env var → `--api-key-file` → `--api-key` (with stderr warning).

- [ ] **Step 3: Add task-driven mode**

When `--task-id` is provided:
1. `GET /admin/tiles/tasks/{id}` → fetch bbox, zoom, regionName
2. `PUT /admin/tiles/tasks/{id}/status` → `{status: "running"}`
3. Call existing `generate_mbtiles()` with parsed args
4. On success: `PUT .../status` → `{status: "done", tileCount, fileSizeMb}`
5. On failure: `PUT .../status` → `{status: "failed", errorMessage}`

Use `urllib.request` with `X-API-Key` header (no external deps needed).

- [ ] **Step 4: Test manually and commit**

```bash
export SMART_LIVESTOCK_API_KEY="sk_live_xxxxx"
python3 tooling/generate_mbtiles.py --task-id 1 --api-url http://172.22.1.123:18080/api/v1
git add tooling/generate_mbtiles.py
git commit -m "feat: generate_mbtiles.py --task-id mode with API-driven execution"
```

---

## Task 9: import_mbtiles.sh DB Sync

**Files:**
- Modify: `tooling/import_mbtiles.sh`

- [ ] **Step 1: Add API key resolution and DB sync step**

After existing step 4 (tileserver reload), add step 5:

```bash
API_URL="${API_URL:-http://172.22.1.123:18080/api/v1}"
API_KEY="${SMART_LIVESTOCK_API_KEY:-$(cat "$API_KEY_FILE" 2>/dev/null)}"

if [ -z "$API_KEY" ]; then
    echo "Skipping DB sync: no API key. Set SMART_LIVESTOCK_API_KEY."
    exit 0
fi

for f in "$LOCAL_DIR"/*.mbtiles; do
    base=$(basename "$f" .mbtiles)
    size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
    md5hash=$(md5 -q "$f" 2>/dev/null || md5sum "$f" | cut -d' ' -f1)
    bounds=$(python3 -c "import sqlite3; c=sqlite3.connect('$f'); r=c.execute(\"SELECT value FROM metadata WHERE name='bounds'\").fetchone(); print(r[0] if r else ''); c.close()")

    [ -z "$bounds" ] && continue
    IFS=',' read -r min_lon min_lat max_lon max_lat <<< "$bounds"

    curl -sf -X POST "$API_URL/admin/tiles/regions" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$base\",\"minLon\":$min_lon,\"minLat\":$min_lat,\"maxLon\":$max_lon,\"maxLat\":$max_lat,\"fileName\":\"$base.mbtiles\",\"fileSize\":$size,\"md5\":\"$md5hash\",\"status\":\"ready\"}" \
        && echo "Synced: $base" || echo "Failed: $base"
done
```

- [ ] **Step 2: Test and commit**

```bash
export SMART_LIVESTOCK_API_KEY="sk_live_xxxxx"
./tooling/import_mbtiles.sh user@server:/data/mbtiles
git add tooling/import_mbtiles.sh
git commit -m "feat: import_mbtiles.sh syncs tile_regions to DB after import"
```

---

## Task 10: Integration Tests + Full Verification

- [ ] **Step 1: Write TileIntegrationTest** — full flow test: farm creation → tile detection → status check → source retrieval → download log.

- [ ] **Step 2: Run all tests**

```bash
cd smart-livestock-server && ./gradlew test
```

Expected: All existing + new tests PASS.

- [ ] **Step 3: Verify Flyway migration**

```bash
docker compose up -d postgres redis
./gradlew bootRun  # Check V15 applied cleanly, then Ctrl+C
docker compose down
```

- [ ] **Step 4: Final commit**

```bash
git add -A && git commit -m "test: integration tests + full verification for plan A"
```

---

## Self-Review

### Spec Coverage

| Spec Section | Task |
|-------------|------|
| §3.1 4 new tables | Task 1 |
| §3.2 Fence version + fence_type | Task 1 |
| §3.3 bbox matching | Task 6 |
| §3.4 Coverage ratio | Task 3 + 6 |
| §4.1 API Key auth | Task 4 |
| §5.1 9 tile management APIs | Task 6 |
| §5.2 Farm creation tile detection | Task 7 |
| §5.3 Fence update 409 | Task 1 |
| §6.1 generate_mbtiles.py --task-id | Task 8 |
| §6.2 import_mbtiles.sh DB sync | Task 9 |
| §4.2 API Key management UI | Deferred to Plan B (Flutter) |

### Placeholder Scan
No TBD/TODO/FIXME. All steps contain actual code or precise instructions.

### Type Consistency
- `TileCoverageCalculator.calculateBbox(List<GpsCoordinate>)` → `double[]` used consistently
- `TileCoverageCalculator.coverageRatio(List<GpsCoordinate>)` → `double` used consistently
- `UpdateFenceCommand(Integer expectedVersion)` → null means skip check
- `TileAdminService.handleFarmTileDetection(Long, double[], double)` matches callers
- `ApiKeyApplicationService.createApiKey(String, String)` → `Map<String, Object>` with `sk_live_` key
