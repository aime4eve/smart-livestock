package com.smartlivestock.ranch.application.command;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;
import java.util.Map;

/**
 * @param generationMetadata optional payload describing how the fence was
 *                           generated (e.g. DEVICE_TRACK); null for plain
 *                           manual creation
 */
public record CreateFenceCommand(Long farmId, String name, List<GpsCoordinate> vertices, String color,
                                 String fenceType, Map<String, Object> generationMetadata) {
}
