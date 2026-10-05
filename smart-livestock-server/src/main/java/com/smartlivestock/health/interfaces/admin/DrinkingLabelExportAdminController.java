package com.smartlivestock.health.interfaces.admin;

import com.smartlivestock.health.application.service.DrinkingLabelExportService;
import com.smartlivestock.health.application.service.DrinkingLabelExportService.LabelExport;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Drinking label-dataset export (NIX-256 Task 6, spec §15.4): the offline
 * calibration loop ({@code calibrate.py --labels}) reads its dataset from
 * this endpoint; it is also the designated feed for the future AI-platform
 * label channel. Class-level @PreAuthorize mirrors the
 * DrinkingRecalcAdminController convention.
 */
@RestController
@RequestMapping("/api/v1/admin/drinking-labels")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class DrinkingLabelExportAdminController {

    private final DrinkingLabelExportService exportService;

    /**
     * GET /export?from=&to= — CSV download of every drinking-event row with
     * {@code event_start_at} in the closed date range from-day 00:00 →
     * to+1-day 00:00 (Asia/Shanghai, the same window as the recalc
     * endpoint). The body is UTF-8 with a BOM so Excel opens the Chinese
     * note column directly; missing or malformed dates answer 400 like the
     * recalc endpoint.
     */
    @GetMapping("/export")
    public ResponseEntity<byte[]> export(@RequestParam(required = false) String from,
                                         @RequestParam(required = false) String to) {
        LabelExport export = exportService.exportCsv(from, to);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + export.filename())
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(export.body());
    }
}
