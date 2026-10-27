package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.dto.SubscriptionResponse.ExportWindow;
import com.smartlivestock.commerce.application.service.SubscriptionHealthEvaluator;
import com.smartlivestock.commerce.application.service.SubscriptionHealthEvaluator.HealthVerdict;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.SubscriptionMapper;
import com.smartlivestock.identity.application.SubscriptionExportPolicy;
import com.smartlivestock.identity.application.SubscriptionExportPolicy.Decision;
import com.smartlivestock.identity.domain.repository.DataExportJobRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * Admin API — all-tenant subscription health overview (NIX-324 spec §4.2).
 * platform_admin only. Wall-clock verdicts from the shared evaluator; the
 * same-day-group flag appears only when ≥2 tenants share an expiry DATE
 * (the hosted-pilot shared deadline bulk-expiry case).
 */
@RestController
@RequestMapping("/api/v1/admin/subscription-overview")
@RequiredArgsConstructor
public class AdminSubscriptionOverviewController {

    private final SpringDataSubscriptionRepository springDataSubscriptionRepository;
    private final SpringDataTenantRepository springDataTenantRepository;
    private final SubscriptionHealthEvaluator subscriptionHealthEvaluator;
    private final SubscriptionExportPolicy subscriptionExportPolicy;
    private final DataExportJobRepository dataExportJobRepository;

    @GetMapping
    public ApiResponse<Map<String, Object>> overview(
            @RequestParam(defaultValue = "all") String health,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "50") int size) {

        Instant now = Instant.now();
        Map<Long, String> tenantNames = springDataTenantRepository.findAll().stream()
                .collect(Collectors.toMap(t -> t.getId(), t -> t.getName() == null ? "" : t.getName(),
                        (a, b) -> a));

        List<Map<String, Object>> rows = new ArrayList<>();
        for (var entity : springDataSubscriptionRepository.findAll()) {
            Subscription sub = SubscriptionMapper.toDomain(entity);
            Long tenantId = sub.getTenantId();
            HealthVerdict verdict = subscriptionHealthEvaluator.evaluate(sub, now);
            if (!"all".equalsIgnoreCase(health)
                    && !verdict.healthStatus().name().equalsIgnoreCase(health)) {
                continue;
            }
            String name = tenantNames.getOrDefault(tenantId, "tenant-" + tenantId);
            if (keyword != null && !keyword.isBlank()
                    && !name.toLowerCase().contains(keyword.toLowerCase())) {
                continue;
            }

            Map<String, Object> row = new LinkedHashMap<>();
            row.put("tenantId", tenantId);
            row.put("tenantName", name);
            row.put("tier", sub.getTier() != null ? sub.getTier().name() : null);
            row.put("status", sub.getStatus() != null ? sub.getStatus().name() : null);
            row.put("healthStatus", verdict.healthStatus().name());
            row.put("level", verdict.level());
            row.put("trialActive", verdict.trialActive());
            row.put("effectiveTier", verdict.effectiveTier());
            row.put("daysToExpiry", verdict.daysToExpiry());
            row.put("degraded", verdict.degraded());
            row.put("expiresAt", sub.getExpiresAt());
            row.put("trialEndsAt", sub.getTrialEndsAt());
            row.put("exportWindow", buildExportWindow(tenantId, now));
            rows.add(row);
        }

        markSameDayGroups(rows, now);
        rows.sort(overviewOrder());

        int total = rows.size();
        int from = Math.min(Math.max(0, (page - 1) * size), total);
        int to = Math.min(from + size, total);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", rows.subList(from, to));
        data.put("page", page);
        data.put("pageSize", size);
        data.put("total", total);
        return ApiResponse.ok(data);
    }

    /**
     * Urgency order: expiring-soon by days asc, then expired, renewal-failed,
     * cancelled, suspended, trial, healthy; ties by tenant name. Same-day
     * groups (shared campaign deadline) sort next to each other naturally
     * via the days key.
     */
    private static Comparator<Map<String, Object>> overviewOrder() {
        return Comparator
                .<Map<String, Object>>comparingInt(AdminSubscriptionOverviewController::urgencyRank)
                .thenComparing(r -> ((Number) Objects.requireNonNullElse(r.get("daysToExpiry"), Long.MAX_VALUE)).longValue())
                .thenComparing(r -> String.valueOf(r.get("tenantName")));
    }

    private static int urgencyRank(Map<String, Object> row) {
        return switch (String.valueOf(row.get("healthStatus"))) {
            case "EXPIRING_SOON" -> 0;
            case "EXPIRED" -> 1;
            case "RENEWAL_FAILED" -> 2;
            case "CANCELLED" -> 3;
            case "SUSPENDED" -> 4;
            case "TRIAL" -> 5;
            default -> 6;
        };
    }

    /** Flag rows whose expiry DATE is shared by ≥2 tenants (spec §4.2). */
    private static void markSameDayGroups(List<Map<String, Object>> rows, Instant now) {
        Map<LocalDate, Long> byDate = new HashMap<>();
        for (Map<String, Object> row : rows) {
            expiryDate(row, now).ifPresent(d -> byDate.merge(d, 1L, Long::sum));
        }
        for (Map<String, Object> row : rows) {
            row.put("sameDayGroup", expiryDate(row, now)
                    .map(d -> byDate.getOrDefault(d, 0L) >= 2)
                    .orElse(false));
        }
    }

    private static java.util.Optional<LocalDate> expiryDate(Map<String, Object> row, Instant now) {
        Object expiresAt = row.get("expiresAt");
        Object trialEndsAt = row.get("trialEndsAt");
        Instant anchor = null;
        if (expiresAt instanceof Instant i) anchor = i;
        else if (trialEndsAt instanceof Instant i) anchor = i;
        if (anchor == null || !anchor.isAfter(now)) {
            return java.util.Optional.empty();
        }
        return java.util.Optional.of(LocalDate.ofInstant(anchor, ZoneOffset.UTC));
    }

    private ExportWindow buildExportWindow(Long tenantId, Instant now) {
        Decision decision = subscriptionExportPolicy.assess(tenantId, now);
        if (!decision.isEligible()) {
            return null;
        }
        var latestJob = dataExportJobRepository.findByTenantIdOrderByIdDesc(tenantId)
                .stream().findFirst().orElse(null);
        return new ExportWindow(
                decision.eligibility().terminatedAt(),
                decision.eligibility().windowEndsAt(),
                Math.max(0, Duration.between(now, decision.eligibility().windowEndsAt()).toDays()),
                latestJob != null ? latestJob.getId() : null,
                latestJob != null ? latestJob.getStatus().name() : null,
                latestJob != null ? latestJob.getDownloadedAt() : null);
    }
}
