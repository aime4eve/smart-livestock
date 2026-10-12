package com.smartlivestock.identity.application.dto;

import com.smartlivestock.identity.domain.model.Farm;

import java.math.BigDecimal;

public record FarmDto(
        Long id,
        Long tenantId,
        String name,
        BigDecimal latitude,
        BigDecimal longitude,
        BigDecimal areaHectares,
        String timezone,
        Integer utcOffsetMinutes
) {
    public static FarmDto from(Farm farm) {
        return new FarmDto(
                farm.getId(),
                farm.getTenantId(),
                farm.getName(),
                farm.getLatitude(),
                farm.getLongitude(),
                farm.getAreaHectares(),
                farm.getTimezone(),
                null
        );
    }

    /** Presentation offset resolved through the farm → tenant → platform chain. */
    public static FarmDto from(Farm farm, int utcOffsetMinutes) {
        return new FarmDto(
                farm.getId(),
                farm.getTenantId(),
                farm.getName(),
                farm.getLatitude(),
                farm.getLongitude(),
                farm.getAreaHectares(),
                farm.getTimezone(),
                utcOffsetMinutes
        );
    }
}
