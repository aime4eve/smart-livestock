package com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * OAuth2 properties for agentic-middle-platform gateway token exchange (grant_type=openapi).
 */
@Data
@Component
@ConfigurationProperties(prefix = "agentic-platform.oauth2")
public class AgenticPlatformOAuth2Properties {

    private boolean enabled = false;
    private String tokenUri = "";
    private String clientId = "";
    private String clientSecret = "";
    private int expirySkewSeconds = 120;
    private int connectTimeoutMs = 5000;
    private int readTimeoutMs = 15000;

    /** Service account userId created via hkt-blade-system feign endpoint. */
    private String serviceUserId = "smart-livestock-server";

    /** Tenant id, sent as Tenant-Id header on token exchange and Feign requests. */
    private String tenantId = "000000";
}
