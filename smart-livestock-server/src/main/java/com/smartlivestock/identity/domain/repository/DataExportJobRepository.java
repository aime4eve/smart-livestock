package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.DataExportJob;

import java.util.List;
import java.util.Optional;

public interface DataExportJobRepository {

    DataExportJob save(DataExportJob job);

    Optional<DataExportJob> findById(Long id);

    List<DataExportJob> findByStatus(DataExportJob.Status status);

    List<DataExportJob> findByTenantIdOrderByIdDesc(Long tenantId);

    List<DataExportJob> findAll(int limit);

    /** Completed jobs whose package delivery window has passed (cleanup input). */
    List<DataExportJob> findCompletedWithWindowEnded(DataExportJob.Status status);
}
