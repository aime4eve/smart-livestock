package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsIngestionTask;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface GpsIngestionTaskRepository {
    void enqueue(GpsIngestionTask task);

    List<Long> findReadyTaskIds(Instant now, int limit);

    Optional<GpsIngestionTask> findById(Long id);

    GpsIngestionTask save(GpsIngestionTask task);

    void delete(GpsIngestionTask task);
}
