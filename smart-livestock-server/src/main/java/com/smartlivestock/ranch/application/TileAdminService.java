package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.application.dto.TileGenerationTaskDto;
import com.smartlivestock.ranch.application.dto.TileRegionDto;
import com.smartlivestock.ranch.application.dto.TileSourceDto;
import com.smartlivestock.ranch.domain.model.FarmTileTask;
import com.smartlivestock.ranch.domain.model.TileGenerationTask;
import com.smartlivestock.ranch.domain.model.TileRegion;
import com.smartlivestock.ranch.domain.repository.FarmTileTaskRepository;
import com.smartlivestock.ranch.domain.repository.TileGenerationTaskRepository;
import com.smartlivestock.ranch.domain.repository.TileDownloadLogRepository;
import com.smartlivestock.ranch.domain.repository.TileRegionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TileAdminService {

    private final TileRegionRepository tileRegionRepository;
    private final TileGenerationTaskRepository tileGenerationTaskRepository;
    private final FarmTileTaskRepository farmTileTaskRepository;
    private final TileDownloadLogRepository tileDownloadLogRepository;

    @Value("${app.tile-server.base-url:http://172.22.1.123:18080}")
    private String tileServerBaseUrl;

    @Transactional(readOnly = true)
    public List<TileRegionDto> listRegions() {
        return tileRegionRepository.findAll().stream().map(TileRegionDto::from).toList();
    }

    @Transactional(readOnly = true)
    public List<TileGenerationTaskDto> listTasks(String status) {
        List<TileGenerationTask> tasks = status != null
                ? tileGenerationTaskRepository.findByStatus(status)
                : tileGenerationTaskRepository.findAll();
        return tasks.stream().map(TileGenerationTaskDto::from).toList();
    }

    @Transactional(readOnly = true)
    public TileGenerationTaskDto getTask(Long id) {
        return tileGenerationTaskRepository.findById(id)
                .map(TileGenerationTaskDto::from)
                .orElseThrow(() -> new com.smartlivestock.shared.common.ApiException(
                        com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "任务不存在: " + id));
    }

    @Transactional
    public TileGenerationTaskDto createTask(String regionName, double minLon, double minLat,
                                             double maxLon, double maxLat, int minZoom, int maxZoom,
                                             Double coverageRatio, boolean customRegion) {
        TileGenerationTask task = new TileGenerationTask(regionName, minLon, minLat, maxLon, maxLat, minZoom, maxZoom);
        task.setCoverageRatio(coverageRatio);
        task.setCustomRegion(customRegion);
        TileGenerationTask saved = tileGenerationTaskRepository.save(task);
        return TileGenerationTaskDto.from(saved);
    }

    @Transactional
    public TileGenerationTaskDto updateTaskStatus(Long id, String status, Integer tileCount,
                                                    Double fileSizeMb, String errorMessage) {
        TileGenerationTask task = tileGenerationTaskRepository.findById(id)
                .orElseThrow(() -> new com.smartlivestock.shared.common.ApiException(
                        com.smartlivestock.shared.common.ErrorCode.RESOURCE_NOT_FOUND, "任务不存在: " + id));
        task.setStatus(status);
        if (tileCount != null) task.setTileCount(tileCount);
        if (fileSizeMb != null) task.setFileSizeMb(fileSizeMb);
        if (errorMessage != null) task.setErrorMessage(errorMessage);
        if ("running".equals(status)) task.setStartedAt(Instant.now());
        if ("done".equals(status) || "failed".equals(status)) task.setFinishedAt(Instant.now());

        if ("done".equals(status)) {
            advanceFarmTileTasks(task);
        }

        TileGenerationTask saved = tileGenerationTaskRepository.save(task);
        return TileGenerationTaskDto.from(saved);
    }

    @Transactional
    public FarmTileStatusDto handleFarmTileDetection(Long farmId, double[] bbox, double coverageRatio) {
        List<TileRegion> intersecting = tileRegionRepository.findIntersecting(
                bbox[0], bbox[1], bbox[2], bbox[3]);

        boolean coverageWarning = coverageRatio >= 0.3 && coverageRatio < 0.5;

        if (intersecting.isEmpty() || coverageRatio < 0.3) {
            TileGenerationTask genTask = new TileGenerationTask(
                    "custom-farm-" + farmId, bbox[0], bbox[1], bbox[2], bbox[3], 11, 15);
            genTask.setCoverageRatio(coverageRatio);
            genTask.setCustomRegion(true);
            tileGenerationTaskRepository.save(genTask);

            List<FarmTileStatusDto.RegionStatus> regions = List.of();
            return new FarmTileStatusDto(farmId, regions, coverageRatio, coverageRatio < 0.3);
        }

        for (TileRegion region : intersecting) {
            if (farmTileTaskRepository.findByFarmIdAndRegionId(farmId, region.getId()).isPresent()) {
                continue;
            }
            FarmTileTask farmTask = new FarmTileTask(farmId, region.getId());
            String taskStatus = "ready".equals(region.getStatus()) ? "ready" : "pending";
            farmTask.setStatus(taskStatus);
            farmTileTaskRepository.save(farmTask);
        }

        List<FarmTileStatusDto.RegionStatus> regionStatuses = intersecting.stream()
                .map(r -> new FarmTileStatusDto.RegionStatus(
                        r.getId(), r.getName(), r.getStatus(), r.getFileSize(), r.getFileName(), r.getMd5()))
                .toList();

        return new FarmTileStatusDto(farmId, regionStatuses, coverageRatio, coverageWarning);
    }

    @Transactional(readOnly = true)
    public FarmTileStatusDto getFarmTileStatus(Long farmId) {
        List<FarmTileTask> tasks = farmTileTaskRepository.findByFarmId(farmId);
        List<Long> regionIds = tasks.stream().map(FarmTileTask::getRegionId).toList();
        java.util.Map<Long, TileRegion> regionMap = tileRegionRepository.findAllByIds(regionIds).stream()
                .collect(java.util.stream.Collectors.toMap(TileRegion::getId, r -> r));
        List<FarmTileStatusDto.RegionStatus> regions = tasks.stream()
                .map(t -> {
                    TileRegion region = regionMap.get(t.getRegionId());
                    return new FarmTileStatusDto.RegionStatus(
                            t.getRegionId(),
                            region != null ? region.getName() : "unknown",
                            t.getStatus(),
                            t.getFileSize(),
                            region != null ? region.getFileName() : null,
                            region != null ? region.getMd5() : null);
                })
                .toList();
        return new FarmTileStatusDto(farmId, regions, 0, false);
    }

    @Transactional(readOnly = true)
    public List<FarmTileStatusDto> listFarmTileStatuses() {
        List<Long> farmIds = farmTileTaskRepository.findAllDistinctFarmIds();
        return farmIds.stream()
                .map(this::getFarmTileStatus)
                .filter(s -> !s.regions().isEmpty())
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TileSourceDto> getFarmTileSources(Long farmId) {
        List<FarmTileTask> tasks = farmTileTaskRepository.findByFarmId(farmId).stream()
                .filter(t -> "ready".equals(t.getStatus()) || "downloaded".equals(t.getStatus()))
                .toList();
        List<Long> regionIds = tasks.stream().map(FarmTileTask::getRegionId).toList();
        java.util.Map<Long, TileRegion> regionMap = tileRegionRepository.findAllByIds(regionIds).stream()
                .collect(java.util.stream.Collectors.toMap(TileRegion::getId, r -> r));
        return tasks.stream()
                .map(t -> regionMap.get(t.getRegionId()))
                .filter(java.util.Objects::nonNull)
                .filter(r -> "ready".equals(r.getStatus()))
                .map(r -> new TileSourceDto(r.getName(),
                        tileServerBaseUrl + "/tiles/" + r.getName() + "/{z}/{x}/{y}.png"))
                .toList();
    }

    @Transactional
    public TileRegionDto upsertRegion(String name, double minLon, double minLat, double maxLon, double maxLat,
                                       int minZoom, int maxZoom, String fileName, Long fileSize,
                                       String md5, String status) {
        TileRegion existing = tileRegionRepository.findByName(name).orElse(null);
        if (existing != null) {
            existing.setMinLon(minLon); existing.setMinLat(minLat);
            existing.setMaxLon(maxLon); existing.setMaxLat(maxLat);
            existing.setMinZoom(minZoom); existing.setMaxZoom(maxZoom);
            existing.setFileName(fileName); existing.setFileSize(fileSize);
            existing.setMd5(md5); existing.setStatus(status);
            existing.setGeneratedAt(Instant.now());
            return TileRegionDto.from(tileRegionRepository.save(existing));
        }
        TileRegion region = new TileRegion(name, minLon, minLat, maxLon, maxLat);
        region.setMinZoom(minZoom); region.setMaxZoom(maxZoom);
        region.setFileName(fileName); region.setFileSize(fileSize);
        region.setMd5(md5); region.setStatus(status);
        region.setGeneratedAt(Instant.now());
        return TileRegionDto.from(tileRegionRepository.save(region));
    }

    private void advanceFarmTileTasks(TileGenerationTask task) {
        if (task.getRegionId() != null) {
            List<FarmTileTask> pending = farmTileTaskRepository.findByRegionIdAndStatus(
                    task.getRegionId(), "pending");
            for (FarmTileTask ft : pending) {
                ft.setStatus("ready");
                farmTileTaskRepository.save(ft);
            }
        }
    }
}
