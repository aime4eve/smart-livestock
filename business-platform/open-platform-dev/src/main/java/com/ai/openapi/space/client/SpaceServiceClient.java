package com.ai.openapi.space.client;

import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.common.config.FeignConfig;
import com.ai.openapi.space.client.fallback.SpaceServiceFallback;
import com.ai.openapi.space.dto.internal.CreateNodeRequest;
import com.ai.openapi.space.dto.internal.SpaceNodeVO;
import com.ai.openapi.space.dto.internal.UpdateNodeRequest;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@FeignClient(
        name = "hkt-blade-space-resource",
        contextId = "spaceServiceClient",
        path = "/v1/space/node",
        configuration = FeignConfig.class,
        fallbackFactory = SpaceServiceFallback.class
)
public interface SpaceServiceClient {

    @PostMapping("/create")
    InternalResponse<String> createNode(@RequestBody CreateNodeRequest request);

    @PutMapping("/update")
    InternalResponse<Boolean> updateNode(@RequestBody UpdateNodeRequest request);

    @DeleteMapping("/delete")
    InternalResponse<Boolean> deleteNode(@RequestParam("nodeId") String nodeId,
                                          @RequestParam("userId") String userId);

    @GetMapping("/detail/{nodeId}")
    InternalResponse<SpaceNodeVO> getNodeDetail(@PathVariable("nodeId") String nodeId);

    @GetMapping("/page")
    InternalResponse<Map<String, Object>> pageNodes(
            @RequestParam(value = "tenantId", required = false) String tenantId,
            @RequestParam(value = "name", required = false) String name,
            @RequestParam(value = "levelId", required = false) String levelId,
            @RequestParam(value = "parentId", required = false) String parentId,
            @RequestParam(value = "rootId", required = false) String rootId,
            @RequestParam(value = "pageNumber", defaultValue = "1") Integer pageNumber,
            @RequestParam(value = "pageSize", defaultValue = "20") Integer pageSize);
}
