package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import lombok.Data;
import java.util.List;

@Data
public class DeviceListReq {
    private List<String> deviceIds;
}
