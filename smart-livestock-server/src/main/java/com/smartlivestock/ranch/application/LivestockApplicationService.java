package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.LivestockDto;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.application.command.CreateLivestockCommand;
import com.smartlivestock.ranch.application.command.UpdateLivestockCommand;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LivestockApplicationService {

    private final LivestockRepository livestockRepository;
    private final HealthQueryPort healthQueryPort;
    private final IoTQueryPort iotQueryPort;

    @Transactional
    public LivestockDto createLivestock(CreateLivestockCommand command) {
        if (livestockRepository.findByLivestockCode(command.livestockCode()).isPresent()) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                    "牲畜编号已存在: " + command.livestockCode());
        }
        Livestock livestock = new Livestock();
        livestock.setFarmId(command.farmId());
        livestock.setLivestockCode(command.livestockCode());
        livestock.setBreed(command.breed());
        livestock.setGender(command.gender());
        livestock.setBirthDate(command.birthDate());
        livestock.setWeight(command.weight());
        Livestock saved = livestockRepository.save(livestock);
        return LivestockDto.from(saved);
    }

    @Transactional(readOnly = true)
    public LivestockDto getLivestock(Long id) {
        Livestock livestock = livestockRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牲畜不存在: " + id));
        HealthQueryPort.LivestockHealthState health = healthQueryPort.findHealthByLivestockId(id).orElse(null);
        return LivestockDto.detail(livestock, health);
    }

    @Transactional(readOnly = true)
    public List<LivestockDto> listByFarm(Long farmId) {
        return livestockRepository.findByFarmId(farmId).stream()
                .map(LivestockDto::from)
                .toList();
    }

    @Transactional
    public void updatePosition(Long id, BigDecimal lat, BigDecimal lng) {
        Livestock livestock = livestockRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牲畜不存在: " + id));
        livestock.updatePosition(lat, lng);
        livestockRepository.save(livestock);
    }

    @Transactional
    public LivestockDto updateLivestock(Long id, UpdateLivestockCommand command) {
        Livestock livestock = livestockRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牲畜不存在: " + id));
        if (!command.livestockCode().equals(livestock.getLivestockCode())) {
            livestockRepository.findByLivestockCode(command.livestockCode())
                    .ifPresent(existing -> {
                        if (!existing.getId().equals(id)) {
                            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                    "牲畜编号已存在: " + command.livestockCode());
                        }
                    });
        }
        livestock.updateInfo(command.livestockCode(), command.breed(),
                command.gender(), command.birthDate(), command.weight());
        Livestock saved = livestockRepository.save(livestock);
        return LivestockDto.from(saved);
    }

    @Transactional
    public void deleteLivestock(Long id) {
        Livestock livestock = livestockRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牲畜不存在: " + id));
        if (iotQueryPort.hasActiveInstallationByLivestock(id)) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "该牲畜仍有活跃设备安装，请先卸载");
        }
        livestockRepository.deleteById(id);
    }
}
