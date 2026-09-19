package com.smartlivestock.iot.infrastructure.client.devicehub;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.context.annotation.Configuration;

/**
 * Assembles the DeviceHub Feign client only when the integration is enabled.
 * The condition sits on the importing configuration because
 * spring-cloud-openfeign registers client beans programmatically and does not
 * evaluate @Conditional on the @FeignClient interface itself.
 */
@Configuration
@ConditionalOnProperty(name = "smartlivestock.devicehub.enabled", havingValue = "true")
@EnableFeignClients(clients = DeviceHubClient.class)
public class DeviceHubFeignConfig {
}
