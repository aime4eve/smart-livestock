package com.ai.openapi.space.client.fallback;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.space.client.SpaceBindingClient;
import com.ai.openapi.space.dto.internal.CreateBindingRequest;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

@Component
public class SpaceBindingFallback implements FallbackFactory<SpaceBindingClient> {

    @Override
    public SpaceBindingClient create(Throwable cause) {
        return new SpaceBindingClient() {
            @Override
            public InternalResponse<String> createBinding(CreateBindingRequest request) {
                throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(), "空间绑定服务暂时不可用", cause);
            }
        };
    }
}
