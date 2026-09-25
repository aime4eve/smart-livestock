package com.smartlivestock.ranch.application.dto;

import java.time.Instant;
import java.util.List;

/** Aggregated management view behind the ranch alert tab and alert center. */
public final class AlertWorkbenchDto {

    private AlertWorkbenchDto() {}

    public record BucketSummary(String key, long total, long unread) {}

    public record AssetSummary(String key, long total, long unread) {}

    public record WorkbenchSummary(List<BucketSummary> buckets, List<AssetSummary> assets) {}

    public record Asset(String kind, String id, String name, String subtitle) {}

    public record Reason(
            Long alertId,
            String type,
            String severity,
            String message,
            Instant occurredAt,
            boolean read
    ) {}

    public record AiView(String band, String findingCode, Double score, Instant assessedAt) {}

    public record WorkbenchItem(
            String id,
            String bucket,
            Asset asset,
            String title,
            String subtitle,
            String severity,
            boolean unread,
            Instant occurredAt,
            Instant resolvedAt,
            String resolvedType,
            List<Reason> reasons,
            AiView ai,
            List<String> actions,
            String targetRoute
    ) {}

    public record WorkbenchResponse(
            WorkbenchSummary summary,
            List<WorkbenchItem> items,
            int page,
            int pageSize,
            long total
    ) {}
}
