package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface AlertRepository {
    Alert save(Alert alert);
    Optional<Alert> findById(Long id);
    List<Alert> findByFarmId(Long farmId);
    List<Alert> findByLivestockIdAndTypeAndStatus(Long livestockId, AlertType type, AlertStatus status);
    List<Alert> findByDeviceIdAndTypeAndStatus(Long deviceId, AlertType type, AlertStatus status);
    List<Alert> findByLivestockIdAndStatusAndSource(Long livestockId, AlertStatus status, String source);

    /** One aggregated row per (status, severity, type) combination of the farm. */
    List<StatusSeverityTypeCount> countByFarmGrouped(Long farmId, Collection<String> types);

    /** Active alerts the user has NOT read, grouped by type. */
    List<TypeCount> countActiveUnreadGroupedByType(Long farmId, Long userId, Collection<String> types);

    /**
     * Paged alert listing, id descending. Empty filter collections mean "all";
     * {@code fenceId} null means no fence filter; {@code unreadOnly} keeps only
     * alerts the reader ({@code readerId}) has no read-status row for.
     *
     * @param page 1-based page index
     */
    AlertPage<Alert> findPageByFilters(Long farmId, Collection<AlertStatus> statuses,
                                       Severity severity, Collection<String> types,
                                       Long fenceId, boolean unreadOnly, Long readerId,
                                       int page, int size);

    record StatusSeverityTypeCount(String status, String severity, String type, long count) {}
    record TypeCount(String type, long count) {}
    record AlertPage<T>(List<T> items, long total) {}

    /**
     * Deletes every alert referencing the given fence.
     * Used when a fence is deleted together with its alert history.
     *
     * @return number of alerts removed
     */
    int deleteByFenceId(Long fenceId);

    /**
     * Deletes per-user read-status rows of the alerts referencing the given
     * fence. Must run before {@link #deleteByFenceId} — alert_read_status
     * holds a non-cascading FK on alerts.id.
     *
     * @return number of read-status rows removed
     */
    int deleteReadStatusByFenceId(Long fenceId);

    /**
     * Keeps alert rows but detaches them from the given fence
     * (alerts.fence_id = NULL) so the fence can be removed.
     *
     * @return number of alerts detached
     */
    int clearFenceReference(Long fenceId);
}
