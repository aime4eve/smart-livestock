package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

@Data
@EqualsAndHashCode(callSuper = true)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceDetailVO extends DeviceVO {

    private String identifier;
    private String type_id;
    private Boolean control_enabled;
    private Boolean data_collection_enabled;
    private Integer rssi;
    private BigDecimal snr;
    private Integer spreading_factor;
    private String last_gateway;
}
