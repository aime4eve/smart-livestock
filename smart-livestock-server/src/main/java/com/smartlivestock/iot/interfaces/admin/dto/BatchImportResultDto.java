package com.smartlivestock.iot.interfaces.admin.dto;

import java.util.List;

/**
 * Result of a batch GPS quality check import (Excel upload).
 */
public class BatchImportResultDto {

    private Long batchId;
    private int totalRows;
    private int totalSuccess;
    private int totalPending;
    private int totalFailed;
    private List<RowResult> rows;

    public BatchImportResultDto() {}

    public Long getBatchId() { return batchId; }
    public void setBatchId(Long batchId) { this.batchId = batchId; }

    public int getTotalRows() { return totalRows; }
    public void setTotalRows(int totalRows) { this.totalRows = totalRows; }

    public int getTotalSuccess() { return totalSuccess; }
    public void setTotalSuccess(int totalSuccess) { this.totalSuccess = totalSuccess; }

    public int getTotalPending() { return totalPending; }
    public void setTotalPending(int totalPending) { this.totalPending = totalPending; }

    public int getTotalFailed() { return totalFailed; }
    public void setTotalFailed(int totalFailed) { this.totalFailed = totalFailed; }

    public List<RowResult> getRows() { return rows; }
    public void setRows(List<RowResult> rows) { this.rows = rows; }

    public record RowResult(
        int rowIndex,
        String status,      // SUCCESS / DEVICE_PENDING / FAILED / SKIPPED
        String eui,
        String deviceCode,
        Long deviceId,
        Long checkId,
        String message
    ) {}
}
