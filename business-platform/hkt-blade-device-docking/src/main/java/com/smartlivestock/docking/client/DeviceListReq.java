package com.smartlivestock.docking.client;

import lombok.Data;
import java.util.List;

@Data
public class DeviceListReq {
    private List<String> deviceIds;
}
