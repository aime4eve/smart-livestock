package com.smartlivestock.iot.infrastructure.client.ns;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

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

    @PostConstruct
    void validateCredentials() {
        if (enabled && (username == null || username.isBlank()
                || password == null || password.isBlank())) {
            throw new IllegalStateException(
                    "smartlivestock.ns.enabled=true requires username and password");
        }
    }
}
