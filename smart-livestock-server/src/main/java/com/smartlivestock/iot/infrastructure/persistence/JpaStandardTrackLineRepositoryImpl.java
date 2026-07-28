package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.StandardTrackLine;
import com.smartlivestock.iot.domain.repository.StandardTrackLineRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.StandardTrackLineJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaStandardTrackLineRepositoryImpl implements StandardTrackLineRepository {

    private final SpringDataStandardTrackLineRepository springDataRepo;

    @Override
    public StandardTrackLine save(StandardTrackLine line) {
        StandardTrackLineJpaEntity jpa = toJpa(line);
        if (line.getId() != null) {
            springDataRepo.findById(line.getId())
                    .ifPresent(existing -> jpa.setCreatedAt(existing.getCreatedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<StandardTrackLine> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public List<StandardTrackLine> findByTenantIdOrderByCreatedAtDesc(Long tenantId) {
        return springDataRepo.findByTenantIdOrderByCreatedAtDesc(tenantId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }

    private StandardTrackLineJpaEntity toJpa(StandardTrackLine l) {
        StandardTrackLineJpaEntity jpa = new StandardTrackLineJpaEntity();
        jpa.setId(l.getId());
        jpa.setTenantId(l.getTenantId());
        jpa.setName(l.getName());
        jpa.setStatus(l.getStatus());
        jpa.setPointCount(l.getPointCount());
        jpa.setLengthM(l.getLengthM());
        jpa.setStartLng(l.getStartLng());
        jpa.setStartLat(l.getStartLat());
        jpa.setSourceFile(l.getSourceFile());
        jpa.setCreatedAt(l.getCreatedAt());
        return jpa;
    }

    private StandardTrackLine toDomain(StandardTrackLineJpaEntity jpa) {
        StandardTrackLine l = new StandardTrackLine();
        l.setId(jpa.getId());
        l.setTenantId(jpa.getTenantId());
        l.setName(jpa.getName());
        l.setStatus(jpa.getStatus());
        l.setPointCount(jpa.getPointCount());
        l.setLengthM(jpa.getLengthM());
        l.setStartLng(jpa.getStartLng());
        l.setStartLat(jpa.getStartLat());
        l.setSourceFile(jpa.getSourceFile());
        l.setCreatedAt(jpa.getCreatedAt());
        return l;
    }
}
