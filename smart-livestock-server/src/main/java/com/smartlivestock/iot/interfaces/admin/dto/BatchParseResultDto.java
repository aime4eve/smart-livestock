package com.smartlivestock.iot.interfaces.admin.dto;

import java.time.Instant;
import java.util.List;

/**
 * Result of a parse-only precheck of a batch GPS quality check import (Excel upload).
 * Nothing is persisted and no device is created or registered.
 */
public class BatchParseResultDto {

    private int totalRows;
    private int okCount;
    private int warnCount;
    private int errorCount;
    private List<ParseRow> rows;

    public BatchParseResultDto() {}

    public int getTotalRows() { return totalRows; }
    public void setTotalRows(int totalRows) { this.totalRows = totalRows; }

    public int getOkCount() { return okCount; }
    public void setOkCount(int okCount) { this.okCount = okCount; }

    public int getWarnCount() { return warnCount; }
    public void setWarnCount(int warnCount) { this.warnCount = warnCount; }

    public int getErrorCount() { return errorCount; }
    public void setErrorCount(int errorCount) { this.errorCount = errorCount; }

    public List<ParseRow> getRows() { return rows; }
    public void setRows(List<ParseRow> rows) { this.rows = rows; }

    public record ParseRow(
        int rowIndex,
        String eui,
        String deviceCode,
        String testType,    // STATIC / DYNAMIC, null when unrecognized
        String refName,
        Long rtkPointId,
        Long routeId,
        Instant startedAt,
        Instant endedAt,
        String preStatus,   // OK / WARN / ERROR
        String message
    ) {}
}
