package com.smartlivestock.docking.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.util.List;

/**
 * Paginated device uplink report records (from /device/report-record/page).
 * Each record contains raw hexData + decodeData (parsed properties JSON string).
 *
 * Verified response structure (211 records for device 2072879090955759616):
 *   id, deviceId, deviceIdentifier, hexData, reportTime, decodeStatus,
 *   decodeData (JSON string with nested properties),
 *   rssi, snr, reportGateway
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class ReportRecordPageResp {
    private Long total;
    private Long current;
    private Long size;
    private List<ReportRecord> records;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ReportRecord {
        private String id;
        private String deviceId;
        private String deviceIdentifier;
        private String hexData;
        private String reportTime;
        private Boolean decodeStatus;
        private String decodeData;
        private Integer rssi;
        private String snr;
        private String reportGateway;
    }
}
