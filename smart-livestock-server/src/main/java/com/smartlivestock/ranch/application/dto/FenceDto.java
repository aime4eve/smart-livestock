package com.smartlivestock.ranch.application.dto;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;

public record FenceDto(
        Long id,
        Long farmId,
        String name,
        List<GpsCoordinate> vertices,
        String color,
        boolean active,
        int version,
        String fenceType,
        String shape,
        int livestockCount,
        Map<String, Object> generationMetadata
) {
    private static final Logger log = LoggerFactory.getLogger(FenceDto.class);
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    public static FenceDto from(Fence fence) {
        return from(fence, 0);
    }

    /**
     * @param livestockCount livestock with a GPS fix currently inside the fence
     *                       (computed by the caller for list endpoints; 0 for
     *                       single-fence mutations)
     */
    public static FenceDto from(Fence fence, int livestockCount) {
        return new FenceDto(
                fence.getId(),
                fence.getFarmId(),
                fence.getName(),
                fence.getVertices(),
                fence.getColor(),
                fence.isActive(),
                fence.getVersion(),
                fence.getFenceType(),
                fence.getShape(),
                livestockCount,
                parseGenerationMetadata(fence.getId(), fence.getGenerationMetadata())
        );
    }

    /**
     * Echo the stored JSON metadata as a Map; degrade to null (never throw)
     * when the payload is absent or malformed so reads stay safe.
     */
    private static Map<String, Object> parseGenerationMetadata(Long fenceId, String json) {
        if (json == null || json.isBlank()) {
            return null;
        }
        try {
            return OBJECT_MAPPER.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (JsonProcessingException e) {
            log.warn("Failed to deserialize generation metadata for fence {}: {}", fenceId, e.getMessage());
            return null;
        }
    }
}
