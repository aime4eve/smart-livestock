package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.StandardTrackLine;
import com.smartlivestock.iot.domain.model.StandardTrackLinePoint;
import com.smartlivestock.iot.domain.repository.StandardTrackLinePointRepository;
import com.smartlivestock.iot.domain.repository.StandardTrackLineRepository;
import com.smartlivestock.iot.domain.service.TrackLineCalculator;
import com.smartlivestock.iot.interfaces.admin.dto.LineTrackPointDto;
import com.smartlivestock.iot.interfaces.admin.dto.StandardTrackLineDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrackLineParseResultDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.SignStyle;
import java.time.temporal.ChronoField;
import java.util.ArrayList;
import java.util.List;

/**
 * Standard track line management (NIX-68, spec §4/§7.1): parse-preview →
 * import two-step flow, aligned with the trajectory import.
 * <p>
 * RTK handset XLSX layout (spec §4.1): single sheet "线路追踪", 8 columns,
 * ONE data row per line; all coordinates live in the "坐标" cell as
 * newline-separated {@code lng,lat,elevation} triples (WGS-84). Only the
 * first data row is imported. File metadata (start/end time, length column)
 * is never trusted — everything is computed from the coordinates (D6).
 * Cleaning is consecutive-duplicate removal only (D7).
 */
@Service
@RequiredArgsConstructor
public class StandardTrackLineService {

    /** Max raw coordinate lines per file (spec §4.3). */
    private static final int MAX_POINTS = 20000;
    private static final int PREVIEW_POINT_COUNT = 8;
    private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** Flexible datetime for metadata cells only (display/warning, never trusted). */
    private static final DateTimeFormatter META_DT = new DateTimeFormatterBuilder()
            .appendPattern("yyyy-MM-dd ")
            .appendValue(ChronoField.HOUR_OF_DAY, 1, 2, SignStyle.NORMAL).appendLiteral(':')
            .appendValue(ChronoField.MINUTE_OF_HOUR, 1, 2, SignStyle.NORMAL)
            .optionalStart().appendLiteral(':')
            .appendValue(ChronoField.SECOND_OF_MINUTE, 1, 2, SignStyle.NORMAL)
            .optionalEnd()
            .toFormatter();

    private final StandardTrackLineRepository lineRepository;
    private final StandardTrackLinePointRepository pointRepository;

    private final TrackLineCalculator calculator = new TrackLineCalculator();

    // ------------------------------------------------------------------
    // Parse preview (no persistence)
    // ------------------------------------------------------------------

    public TrackLineParseResultDto parse(MultipartFile file) {
        ParsedTrack parsed = readTrack(file);

        TrackLineParseResultDto dto = new TrackLineParseResultDto();
        dto.setDefaultName(parsed.defaultName());
        dto.setRawPointCount(parsed.rawPointCount());
        dto.setPointCount(parsed.points().size());
        dto.setRemovedDuplicates(parsed.removedDuplicates());
        dto.setInvalidPoints(parsed.invalidPoints());
        dto.setLengthMeters(parsed.lengthMeters());
        TrackLineCalculator.LinePoint first = parsed.points().get(0);
        TrackLineCalculator.LinePoint last = parsed.points().get(parsed.points().size() - 1);
        dto.setStartLng(BigDecimal.valueOf(first.longitude()));
        dto.setStartLat(BigDecimal.valueOf(first.latitude()));
        dto.setEndLng(BigDecimal.valueOf(last.longitude()));
        dto.setEndLat(BigDecimal.valueOf(last.latitude()));
        dto.setMetadataWarning(parsed.metadataWarning());
        List<TrackLineParseResultDto.Point> preview = new ArrayList<>();
        int limit = Math.min(PREVIEW_POINT_COUNT, parsed.points().size());
        for (int i = 0; i < limit; i++) {
            TrackLineCalculator.LinePoint p = parsed.points().get(i);
            preview.add(new TrackLineParseResultDto.Point(i + 1,
                    BigDecimal.valueOf(p.longitude()), BigDecimal.valueOf(p.latitude())));
        }
        dto.setPreviewPoints(preview);
        return dto;
    }

    // ------------------------------------------------------------------
    // Import (append-only: every import creates a new CANDIDATE, D3)
    // ------------------------------------------------------------------

    public StandardTrackLineDto importFile(MultipartFile file, String name, Long tenantId) {
        ParsedTrack parsed = readTrack(file);
        String finalName = (name != null && !name.isBlank()) ? name.trim() : parsed.defaultName();

        StandardTrackLine line = new StandardTrackLine();
        line.setTenantId(tenantId);
        line.setName(finalName);
        line.setStatus(StandardTrackLine.STATUS_CANDIDATE);
        line.setPointCount(parsed.points().size());
        line.setLengthM(BigDecimal.valueOf(parsed.lengthMeters())
                .setScale(1, java.math.RoundingMode.HALF_UP));
        TrackLineCalculator.LinePoint first = parsed.points().get(0);
        line.setStartLng(BigDecimal.valueOf(first.longitude()));
        line.setStartLat(BigDecimal.valueOf(first.latitude()));
        line.setSourceFile(file.getOriginalFilename());
        StandardTrackLine saved = lineRepository.save(line);

        List<StandardTrackLinePoint> points = new ArrayList<>(parsed.points().size());
        int seq = 1;
        for (TrackLineCalculator.LinePoint p : parsed.points()) {
            StandardTrackLinePoint point = new StandardTrackLinePoint();
            point.setLineId(saved.getId());
            point.setSequenceNo(seq++);
            point.setLongitude(BigDecimal.valueOf(p.longitude()));
            point.setLatitude(BigDecimal.valueOf(p.latitude()));
            points.add(point);
        }
        pointRepository.saveAll(points);
        return StandardTrackLineDto.from(saved);
    }

    // ------------------------------------------------------------------
    // Candidate management
    // ------------------------------------------------------------------

    public List<StandardTrackLineDto> list(Long tenantId) {
        return lineRepository.findByTenantIdOrderByCreatedAtDesc(tenantId).stream()
                .map(StandardTrackLineDto::from).toList();
    }

    public StandardTrackLineDto select(Long id) {
        return changeStatus(id, StandardTrackLine.STATUS_SELECTED);
    }

    public StandardTrackLineDto unselect(Long id) {
        return changeStatus(id, StandardTrackLine.STATUS_CANDIDATE);
    }

    private StandardTrackLineDto changeStatus(Long id, String status) {
        StandardTrackLine line = lineRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Standard track line not found: " + id));
        line.setStatus(status);
        return StandardTrackLineDto.from(lineRepository.save(line));
    }

    /**
     * Delete a candidate. Points cascade at the DB level; historical LINE
     * tests keep their own snapshots and their track_line_id is SET NULL (D4).
     */
    public void delete(Long id) {
        lineRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Standard track line not found: " + id));
        lineRepository.deleteById(id);
    }

    public List<LineTrackPointDto> findPoints(Long lineId) {
        lineRepository.findById(lineId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Standard track line not found: " + lineId));
        return pointRepository.findByLineIdOrderBySequenceNo(lineId).stream()
                .map(p -> new LineTrackPointDto(p.getSequenceNo(), p.getLongitude(), p.getLatitude()))
                .toList();
    }

    // ------------------------------------------------------------------
    // XLSX reading (spec §4.2): first sheet, header + first data row only
    // ------------------------------------------------------------------

    private record ParsedTrack(
            String defaultName,
            List<TrackLineCalculator.LinePoint> points,
            int rawPointCount,
            int removedDuplicates,
            int invalidPoints,
            double lengthMeters,
            String metadataWarning) {}

    private ParsedTrack readTrack(MultipartFile file) {
        String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "";
        if (!fileName.toLowerCase().endsWith(".xlsx")) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Unsupported file type (expected .xlsx): " + fileName);
        }

        Sheet sheet;
        try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
            sheet = wb.getSheetAt(0);
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Failed to read file: " + e.getMessage());
        }

        // Locate the first non-blank data row after the header
        Row dataRow = null;
        boolean hasMoreDataRows = false;
        for (int r = 1; r <= sheet.getLastRowNum(); r++) {
            Row row = sheet.getRow(r);
            if (row == null) continue;
            boolean blank = true;
            for (int c = 0; c < 8; c++) {
                String v = cellString(row.getCell(c));
                if (v != null && !v.isBlank()) { blank = false; break; }
            }
            if (blank) continue;
            if (dataRow == null) {
                dataRow = row;
            } else {
                hasMoreDataRows = true;
            }
        }
        if (dataRow == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "No data row found in sheet");
        }

        String nameCol = trim(cellString(dataRow.getCell(0)));
        String defaultName = nameCol != null ? nameCol
                : fileName.replaceAll("(?i)\\.xlsx$", "");
        String coordinates = cellString(dataRow.getCell(7));

        List<String> warnings = new ArrayList<>();
        if (hasMoreDataRows) {
            warnings.add("文件含多条线路，仅导入第 1 条");
        }
        String metaWarning = metadataWarning(
                trim(cellString(dataRow.getCell(2))),
                trim(cellString(dataRow.getCell(3))),
                trim(cellString(dataRow.getCell(4))));
        if (metaWarning != null) {
            warnings.add(metaWarning);
        }

        List<TrackLineCalculator.LinePoint> points = new ArrayList<>();
        int raw = 0, invalid = 0, removed = 0;
        if (coordinates != null) {
            for (String lineStr : coordinates.split("\n", -1)) {
                String trimmed = lineStr.trim(); // also strips a trailing \r (\r\n compatible)
                if (trimmed.isEmpty()) continue;
                raw++;
                if (raw > MAX_POINTS) {
                    throw new ApiException(ErrorCode.VALIDATION_ERROR,
                            "Too many coordinate points: " + raw + " (max " + MAX_POINTS + ")");
                }
                TrackLineCalculator.LinePoint p = parseTriple(trimmed);
                if (p == null) {
                    invalid++;
                    continue;
                }
                if (!points.isEmpty()) {
                    TrackLineCalculator.LinePoint prev = points.get(points.size() - 1);
                    if (prev.latitude() == p.latitude() && prev.longitude() == p.longitude()) {
                        removed++;
                        continue;
                    }
                }
                points.add(p);
            }
        }
        if (points.size() < 2) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "有效坐标点不足（去连续重复后 " + points.size() + " 个，至少 2 个）");
        }

        double lengthMeters = calculator.polylineLengthMeters(points);
        return new ParsedTrack(defaultName, points, raw, removed, invalid, lengthMeters,
                warnings.isEmpty() ? null : String.join("；", warnings));
    }

    /** Parse one {@code lng,lat,elevation} triple; elevation is ignored (D7). */
    private static TrackLineCalculator.LinePoint parseTriple(String line) {
        String[] parts = line.split(",", -1);
        if (parts.length != 3) return null;
        try {
            double lng = Double.parseDouble(parts[0].trim());
            double lat = Double.parseDouble(parts[1].trim());
            if (lng < -180 || lng > 180 || lat < -90 || lat > 90) return null;
            return new TrackLineCalculator.LinePoint(lat, lng);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Best-effort metadata sanity note (spec D6): metadata is displayed but
     * never persisted; anomalies (start == end, zero length, unparseable
     * times) produce a warning instead of failing the import.
     */
    private static String metadataWarning(String start, String end, String length) {
        List<String> issues = new ArrayList<>();
        boolean startParsed = parseMetaTime(start) != null;
        boolean endParsed = parseMetaTime(end) != null;
        if ((start != null && !startParsed) || (end != null && !endParsed)) {
            issues.add("开始/结束时间解析失败");
        }
        if (startParsed && endParsed && start.equals(end)) {
            issues.add("开始=结束时间");
        }
        if (length != null) {
            try {
                if (Double.parseDouble(length) == 0.0) {
                    issues.add("长度为 0");
                }
            } catch (NumberFormatException ignored) {
                issues.add("长度解析失败");
            }
        }
        return issues.isEmpty() ? null : "元数据不可信（" + String.join("、", issues) + "），已按坐标实算";
    }

    private static String parseMetaTime(String value) {
        if (value == null) return null;
        try {
            return java.time.LocalDateTime.parse(value, META_DT).toString();
        } catch (Exception e) {
            return null;
        }
    }

    private static String trim(String v) {
        return v != null && !v.isBlank() ? v.trim() : null;
    }

    private static String cellString(org.apache.poi.ss.usermodel.Cell cell) {
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue();
            case NUMERIC -> DateUtil.isCellDateFormatted(cell)
                    ? cell.getLocalDateTimeCellValue().format(DT_FMT)
                    : BigDecimal.valueOf(cell.getNumericCellValue()).toPlainString();
            default -> null;
        };
    }
}
