package com.smartlivestock.iot.infrastructure.client.devicehub;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * HKT-DeviceHub shared service integration (gray rollout, disabled by default).
 * enabled=true switches TB device provisioning to DeviceHub REST and assembles
 * the DeviceHub telemetry consumer / Feign client.
 */
@Component
@ConfigurationProperties(prefix = "smartlivestock.devicehub")
@Getter
@Setter
public class DeviceHubProperties {

    private boolean enabled = false;
    private String serviceUrl = "http://172.17.10.206:8080";
    private String mqNameServer = "172.17.10.206:9876";
    private String mqTopic = "DEVICEHUB_TELEMETRY_FRAME";
    private String mqConsumerGroup = "devicehub-livestock";
}
