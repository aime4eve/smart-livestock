package com.smartlivestock.docking.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class LicenseStatusResp {
    private String deviceEui;
    private String deviceSn;
    private String deviceTypeCode;
    private String status;
    private String agentId;
    private String agentCode;
    private String activatedAt;
    private Boolean isValid;
}
