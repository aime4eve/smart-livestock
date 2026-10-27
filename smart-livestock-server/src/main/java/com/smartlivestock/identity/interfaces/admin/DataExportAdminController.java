package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.identity.application.DataExportApplicationService;
import com.smartlivestock.identity.domain.model.DataExportJob;
import com.smartlivestock.identity.domain.repository.DataExportJobRepository;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Admin API — data-export job oversight for platform_admin (NIX-325):
 * all tenants, delivery evidence for the audit chain.
 */
@RestController
@RequestMapping("/api/v1/admin/data-export-jobs")
@RequiredArgsConstructor
public class DataExportAdminController {

    private final DataExportJobRepository jobRepository;

    @GetMapping
    public ApiResponse<Map<String, Object>> list(@RequestParam(defaultValue = "1") int page,
                                                 @RequestParam(defaultValue = "50") int size) {
        var jobs = jobRepository.findAll(Integer.MAX_VALUE);
        int from = Math.min(Math.max(0, (page - 1) * size), jobs.size());
        int to = Math.min(from + size, jobs.size());
        return ApiResponse.ok(Map.of(
                "items", jobs.subList(from, to).stream().map(this::toView).toList(),
                "page", page,
                "pageSize", size,
                "total", jobs.size()));
    }

    private Map<String, Object> toView(DataExportJob job) {
        Map<String, Object> view = new LinkedHashMap<>();
        view.put("jobId", job.getId());
        view.put("tenantId", job.getTenantId());
        view.put("farmId", job.getFarmId());
        view.put("status", job.getStatus().name());
        view.put("terminatedAt", job.getTerminatedAt());
        view.put("windowEndsAt", job.getWindowEndsAt());
        view.put("requestedAt", job.getRequestedAt());
        view.put("completedAt", job.getCompletedAt());
        view.put("downloadedAt", job.getDownloadedAt());
        view.put("fileSizeBytes", job.getFileSizeBytes());
        view.put("rowCounts", job.getRowCounts());
        if (job.getError() != null) {
            view.put("error", job.getError());
        }
        return view;
    }
}
