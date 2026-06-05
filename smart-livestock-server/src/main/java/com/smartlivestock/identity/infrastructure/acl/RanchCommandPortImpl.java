package com.smartlivestock.identity.infrastructure.acl;

import com.smartlivestock.identity.domain.port.RanchCommandPort;
import com.smartlivestock.ranch.application.TileAdminService;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.service.TileCoverageCalculator;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.IntStream;

@Component("identityRanchCommandPort")
public class RanchCommandPortImpl implements RanchCommandPort {

    private final FenceRepository fenceRepository;
    private final TileCoverageCalculator coverageCalculator;
    private final TileAdminService tileAdminService;

    public RanchCommandPortImpl(FenceRepository fenceRepository,
                                 TileCoverageCalculator coverageCalculator,
                                 TileAdminService tileAdminService) {
        this.fenceRepository = fenceRepository;
        this.coverageCalculator = coverageCalculator;
        this.tileAdminService = tileAdminService;
    }

    @Override
    public void createBoundaryFenceAndDetectTiles(Long farmId, String farmName,
                                                   List<BigDecimal> latitudes, List<BigDecimal> longitudes) {
        List<GpsCoordinate> vertices = IntStream.range(0, latitudes.size())
                .mapToObj(i -> new GpsCoordinate(latitudes.get(i), longitudes.get(i)))
                .toList();

        Fence boundaryFence = new Fence(farmId, farmName + " 边界", vertices, "#FF0000");
        boundaryFence.setFenceType("boundary");
        fenceRepository.save(boundaryFence);

        double[] bbox = coverageCalculator.calculateBbox(vertices);
        double ratio = coverageCalculator.coverageRatio(vertices);
        tileAdminService.handleFarmTileDetection(farmId, bbox, ratio);
    }
}
