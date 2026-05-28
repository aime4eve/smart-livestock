package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.shared.common.ApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private static final Logger log = LoggerFactory.getLogger(AnalyticsController.class);

    @PostMapping("/events")
    public ResponseEntity<ApiResponse<Void>> receiveEvents(
            @RequestBody List<Map<String, Object>> events) {
        for (Map<String, Object> event : events) {
            log.info("Analytics event: type={}, data={}",
                event.getOrDefault("event", "unknown"),
                event.getOrDefault("data", ""));
        }
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
