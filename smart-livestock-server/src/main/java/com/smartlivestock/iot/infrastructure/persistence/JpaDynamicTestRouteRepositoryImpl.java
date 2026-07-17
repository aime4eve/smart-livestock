package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.DynamicTestRoute;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.DynamicTestRouteJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDynamicTestRouteRepositoryImpl implements DynamicTestRouteRepository {

    private final SpringDataDynamicTestRouteRepository springDataRepo;

    @Override
    public DynamicTestRoute save(DynamicTestRoute route) {
        DynamicTestRouteJpaEntity jpa = toJpa(route);
        if (route.getId() != null) {
            springDataRepo.findById(route.getId())
                    .ifPresent(existing -> jpa.setCreatedAt(existing.getCreatedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<DynamicTestRoute> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public List<DynamicTestRoute> findAll() {
        return springDataRepo.findAll().stream().map(this::toDomain).toList();
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }

    @Override
    public boolean existsById(Long id) {
        return springDataRepo.existsById(id);
    }

    private DynamicTestRouteJpaEntity toJpa(DynamicTestRoute r) {
        DynamicTestRouteJpaEntity jpa = new DynamicTestRouteJpaEntity();
        jpa.setId(r.getId());
        jpa.setName(r.getName());
        jpa.setDescription(r.getDescription());
        return jpa;
    }

    private DynamicTestRoute toDomain(DynamicTestRouteJpaEntity jpa) {
        DynamicTestRoute r = new DynamicTestRoute();
        r.setId(jpa.getId());
        r.setName(jpa.getName());
        r.setDescription(jpa.getDescription());
        r.setCreatedAt(jpa.getCreatedAt());
        r.setUpdatedAt(jpa.getUpdatedAt());
        return r;
    }
}
