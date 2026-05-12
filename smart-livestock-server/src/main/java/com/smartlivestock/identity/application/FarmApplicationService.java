package com.smartlivestock.identity.application;

import com.smartlivestock.identity.application.command.CreateFarmCommand;
import com.smartlivestock.identity.application.dto.FarmDto;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
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

    @Transactional
    public FarmDto createFarm(Long tenantId, CreateFarmCommand command) {
        Farm farm = new Farm(tenantId, command.name(), command.latitude(), command.longitude(), command.areaHectares());
        Farm saved = farmRepository.save(farm);
        return FarmDto.from(saved);
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
}
