package com.smartlivestock.iot.infrastructure.client.thingsboard;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "smartlivestock.tb")
@Getter
@Setter
public class TbProperties {

    private boolean enabled = false;
    private String baseUrl = "http://172.22.3.105";
    private String username = "tenant@hkt.com";
    private String password = "";
    private long pollIntervalMs = 300_000;
    private int lookbackDays = 7;
    private int batchSize = 200;
    private boolean bladeExclusion = false;
    private Long tenantId = 1L;
}
