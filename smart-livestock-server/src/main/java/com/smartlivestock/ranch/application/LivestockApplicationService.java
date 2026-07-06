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
                    "error.livestockCodeDuplicate", new Object[]{command.livestockCode()});
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
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.livestockNotFound", new Object[]{id}));
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
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.livestockNotFound", new Object[]{id}));
        livestock.updatePosition(lat, lng);
        livestockRepository.save(livestock);
    }

    @Transactional
    public LivestockDto updateLivestock(Long id, UpdateLivestockCommand command) {
        Livestock livestock = livestockRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.livestockNotFound", new Object[]{id}));
        if (!command.livestockCode().equals(livestock.getLivestockCode())) {
            livestockRepository.findByLivestockCode(command.livestockCode())
                    .ifPresent(existing -> {
                        if (!existing.getId().equals(id)) {
                            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                                    "error.livestockCodeDuplicate", new Object[]{command.livestockCode()});
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
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.livestockNotFound", new Object[]{id}));
        if (iotQueryPort.hasActiveInstallationByLivestock(id)) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "error.livestockHasActiveInstallation", null);
        }
        livestockRepository.deleteById(id);
    }

    /**
     * Paginated livestock query with optional keyword search.
     */
    @Transactional(readOnly = true)
    public LivestockPage listByFarm(Long farmId, String keyword, int page, int pageSize) {
        String kw = (keyword != null && !keyword.isBlank()) ? keyword.trim() : null;
        int safePage = Math.max(1, page);
        int offset = (safePage - 1) * pageSize;
        List<LivestockDto> items;
        long total;
        if (kw != null) {
            items = livestockRepository.findByFarmIdAndKeyword(farmId, kw, offset, pageSize)
                    .stream().map(LivestockDto::from).toList();
            total = livestockRepository.countByFarmIdAndKeyword(farmId, kw);
        } else {
            items = livestockRepository.findByFarmIdPaged(farmId, offset, pageSize)
                    .stream().map(LivestockDto::from).toList();
            total = livestockRepository.countByFarmIdPaged(farmId);
        }
        return new LivestockPage(items, page, pageSize, total);
    }

    public record LivestockPage(List<LivestockDto> items, int page, int pageSize, long total) {}
}
