package com.ai.openapi.space.client;

import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.common.config.FeignConfig;
import com.ai.openapi.space.client.fallback.SpaceBindingFallback;
import com.ai.openapi.space.dto.internal.CreateBindingRequest;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(
        name = "hkt-blade-space-resource",
        contextId = "spaceBindingClient",
        path = "/v1/space/binding",
        configuration = FeignConfig.class,
        fallbackFactory = SpaceBindingFallback.class
)
public interface SpaceBindingClient {

    @PostMapping("/create")
    InternalResponse<String> createBinding(@RequestBody CreateBindingRequest request);
}
