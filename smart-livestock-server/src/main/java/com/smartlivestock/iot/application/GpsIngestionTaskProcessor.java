package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GpsIngestionTask;
import com.smartlivestock.iot.domain.model.GpsIngestionTaskStatus;
import com.smartlivestock.iot.domain.repository.GpsIngestionTaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class GpsIngestionTaskProcessor {
    private final GpsIngestionTaskRepository taskRepository;
    private final GpsLogApplicationService gpsLogApplicationService;

    @Transactional(readOnly = true)
    public List<Long> findReadyTaskIds(Instant now, int limit) {
        return taskRepository.findReadyTaskIds(now, limit);
    }

    @Transactional
    public boolean processTask(Long taskId) {
        Optional<GpsIngestionTask> existing = taskRepository.findById(taskId);
        if (existing.isEmpty()) {
            return false;
        }

        GpsIngestionTask task = existing.get();
        if (task.getStatus() != GpsIngestionTaskStatus.PENDING
                || task.getNextAttemptAt().isAfter(Instant.now())) {
            return false;
        }

        gpsLogApplicationService.logGps(
                task.getDeviceId(),
                task.getLatitude(),
                task.getLongitude(),
                task.getAccuracy(),
                task.getRecordedAt(),
                task.getSource());
        // Completed tasks are removed in the same transaction as the GPS upsert;
        // a later duplicate re-enqueues and the gps_logs unique key keeps it idempotent.
        taskRepository.delete(task);
        return true;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordFailure(Long taskId, String error, int maxAttempts, Instant retryAt) {
        taskRepository.findById(taskId).ifPresent(task -> {
            task.markFailed(error, maxAttempts, retryAt);
            taskRepository.save(task);
        });
    }
}
