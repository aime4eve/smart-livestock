package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.LivestockDto;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
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

    @Transactional
    public LivestockDto createLivestock(Long farmId, String livestockCode) {
        Livestock livestock = new Livestock();
        livestock.setFarmId(farmId);
        livestock.setLivestockCode(livestockCode);
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
    public void deleteLivestock(Long id) {
        if (livestockRepository.findById(id).isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "牲畜不存在: " + id);
        }
        livestockRepository.deleteById(id);
    }
}
