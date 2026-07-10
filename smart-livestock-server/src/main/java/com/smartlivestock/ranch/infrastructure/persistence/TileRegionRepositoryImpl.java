package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.TileRegion;
import com.smartlivestock.ranch.domain.repository.TileRegionRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.TileRegionMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class TileRegionRepositoryImpl implements TileRegionRepository {
    private final SpringDataTileRegionRepository springDataRepo;

    @Override
    public TileRegion save(TileRegion region) {
        return TileRegionMapper.toDomain(springDataRepo.save(TileRegionMapper.toJpaEntity(region)));
    }
    @Override
    public Optional<TileRegion> findById(Long id) {
        return springDataRepo.findById(id).map(TileRegionMapper::toDomain);
    }
    @Override
    public Optional<TileRegion> findByName(String name) {
        return springDataRepo.findByName(name).map(TileRegionMapper::toDomain);
    }
    @Override
    public List<TileRegion> findAll() {
        return springDataRepo.findAll().stream().map(TileRegionMapper::toDomain).toList();
    }
    @Override
    public List<TileRegion> findAllByIds(List<Long> ids) {
        return springDataRepo.findAllById(ids).stream().map(TileRegionMapper::toDomain).toList();
    }
    @Override
    public List<TileRegion> findByStatus(String status) {
        return springDataRepo.findByStatus(status).stream().map(TileRegionMapper::toDomain).toList();
    }
    @Override
    public List<TileRegion> findIntersecting(double minLon, double minLat, double maxLon, double maxLat) {
        return springDataRepo.findIntersecting(minLon, minLat, maxLon, maxLat).stream()
                .map(TileRegionMapper::toDomain).toList();
    }
}
