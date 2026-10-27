package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.DataExportJob;
import com.smartlivestock.identity.domain.repository.DataExportJobRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.DataExportJobJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDataExportJobRepositoryImpl implements DataExportJobRepository {

    private final SpringDataDataExportJobRepository springDataRepo;

    @Override
    public DataExportJob save(DataExportJob job) {
        DataExportJobJpaEntity saved = springDataRepo.save(toJpa(job));
        return toDomain(saved);
    }

    @Override
    public Optional<DataExportJob> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public List<DataExportJob> findByStatus(DataExportJob.Status status) {
        return springDataRepo.findByStatus(status.name()).stream().map(this::toDomain).toList();
    }

    @Override
    public List<DataExportJob> findByTenantIdOrderByIdDesc(Long tenantId) {
        return springDataRepo.findByTenantIdOrderByIdDesc(tenantId).stream().map(this::toDomain).toList();
    }

    @Override
    public List<DataExportJob> findAll(int limit) {
        return springDataRepo.findTop200ByOrderByIdDesc().stream().map(this::toDomain).toList();
    }

    @Override
    public List<DataExportJob> findCompletedWithWindowEnded(DataExportJob.Status status) {
        return springDataRepo.findByStatusAndWindowEndsAtBefore(status.name(), java.time.Instant.now())
                .stream().map(this::toDomain).toList();
    }

    private DataExportJobJpaEntity toJpa(DataExportJob d) {
        DataExportJobJpaEntity e = new DataExportJobJpaEntity();
        e.setId(d.getId());
        e.setTenantId(d.getTenantId());
        e.setFarmId(d.getFarmId());
        e.setStatus(d.getStatus() != null ? d.getStatus().name() : DataExportJob.Status.PENDING.name());
        e.setTerminatedAt(d.getTerminatedAt());
        e.setWindowEndsAt(d.getWindowEndsAt());
        e.setRequestedBy(d.getRequestedBy());
        e.setRequestedAt(d.getRequestedAt());
        e.setCompletedAt(d.getCompletedAt());
        e.setDownloadedAt(d.getDownloadedAt());
        e.setFilePath(d.getFilePath());
        e.setFileSizeBytes(d.getFileSizeBytes());
        e.setRowCounts(d.getRowCounts());
        e.setError(d.getError());
        e.setCreatedAt(d.getCreatedAt());
        e.setUpdatedAt(d.getUpdatedAt());
        return e;
    }

    private DataExportJob toDomain(DataExportJobJpaEntity e) {
        DataExportJob d = new DataExportJob();
        d.setId(e.getId());
        d.setTenantId(e.getTenantId());
        d.setFarmId(e.getFarmId());
        d.setStatus(DataExportJob.Status.valueOf(e.getStatus()));
        d.setTerminatedAt(e.getTerminatedAt());
        d.setWindowEndsAt(e.getWindowEndsAt());
        d.setRequestedBy(e.getRequestedBy());
        d.setRequestedAt(e.getRequestedAt());
        d.setCompletedAt(e.getCompletedAt());
        d.setDownloadedAt(e.getDownloadedAt());
        d.setFilePath(e.getFilePath());
        d.setFileSizeBytes(e.getFileSizeBytes());
        d.setRowCounts(e.getRowCounts());
        d.setError(e.getError());
        d.setCreatedAt(e.getCreatedAt());
        d.setUpdatedAt(e.getUpdatedAt());
        return d;
    }
}
