package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;

import java.util.List;
import java.util.Optional;

public interface AlertRepository {
    Alert save(Alert alert);
    Optional<Alert> findById(Long id);
    List<Alert> findByFarmId(Long farmId);
    List<Alert> findByFarmIdRecent(Long farmId, int limit);
    List<Alert> findByFarmIdAndStatus(Long farmId, AlertStatus status);
    List<Alert> findByLivestockIdAndTypeAndStatus(Long livestockId, AlertType type, AlertStatus status);
    List<Alert> findByDeviceIdAndTypeAndStatus(Long deviceId, AlertType type, AlertStatus status);

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
