package com.smartlivestock.docking.oauth;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * OAuth2 properties for blade gateway token exchange (grant_type=openapi).
 */
@Data
@Component
@ConfigurationProperties(prefix = "blade.oauth2")
public class BladeOAuth2Properties {

    private boolean enabled = false;
    private String tokenUri = "";
    private String clientId = "";
    private String clientSecret = "";
    private int expirySkewSeconds = 120;
    private int connectTimeoutMs = 5000;
    private int readTimeoutMs = 15000;

    /**
     * Service account userId created via hkt-blade-system feign endpoint.
     * Flow: POST /feign/v1/system/sdk/user/create -> PUT /sdk/user/{id}/enable -> use openapi grant.
     */
    private String serviceUserId = "smart-livestock-server";

    /** Blade tenant id, sent as Tenant-Id header on token exchange and Feign requests. */
    private String tenantId = "000000";
}
