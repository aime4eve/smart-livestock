package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.TileGenerationTask;
import com.smartlivestock.ranch.domain.repository.TileGenerationTaskRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.TileGenerationTaskMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class TileGenerationTaskRepositoryImpl implements TileGenerationTaskRepository {
    private final SpringDataTileGenerationTaskRepository springDataRepo;

    @Override
    public TileGenerationTask save(TileGenerationTask task) {
        return TileGenerationTaskMapper.toDomain(springDataRepo.save(TileGenerationTaskMapper.toJpaEntity(task)));
    }
    @Override
    public Optional<TileGenerationTask> findById(Long id) {
        return springDataRepo.findById(id).map(TileGenerationTaskMapper::toDomain);
    }
    @Override
    public List<TileGenerationTask> findByStatus(String status) {
        return springDataRepo.findByStatus(status).stream().map(TileGenerationTaskMapper::toDomain).toList();
    }
    @Override
    public List<TileGenerationTask> findAll() {
        return springDataRepo.findAll().stream().map(TileGenerationTaskMapper::toDomain).toList();
    }
}
