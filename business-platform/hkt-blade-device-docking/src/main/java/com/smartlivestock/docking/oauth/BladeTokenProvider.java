package com.smartlivestock.docking.oauth;

import com.smartlivestock.docking.service.BladeServiceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Provides access_token for Feign requests via blade OAuth2 openapi grant.
 * Uses a fixed service account userId instead of per-request context.
 */
@Component
public class BladeTokenProvider {

    private final BladeGatewayTokenService gatewayTokenService;

    @Value("${blade.oauth2.service-user-id:2074385063398711296}")
    private String serviceUserId;

    public BladeTokenProvider(BladeGatewayTokenService gatewayTokenService) {
        this.gatewayTokenService = gatewayTokenService;
    }

    public String getToken() {
        if (gatewayTokenService.isReady()) {
            return gatewayTokenService.getAccessToken(serviceUserId);
        }
        throw new BladeServiceException(
                "blade OAuth2 not ready: " + gatewayTokenService.describeWhyNotReady());
    }
}
