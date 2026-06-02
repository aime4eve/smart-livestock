package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.ranch.application.TileAdminService;
import com.smartlivestock.ranch.application.dto.FarmTileStatusDto;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.service.TileCoverageCalculator;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FarmApplicationService {

    private final FarmRepository farmRepository;
    private final TenantRepository tenantRepository;
    private final UserRepository userRepository;
    private final UserFarmAssignmentRepository assignmentRepository;
    private final FenceRepository fenceRepository;
    private final TileAdminService tileAdminService;
    private final TileCoverageCalculator coverageCalculator;

    @Transactional
    public FarmDto createFarm(Long tenantId, CreateFarmCommand command, Long userId) {
        if (!tenantRepository.existsById(tenantId)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "租户不存在: " + tenantId);
        }
        Farm farm = new Farm(tenantId, command.name(), command.latitude(), command.longitude(), command.areaHectares());
        Farm saved = farmRepository.save(farm);

        if (userId != null) {
            autoAssignOwner(userId, saved.getId(), tenantId);
        }

        if (command.boundaryVertices() != null && command.boundaryVertices().size() >= 3) {
            createBoundaryFenceAndDetectTiles(saved.getId(), command.name(), command.boundaryVertices());
        }

        return FarmDto.from(saved);
    }

    public void triggerTileDetection(Long farmId, String farmName, List<GpsCoordinate> vertices) {
        createBoundaryFenceAndDetectTiles(farmId, farmName, vertices);
    }

    private void createBoundaryFenceAndDetectTiles(Long farmId, String farmName, List<GpsCoordinate> vertices) {
        Fence boundaryFence = new Fence(farmId, farmName + " 边界", vertices, "#FF0000");
        boundaryFence.setFenceType("boundary");
        fenceRepository.save(boundaryFence);

        double[] bbox = coverageCalculator.calculateBbox(vertices);
        double ratio = coverageCalculator.coverageRatio(vertices);
        tileAdminService.handleFarmTileDetection(farmId, bbox, ratio);
    }

    private void autoAssignOwner(Long userId, Long farmId, Long tenantId) {
        var userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) return;

        var user = userOpt.get();
        if (!user.isOwner()) return;
        if (!tenantId.equals(user.getTenantId())) return;
        if (assignmentRepository.existsByUserIdAndFarmId(userId, farmId)) return;

        assignmentRepository.save(userId, farmId, "OWNER", "ACTIVE");
    }

    @Transactional(readOnly = true)
    public FarmDto getFarm(Long id) {
        Farm farm = farmRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + id));
        return FarmDto.from(farm);
    }

    @Transactional(readOnly = true)
    public List<FarmDto> listFarms(Long tenantId) {
        return farmRepository.findByTenantId(tenantId).stream()
                .map(FarmDto::from)
                .toList();
    }

    @Transactional
    public void deleteFarm(Long id) {
        if (farmRepository.findById(id).isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + id);
        }
        farmRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public Farm getFarmEntity(Long id) {
        return farmRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牧场不存在: " + id));
    }

    @Transactional
    public Farm saveFarm(Farm farm) {
        return farmRepository.save(farm);
    }
}
