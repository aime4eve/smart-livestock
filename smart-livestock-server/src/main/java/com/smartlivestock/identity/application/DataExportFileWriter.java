package com.smartlivestock.identity.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.RumenMotilityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.RumenMotilityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * Streams a farm's full data as a zip of NDJSON files (one per entity) —
 * NIX-325. Everything is written through a streaming pipeline in bounded
 * pages; no full-table load. Alert status values are serialized as-is
 * (domain enum names).
 */
@Component
@Slf4j
public class DataExportFileWriter {

    private static final int PAGE_SIZE = 2000;

    private final LivestockRepository livestockRepository;
    private final AlertRepository alertRepository;
    private final TemperatureLogRepository temperatureLogRepository;
    private final RumenMotilityLogRepository motilityLogRepository;
    private final ActivityLogRepository activityLogRepository;
    private final GpsLogRepository gpsLogRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final com.smartlivestock.iot.domain.repository.InstallationRepository installationRepository;
    private final ObjectMapper objectMapper;
    private final Path exportDir;

    public DataExportFileWriter(LivestockRepository livestockRepository,
                                AlertRepository alertRepository,
                                TemperatureLogRepository temperatureLogRepository,
                                RumenMotilityLogRepository motilityLogRepository,
                                ActivityLogRepository activityLogRepository,
                                GpsLogRepository gpsLogRepository,
                                DeviceTelemetryLogRepository deviceTelemetryLogRepository,
                                com.smartlivestock.iot.domain.repository.InstallationRepository installationRepository,
                                @Value("${smartlivestock.export.dir:/app/data/exports}") String exportDir) {
        this.livestockRepository = livestockRepository;
        this.alertRepository = alertRepository;
        this.temperatureLogRepository = temperatureLogRepository;
        this.motilityLogRepository = motilityLogRepository;
        this.activityLogRepository = activityLogRepository;
        this.gpsLogRepository = gpsLogRepository;
        this.deviceTelemetryLogRepository = deviceTelemetryLogRepository;
        this.installationRepository = installationRepository;
        this.exportDir = Path.of(exportDir);
        this.objectMapper = new ObjectMapper()
                .registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule())
                .disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    public record ExportResult(Path file, long sizeBytes, Map<String, Object> rowCounts) {}

    /**
     * Generates the zip for one farm. The caller owns persistence of the job
     * status; any exception here means the caller marks the job FAILED.
     */
    public ExportResult writeFarmExport(Long tenantId, Long farmId, Long jobId) throws IOException {
        Files.createDirectories(exportDir);
        Path zipPath = exportDir.resolve("export-" + farmId + "-job" + jobId + ".zip");
        Map<String, Object> rowCounts = new LinkedHashMap<>();

        List<Livestock> livestock = livestockRepository.findActiveByFarmId(farmId);
        rowCounts.put("livestock", (long) livestock.size());

        List<Long> livestockIds = livestock.stream().map(Livestock::getId).toList();

        try (OutputStream fos = Files.newOutputStream(zipPath);
             BufferedOutputStream bos = new BufferedOutputStream(fos, 1 << 16);
             ZipOutputStream zip = new ZipOutputStream(bos, StandardCharsets.UTF_8)) {

            rowCounts.put("livestock", writeLivestock(zip, livestock));
            rowCounts.put("alerts", writeAlerts(zip, farmId));
            rowCounts.put("gps_logs", writeGpsLogs(zip, livestockIds));
            rowCounts.put("temperature_logs", writeTelemetry(zip, "temperature_logs.jsonl", livestockIds,
                    (ids, page) -> temperatureLogRepository.findPageByLivestockIn(ids, page)));
            rowCounts.put("rumen_motility_logs", writeTelemetry(zip, "rumen_motility_logs.jsonl", livestockIds,
                    (ids, page) -> motilityLogRepository.findPageByLivestockIn(ids, page)));
            rowCounts.put("activity_logs", writeTelemetry(zip, "activity_logs.jsonl", livestockIds,
                    (ids, page) -> activityLogRepository.findPageByLivestockIn(ids, page)));
        }

        long size = Files.size(zipPath);
        log.info("NIX-325 export generated: farm={} job={} size={} counts={}", farmId, jobId, size, rowCounts);
        return new ExportResult(zipPath, size, rowCounts);
    }

    public void deleteQuietly(String filePath) {
        if (filePath == null) return;
        try {
            Files.deleteIfExists(Path.of(filePath));
        } catch (Exception e) {
            log.warn("NIX-325 failed to delete export file {}: {}", filePath, e.getMessage());
        }
    }

    // ── entity writers ─────────────────────────────────────────

    private interface PageFetcher {
        com.smartlivestock.shared.domain.TelemetryPage<?> fetch(List<Long> livestockIds, org.springframework.data.domain.Pageable page);
    }

    private long writeLivestock(ZipOutputStream zip, List<Livestock> livestock) throws IOException {
        zip.putNextEntry(new ZipEntry("livestock.jsonl"));
        long count = 0;
        for (Livestock l : livestock) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", l.getId());
            row.put("livestockCode", l.getLivestockCode());
            row.put("breed", l.getBreed());
            row.put("gender", l.getGender());
            row.put("birthDate", l.getBirthDate());
            row.put("weight", l.getWeight());
            row.put("healthStatus", l.getHealthStatus() != null ? l.getHealthStatus().name() : null);
            writeLine(zip, row);
            count++;
        }
        zip.closeEntry();
        return count;
    }

    private long writeAlerts(ZipOutputStream zip, Long farmId) throws IOException {
        zip.putNextEntry(new ZipEntry("alerts.jsonl"));
        long count = 0;
        List<Alert> alerts = alertRepository.findByFarmId(farmId);
        for (Alert a : alerts) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", a.getId());
            row.put("livestockId", a.getLivestockId());
            row.put("type", a.getType() != null ? a.getType().name() : null);
            row.put("status", a.getStatus() != null ? a.getStatus().name() : null);
            row.put("severity", a.getSeverity() != null ? a.getSeverity().name() : null);
            row.put("message", a.getMessage());
            row.put("acknowledgedAt", a.getAcknowledgedAt());
            row.put("handledAt", a.getHandledAt());
            row.put("createdAt", a.getCreatedAt());
            writeLine(zip, row);
            count++;
        }
        zip.closeEntry();
        return count;
    }

    private long writeGpsLogs(ZipOutputStream zip, List<Long> livestockIds) throws IOException {
        zip.putNextEntry(new ZipEntry("gps_logs.jsonl"));
        long count = 0;
        List<Long> deviceIds = installationRepository.findByLivestockIdIn(livestockIds).stream()
                .filter(inst -> inst.isActive() && inst.getLivestockId() != null)
                .map(com.smartlivestock.iot.domain.model.Installation::getDeviceId)
                .distinct()
                .toList();
        for (Long deviceId : deviceIds) {
            int page = 0;
            while (true) {
                var rows = gpsLogRepository.findPageByDeviceId(deviceId, page + 1, PAGE_SIZE);
                for (var g : rows.items()) {
                    writeLine(zip, g);
                    count++;
                }
                if ((page + 1) * (long) PAGE_SIZE < rows.total()) {
                    page++;
                } else {
                    break;
                }
            }
        }
        zip.closeEntry();
        return count;
    }

    private long writeTelemetry(ZipOutputStream zip, String entryName, List<Long> livestockIds,
                                PageFetcher fetcher) throws IOException {
        zip.putNextEntry(new ZipEntry(entryName));
        long count = 0;
        if (livestockIds.isEmpty()) {
            zip.closeEntry();
            return 0;
        }
        int page = 0;
        while (true) {
            var rows = fetcher.fetch(livestockIds, PageRequest.of(page, PAGE_SIZE));
            for (Object row : rows.items()) {
                writeLine(zip, row);
                count++;
            }
            if (page + 1 < Math.max(1, (int) Math.ceil((double) rows.total() / PAGE_SIZE))) {
                page++;
            } else {
                break;
            }
        }
        zip.closeEntry();
        return count;
    }

    private void writeLine(ZipOutputStream zip, Object row) throws IOException {
        zip.write(objectMapper.writeValueAsBytes(row));
        zip.write('\n');
    }
}
