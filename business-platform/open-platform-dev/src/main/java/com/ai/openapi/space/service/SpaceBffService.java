package com.ai.openapi.space.service;

import com.ai.openapi.auth.context.RequestContext;
import com.ai.openapi.common.dto.LoginUser;
import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.common.response.OpenApiResponse;
import com.ai.openapi.space.adapter.SpaceAdapter;
import com.ai.openapi.space.client.SpaceBindingClient;
import com.ai.openapi.space.client.SpaceServiceClient;
import com.ai.openapi.space.dto.external.CreateSpaceRequest;
import com.ai.openapi.space.dto.external.SpaceVO;
import com.ai.openapi.space.dto.external.UpdateSpaceRequest;
import com.ai.openapi.space.dto.internal.CreateBindingRequest;
import com.ai.openapi.space.dto.internal.CreateNodeRequest;
import com.ai.openapi.space.dto.internal.SpaceNodeVO;
import com.ai.openapi.space.dto.internal.UpdateNodeRequest;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import feign.FeignException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class SpaceBffService {

    private static final String DEFAULT_UPSTREAM_ERROR = "空间服务暂时不可用";

    private final SpaceServiceClient spaceServiceClient;
    private final SpaceBindingClient spaceBindingClient;
    private final SpaceAdapter spaceAdapter;
    private final ObjectMapper objectMapper;

    public SpaceBffService(SpaceServiceClient spaceServiceClient,
                           SpaceBindingClient spaceBindingClient,
                           SpaceAdapter spaceAdapter,
                           ObjectMapper objectMapper) {
        this.spaceServiceClient = spaceServiceClient;
        this.spaceBindingClient = spaceBindingClient;
        this.spaceAdapter = spaceAdapter;
        this.objectMapper = objectMapper;
    }

    private String extractUpstreamMsg(FeignException e) {
        try {
            Map<String, Object> body = objectMapper.readValue(e.contentUTF8(), new TypeReference<>() {});
            Object msg = body.get("msg");
            if (msg != null && !msg.toString().isBlank()) {
                return msg.toString();
            }
        } catch (Exception ignored) {
        }
        return DEFAULT_UPSTREAM_ERROR;
    }

    private OpenApiException upstreamError(FeignException e) {
        return new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                ErrorCode.UPSTREAM_ERROR.getCode(), extractUpstreamMsg(e));
    }

    /**
     * 对外开放列表不传 level：由空间中台自行处理层级，此处 levelId 固定为 null。
     */
    public OpenApiResponse<SpaceVO> listSpaces(String name, String parentId, int page, int pageSize) {
        RequestContext ctx = RequestContext.get();
        String tenantId = ctx.getInternalUserId();

        InternalResponse<Map<String, Object>> response;
        try {
            response = spaceServiceClient.pageNodes(tenantId, name, null, parentId, null, page, pageSize);
        } catch (FeignException e) {
            throw upstreamError(e);
        }

        if (!response.isOk()) {
            throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                    ErrorCode.UPSTREAM_ERROR.getCode(), "查询空间列表失败: " + response.getMsg());
        }

        Map<String, Object> data = response.getData();

        @SuppressWarnings("unchecked")
        List<SpaceNodeVO> records = data != null && data.get("rows") != null
                ? objectMapper.convertValue(data.get("rows"), new TypeReference<List<SpaceNodeVO>>() {})
                : List.of();

        long total = data != null && data.get("total") != null
                ? ((Number) data.get("total")).longValue()
                : records.size();

        List<SpaceVO> pageItems = spaceAdapter.toExternalList(records);

        return OpenApiResponse.of(pageItems, total, page, pageSize);
    }

    public SpaceVO getSpaceDetail(String spaceId) {
        InternalResponse<SpaceNodeVO> response;
        try {
            response = spaceServiceClient.getNodeDetail(spaceId);
        } catch (FeignException.BadRequest e) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "空间不存在");
        } catch (FeignException e) {
            throw upstreamError(e);
        }

        if (!response.isOk() || response.getData() == null) {
            throw new OpenApiException(ErrorCode.NOT_FOUND.getHttpStatus(), ErrorCode.NOT_FOUND.getCode(),
                    "空间不存在: " + response.getMsg());
        }

        return spaceAdapter.toExternal(response.getData());
    }

    public SpaceVO createSpace(CreateSpaceRequest request) {
        RequestContext ctx = RequestContext.get();
        LoginUser loginUser = LoginUser.from(ctx.getInternalUserId(), ctx.getAppExternalId());

        CreateNodeRequest internalReq = new CreateNodeRequest();
        internalReq.setUser(loginUser);
        internalReq.setTenantId(ctx.getInternalUserId());
        internalReq.setName(request.getName());
        internalReq.setParentId(blankToNull(request.getParent_id()));
        // 层级、面积等由空间中台策略处理，开放平台不传
        internalReq.setLevelId(null);
        internalReq.setArea(null);

        InternalResponse<String> response;
        try {
            response = spaceServiceClient.createNode(internalReq);
        } catch (FeignException e) {
            log.warn("空间服务调用失败: status={}, msg={}", e.status(), extractUpstreamMsg(e));
            throw upstreamError(e);
        }

        if (!response.isOk()) {
            throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.getCode(), "创建空间失败: " + response.getMsg());
        }

        return getSpaceDetail(response.getData());
    }

    public SpaceVO updateSpace(String spaceId, UpdateSpaceRequest request) {
        // 先校验空间是否存在，不存在则抛出 NOT_FOUND
        getSpaceDetail(spaceId);

        RequestContext ctx = RequestContext.get();
        LoginUser loginUser = LoginUser.from(ctx.getInternalUserId(), ctx.getAppExternalId());

        UpdateNodeRequest internalReq = new UpdateNodeRequest();
        internalReq.setUser(loginUser);
        internalReq.setTenantId(ctx.getInternalUserId());
        internalReq.setNodeId(spaceId);
        internalReq.setName(request.getName());
        internalReq.setParentId(blankToNull(request.getParent_id()));
        internalReq.setLevelId(null);
        internalReq.setArea(null);

        InternalResponse<Boolean> response;
        try {
            response = spaceServiceClient.updateNode(internalReq);
        } catch (FeignException e) {
            log.warn("空间服务调用失败: status={}, msg={}", e.status(), extractUpstreamMsg(e));
            throw upstreamError(e);
        }

        if (!response.isOk()) {
            throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.getCode(), "修改空间失败: " + response.getMsg());
        }

        return getSpaceDetail(spaceId);
    }

    public boolean deleteSpace(String spaceId) {
        // 先校验空间是否存在，不存在则抛出 NOT_FOUND
        getSpaceDetail(spaceId);

        RequestContext ctx = RequestContext.get();
        String userId = ctx.getInternalUserId();

        InternalResponse<Boolean> response;
        try {
            response = spaceServiceClient.deleteNode(spaceId, userId);
        } catch (FeignException e) {
            log.warn("空间服务调用失败: status={}, msg={}", e.status(), extractUpstreamMsg(e));
            throw upstreamError(e);
        }

        if (!response.isOk()) {
            throw new OpenApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.getCode(), "删除空间失败: " + response.getMsg());
        }

        return Boolean.TRUE.equals(response.getData());
    }

    public void createDeviceBinding(String spaceId, String deviceId) {
        CreateBindingRequest bindingReq = new CreateBindingRequest();
        bindingReq.setNodeId(spaceId);
        bindingReq.setResourceId(deviceId);
        bindingReq.setResourceType("1");

        InternalResponse<String> response;
        try {
            response = spaceBindingClient.createBinding(bindingReq);
        } catch (FeignException e) {
            log.warn("创建空间-设备绑定关系失败: spaceId={}, deviceId={}, status={}",
                    spaceId, deviceId, e.status());
            return;
        }

        if (!response.isOk()) {
            log.warn("创建空间-设备绑定关系失败: spaceId={}, deviceId={}, msg={}",
                    spaceId, deviceId, response.getMsg());
        }
    }

    private static String blankToNull(String s) {
        return StringUtils.hasText(s) ? s : null;
    }
}
