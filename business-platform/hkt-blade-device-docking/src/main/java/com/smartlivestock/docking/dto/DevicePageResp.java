package com.smartlivestock.docking.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DevicePageResp {
    private Long total;
    private Long current;
    private Long pageSize;
    private List<DeviceDetailResp> records;
}
