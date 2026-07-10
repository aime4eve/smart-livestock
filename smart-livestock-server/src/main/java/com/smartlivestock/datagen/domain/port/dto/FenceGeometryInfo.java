package com.smartlivestock.datagen.domain.port.dto;

import java.util.List;

public record FenceGeometryInfo(
        Long fenceId, Long farmId, String name,
        List<CoordinateInfo> vertices
) {}
