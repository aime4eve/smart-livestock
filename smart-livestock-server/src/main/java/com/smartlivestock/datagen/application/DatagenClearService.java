package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.dto.DatagenClearRequest;
import com.smartlivestock.datagen.application.dto.DatagenClearResultDto;
import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.domain.repository.DatagenFarmControlRepository;
import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DatagenClearService {
    private final DatagenFarmAccessService accessService;
    private final DatagenOperatorContextResolver operatorResolver;
    private final DatagenFarmControlRepository controlRepository;
    private final DatagenDataQueryService dataQueryService;
    private final DatagenAuditService auditService;

    @Transactional(readOnly = true)
    public DatagenClearResultDto preview(DatagenClearRequest request) {
        DatagenOperatorContext operator = operatorResolver.resolve();
        Farm farm = accessService.requireAccessibleFarm(request.farmId(), operator);
        Range range = resolveRange(request);
        return dataQueryService.preview(farm.getId(), range.from(), range.to());
    }

    @Transactional
    public DatagenClearResultDto clear(DatagenClearRequest request) {
        DatagenOperatorContext operator = operatorResolver.resolve();
        Farm farm = accessService.requireAccessibleFarm(request.farmId(), operator);
        if (request.confirmText() == null || !request.confirmText().equals("清空")) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "error.datagen.confirmTextMismatch");
        }

        DatagenFarmControl control = controlRepository.findByFarmId(farm.getId()).orElse(null);
        if (control != null) {
            control = controlRepository.lockByFarmId(farm.getId()).orElseThrow();
        }
        if (control != null && control.isEnabled()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "error.datagen.runningCannotClear");
        }

        Range range = resolveRange(request);
        DatagenClearResultDto result =
                dataQueryService.clear(farm.getId(), range.from(), range.to());
        auditService.record("CLEAR_DATA", farm.getId(), operator, Map.of(
                "rangeType", request.rangeType(),
                "from", range.from().toString(),
                "to", range.to().toString(),
                "result", result));
        return result;
    }

    private Range resolveRange(DatagenClearRequest request) {
        Instant to = Instant.now();
        Instant from = switch (request.rangeType() == null ? "" : request.rangeType()) {
            case "LAST_24_HOURS" -> to.minusSeconds(24 * 3600);
            case "LAST_7_DAYS" -> to.minusSeconds(7 * 24 * 3600);
            case "ALL" -> Instant.EPOCH;
            case "CUSTOM" -> {
                if (request.from() == null || request.to() == null
                        || !request.from().isBefore(request.to())) {
                    throw new ApiException(ErrorCode.VALIDATION_ERROR,
                            "error.datagen.invalidTimeRange");
                }
                yield request.from();
            }
            default -> throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "error.datagen.invalidTimeRange");
        };

        if ("CUSTOM".equals(request.rangeType())) {
            to = request.to();
        }
        return new Range(from, to);
    }

    private record Range(Instant from, Instant to) {}
}
