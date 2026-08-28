package com.smartlivestock.iot.infrastructure.client.ns;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "smartlivestock.ns")
@Getter
@Setter
public class NsProperties {

    private boolean enabled = false;
    private String baseUrl = "http://172.17.201.15";
    private String username = "";
    private String password = "";
    private Long orgId = 1L;
    private int pageSize = 100;
}
