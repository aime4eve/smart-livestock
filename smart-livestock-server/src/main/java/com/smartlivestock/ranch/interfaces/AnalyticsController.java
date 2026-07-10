package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private static final Logger log = LoggerFactory.getLogger(AnalyticsController.class);
    private static final int MAX_EVENTS_PER_REQUEST = 100;
    private static final Set<String> ALLOWED_EVENT_TYPES = Set.of(
            "tile_download_completed", "tile_download_failed", "tile_evicted",
            "tile_cache_hit", "tile_cache_miss", "fence_sync_conflict",
            "fence_offline_edit", "offline_session"
    );

    @PostMapping("/events")
    public ResponseEntity<ApiResponse<Void>> receiveEvents(
            @RequestBody List<Map<String, Object>> events) {
        if (events == null || events.size() > MAX_EVENTS_PER_REQUEST) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "事件数量超限，最多 " + MAX_EVENTS_PER_REQUEST + " 条");
        }
        for (Map<String, Object> event : events) {
            String type = (String) event.getOrDefault("event", "unknown");
            if (!ALLOWED_EVENT_TYPES.contains(type)) {
                log.debug("Unknown analytics event type: {}", type);
                continue;
            }
            log.debug("Analytics event: type={}", type);
        }
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
