package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.application.dto.TileSourceDto;
import com.smartlivestock.ranch.domain.model.FarmTileTask;
import com.smartlivestock.ranch.domain.model.TileRegion;
import com.smartlivestock.ranch.domain.repository.FarmTileTaskRepository;
import com.smartlivestock.ranch.domain.repository.TileGenerationTaskRepository;
import com.smartlivestock.ranch.domain.repository.TileDownloadLogRepository;
import com.smartlivestock.ranch.domain.repository.TileRegionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TileAdminServiceTest {

    @Mock private TileRegionRepository tileRegionRepository;
    @Mock private TileGenerationTaskRepository tileGenerationTaskRepository;
    @Mock private FarmTileTaskRepository farmTileTaskRepository;
    @Mock private TileDownloadLogRepository tileDownloadLogRepository;

    private TileAdminService createService() {
        var svc = new TileAdminService(tileRegionRepository, tileGenerationTaskRepository,
                farmTileTaskRepository, tileDownloadLogRepository);
        return svc;
    }

    @Test
    void handleFarmTileDetection_matchingRegion_createsReadyTask() {
        TileRegion region = new TileRegion("changsha", 112.8, 28.1, 113.1, 28.4);
        region.setId(1L);
        region.setStatus("ready");
        when(tileRegionRepository.findIntersecting(112.8, 28.1, 113.1, 28.4))
                .thenReturn(List.of(region));
        when(farmTileTaskRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var svc = createService();
        FarmTileStatusDto result = svc.handleFarmTileDetection(1L,
                new double[]{112.8, 28.1, 113.1, 28.4}, 0.8);

        assertEquals(1, result.regions().size());
        assertFalse(result.coverageWarning());
        verify(farmTileTaskRepository).save(any(FarmTileTask.class));
    }

    @Test
    void handleFarmTileDetection_noCoverage_createsGenerationTask() {
        when(tileRegionRepository.findIntersecting(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(List.of());
        when(tileGenerationTaskRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var svc = createService();
        FarmTileStatusDto result = svc.handleFarmTileDetection(1L,
                new double[]{116.0, 39.5, 116.5, 40.0}, 0.1);

        assertTrue(result.regions().isEmpty());
        verify(tileGenerationTaskRepository).save(any());
    }

    @Test
    void handleFarmTileDetection_lowCoverage_createsCustomRegion() {
        when(tileRegionRepository.findIntersecting(anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(List.of());
        when(tileGenerationTaskRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var svc = createService();
        FarmTileStatusDto result = svc.handleFarmTileDetection(1L,
                new double[]{112.9, 28.15, 113.05, 28.2}, 0.2);

        assertTrue(result.regions().isEmpty());
        verify(tileGenerationTaskRepository).save(any());
    }

    @Test
    void getFarmTileSources_returnsReadySources() {
        FarmTileTask task = new FarmTileTask(1L, 10L);
        task.setStatus("ready");
        when(farmTileTaskRepository.findByFarmId(1L)).thenReturn(List.of(task));

        TileRegion region = new TileRegion("changsha", 112.8, 28.1, 113.1, 28.4);
        region.setId(10L);
        region.setStatus("ready");
        when(tileRegionRepository.findAllByIds(List.of(10L))).thenReturn(List.of(region));

        var svc = createService();
        List<TileSourceDto> sources = svc.getFarmTileSources(1L);

        assertEquals(1, sources.size());
        assertEquals("changsha", sources.get(0).sourceName());
        assertTrue(sources.get(0).tileUrl().contains("/tiles/changsha/"));
    }
}
