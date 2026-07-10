package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.TileDownloadLog;
import com.smartlivestock.ranch.domain.repository.TileDownloadLogRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.TileDownloadLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class TileDownloadLogRepositoryImpl implements TileDownloadLogRepository {
    private final SpringDataTileDownloadLogRepository springDataRepo;

    @Override
    public TileDownloadLog save(TileDownloadLog log) {
        return TileDownloadLogMapper.toDomain(springDataRepo.save(TileDownloadLogMapper.toJpaEntity(log)));
    }
    @Override
    public List<TileDownloadLog> findByUserId(Long userId) {
        return springDataRepo.findByUserId(userId).stream().map(TileDownloadLogMapper::toDomain).toList();
    }
}
