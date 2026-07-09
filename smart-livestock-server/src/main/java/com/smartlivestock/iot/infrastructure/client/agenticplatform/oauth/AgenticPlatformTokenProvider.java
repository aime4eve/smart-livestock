package com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformServiceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Provides access_token for Feign requests via agentic-middle-platform OAuth2 openapi grant.
 */
@Component
public class AgenticPlatformTokenProvider {

    private final AgenticPlatformGatewayTokenService gatewayTokenService;

    @Value("${agentic-platform.oauth2.service-user-id:2074385063398711296}")
    private String serviceUserId;

    public AgenticPlatformTokenProvider(AgenticPlatformGatewayTokenService gatewayTokenService) {
        this.gatewayTokenService = gatewayTokenService;
    }

    public String getToken() {
        if (gatewayTokenService.isReady()) {
            return gatewayTokenService.getAccessToken(serviceUserId);
        }
        throw new AgenticPlatformServiceException(
                "agentic-middle-platform OAuth2 not ready: " + gatewayTokenService.describeWhyNotReady());
    }
}
