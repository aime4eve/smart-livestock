package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsIngestionTask;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.repository.GpsIngestionTaskRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsIngestionTaskJpaEntity;
import com.smartlivestock.iot.infrastructure.persistence.mapper.GpsIngestionTaskMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaGpsIngestionTaskRepositoryImpl implements GpsIngestionTaskRepository {
    private final SpringDataGpsIngestionTaskRepository springDataRepo;

    @Override
    public void enqueue(GpsIngestionTask task) {
        springDataRepo.enqueue(
                task.getDeviceId(),
                task.getLatitude(),
                task.getLongitude(),
                task.getAccuracy(),
                task.getRecordedAt(),
                task.getSource() != null ? task.getSource().name() : TelemetrySource.HTTP.name());
        springDataRepo.flush();
    }

    @Override
    public List<Long> findReadyTaskIds(Instant now, int limit) {
        return springDataRepo.findReadyTaskIds(now, PageRequest.of(0, limit));
    }

    @Override
    public Optional<GpsIngestionTask> findById(Long id) {
        return springDataRepo.findById(id).map(GpsIngestionTaskMapper::toDomain);
    }

    @Override
    public GpsIngestionTask save(GpsIngestionTask task) {
        GpsIngestionTaskJpaEntity entity = springDataRepo.findById(task.getId())
                .orElseGet(GpsIngestionTaskJpaEntity::new);
        applyChanges(entity, task);
        return GpsIngestionTaskMapper.toDomain(springDataRepo.save(entity));
    }

    @Override
    public void delete(GpsIngestionTask task) {
        springDataRepo.deleteById(task.getId());
    }

    private void applyChanges(GpsIngestionTaskJpaEntity entity, GpsIngestionTask task) {
        entity.setId(task.getId());
        entity.setDeviceId(task.getDeviceId());
        entity.setLatitude(task.getLatitude());
        entity.setLongitude(task.getLongitude());
        entity.setAccuracy(task.getAccuracy());
        entity.setRecordedAt(task.getRecordedAt());
        entity.setSource(task.getSource() != null ? task.getSource().name() : TelemetrySource.HTTP.name());
        entity.setStatus(task.getStatus().name());
        entity.setAttempts(task.getAttempts());
        entity.setNextAttemptAt(task.getNextAttemptAt());
        entity.setLastError(task.getLastError());
        entity.setCreatedAt(task.getCreatedAt());
        entity.setUpdatedAt(task.getUpdatedAt());
    }
}
