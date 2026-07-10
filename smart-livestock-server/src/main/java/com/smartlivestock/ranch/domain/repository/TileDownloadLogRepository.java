package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.TileDownloadLog;
import java.util.List;

public interface TileDownloadLogRepository {
    TileDownloadLog save(TileDownloadLog log);
    List<TileDownloadLog> findByUserId(Long userId);
}
