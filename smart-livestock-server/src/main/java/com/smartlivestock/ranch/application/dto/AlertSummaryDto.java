package com.smartlivestock.ranch.application.dto;

/**
 * Aggregated alert counters for the alert-center summary strip and the ranch
 * page badges. All counts are farm-global (not windowed); unread is per user.
 */
public final class AlertSummaryDto {

    private AlertSummaryDto() {}

    /** Active-alert counts grouped by business type family (fence/health/device). */
    public record TypeGroupCounts(int fence, int health, int device) {
        public static TypeGroupCounts zero() {
            return new TypeGroupCounts(0, 0, 0);
        }
    }

    /**
     * Active = status ACTIVE. critical+warning+info ≡ total by construction.
     * unread = active alerts the given user has no read-status row for.
     */
    public record ActiveSummary(
            int total,
            int unread,
            int critical,
            int warning,
            int info,
            TypeGroupCounts byGroup,
            TypeGroupCounts byGroupUnread
    ) {}

    /** resolved = DISMISSED + AUTO_RESOLVED. */
    public record AlertSummaryResponse(ActiveSummary active, int resolved) {}
}
