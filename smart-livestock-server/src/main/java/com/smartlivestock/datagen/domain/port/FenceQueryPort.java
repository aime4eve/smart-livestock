package com.smartlivestock.datagen.domain.port;

import com.smartlivestock.datagen.domain.port.dto.FenceGeometryInfo;

import java.util.List;

/** ACL port: datagen -> Ranch. Queries fence geometry for fence breach scenarios. */
public interface FenceQueryPort {
    /** Find active fences for the farm that a livestock belongs to. */
    List<FenceGeometryInfo> findActiveFencesByLivestockId(Long livestockId);
}
