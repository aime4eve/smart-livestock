package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.infrastructure.persistence.entity.FarmSignalRevisionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FarmSignalRevisionJpaRepository
        extends JpaRepository<FarmSignalRevisionJpaEntity, Long> {
}
