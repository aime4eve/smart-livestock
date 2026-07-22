package com.smartlivestock.iot.interfaces.admin.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Parse-preview result of an RTK trajectory import file (spec §6.2).
 * Nothing is persisted at this stage.
 */
public class TrajectoryParseResultDto {

    private int totalRows;
    private int validRows;
    private int invalidRows;
    private int deviceCount;
    private int filePaired;
    private int logPaired;
    private int unpaired;
    private List<Row> rows;
    private List<String> autoRegisteredEuis;

    /**
     * @param matchMode          FILE / GPS_LOG / UNPAIRED / INVALID
     * @param error              INVALID reason, else null
     * @param matchedRecordedAt  gps_logs report timestamp when GPS_LOG, else null
     * @param timeDiffSec        pairing time diff when GPS_LOG, else null
     */
    public record Row(
        int rowNo,
        String deviceEui,
        Instant collectedAt,
        BigDecimal rtkLatitude,
        BigDecimal rtkLongitude,
        BigDecimal deviceLatitude,
        BigDecimal deviceLongitude,
        String matchMode,
        String error,
        Instant matchedRecordedAt,
        Integer timeDiffSec
    ) {}

    public int getTotalRows() { return totalRows; }
    public void setTotalRows(int totalRows) { this.totalRows = totalRows; }
    public int getValidRows() { return validRows; }
    public void setValidRows(int validRows) { this.validRows = validRows; }
    public int getInvalidRows() { return invalidRows; }
    public void setInvalidRows(int invalidRows) { this.invalidRows = invalidRows; }
    public int getDeviceCount() { return deviceCount; }
    public void setDeviceCount(int deviceCount) { this.deviceCount = deviceCount; }
    public int getFilePaired() { return filePaired; }
    public void setFilePaired(int filePaired) { this.filePaired = filePaired; }
    public int getLogPaired() { return logPaired; }
    public void setLogPaired(int logPaired) { this.logPaired = logPaired; }
    public int getUnpaired() { return unpaired; }
    public void setUnpaired(int unpaired) { this.unpaired = unpaired; }
    public List<Row> getRows() { return rows; }
    public List<String> getAutoRegisteredEuis() { return autoRegisteredEuis; }
    public void setAutoRegisteredEuis(List<String> autoRegisteredEuis) { this.autoRegisteredEuis = autoRegisteredEuis; }
    public void setRows(List<Row> rows) { this.rows = rows; }
}
