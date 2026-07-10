package com.ai.openapi.space.client.fallback;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.space.client.SpaceServiceClient;
import com.ai.openapi.space.dto.internal.CreateNodeRequest;
import com.ai.openapi.space.dto.internal.SpaceNodeVO;
import com.ai.openapi.space.dto.internal.UpdateNodeRequest;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class SpaceServiceFallback implements FallbackFactory<SpaceServiceClient> {

    @Override
    public SpaceServiceClient create(Throwable cause) {
        return new SpaceServiceClient() {
            @Override
            public InternalResponse<String> createNode(CreateNodeRequest request) {
                throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(), "空间服务暂时不可用", cause);
            }

            @Override
            public InternalResponse<Boolean> updateNode(UpdateNodeRequest request) {
                throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(), "空间服务暂时不可用", cause);
            }

            @Override
            public InternalResponse<Boolean> deleteNode(String nodeId, String userId) {
                throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(), "空间服务暂时不可用", cause);
            }

            @Override
            public InternalResponse<SpaceNodeVO> getNodeDetail(String nodeId) {
                throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(), "空间服务暂时不可用", cause);
            }

            @Override
            public InternalResponse<Map<String, Object>> pageNodes(String tenantId, String name, String levelId,
                    String parentId, String rootId, Integer pageNumber, Integer pageSize) {
                throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(), "空间服务暂时不可用", cause);
            }
        };
    }
}
