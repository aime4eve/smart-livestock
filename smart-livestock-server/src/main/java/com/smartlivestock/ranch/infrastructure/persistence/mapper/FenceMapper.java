package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.infrastructure.persistence.entity.FenceJpaEntity;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class FenceMapper {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private FenceMapper() {}

    public static FenceJpaEntity toJpaEntity(Fence fence) {
        FenceJpaEntity jpa = new FenceJpaEntity();
        jpa.setId(fence.getId());
        jpa.setFarmId(fence.getFarmId());
        jpa.setName(fence.getName());
        jpa.setVertices(toVerticesJson(fence.getVertices()));
        jpa.setColor(fence.getColor());
        jpa.setStatus(fence.isActive() ? "ACTIVE" : "DISABLED");
        jpa.setVersion(fence.getVersion());
        jpa.setFenceType(fence.getFenceType());
        return jpa;
    }

    public static void updateEntity(FenceJpaEntity existing, Fence fence) {
        existing.setName(fence.getName());
        existing.setVertices(toVerticesJson(fence.getVertices()));
        existing.setColor(fence.getColor());
        existing.setStatus(fence.isActive() ? "ACTIVE" : "DISABLED");
        existing.setVersion(fence.getVersion());
        existing.setFenceType(fence.getFenceType());
    }

    public static Fence toDomain(FenceJpaEntity jpa) {
        Fence fence = new Fence();
        fence.setId(jpa.getId());
        fence.setFarmId(jpa.getFarmId());
        fence.setName(jpa.getName());
        fence.setVertices(fromVerticesJson(jpa.getVertices()));
        fence.setColor(jpa.getColor());
        if ("DISABLED".equals(jpa.getStatus())) {
            fence.disable();
        }
        fence.setVersion(jpa.getVersion());
        fence.setFenceType(jpa.getFenceType());
        return fence;
    }

    private static String toVerticesJson(List<GpsCoordinate> vertices) {
        if (vertices == null || vertices.isEmpty()) {
            return "[]";
        }
        try {
            List<Map<String, String>> list = new ArrayList<>();
            for (GpsCoordinate coord : vertices) {
                list.add(Map.of(
                    "latitude", coord.latitude().toPlainString(),
                    "longitude", coord.longitude().toPlainString()
                ));
            }
            return OBJECT_MAPPER.writeValueAsString(list);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize fence vertices", e);
        }
    }

    private static List<GpsCoordinate> fromVerticesJson(String json) {
        if (json == null || json.isBlank() || "[]".equals(json.trim())) {
            return new ArrayList<>();
        }
        try {
            // Try object format first: [{latitude: "x", longitude: "y"}, ...]
            List<Map<String, String>> objList = OBJECT_MAPPER.readValue(
                json, new TypeReference<List<Map<String, String>>>() {});
            List<GpsCoordinate> coordinates = new ArrayList<>();
            for (Map<String, String> item : objList) {
                coordinates.add(new GpsCoordinate(
                    new BigDecimal(item.get("latitude")),
                    new BigDecimal(item.get("longitude"))
                ));
            }
            return coordinates;
        } catch (JsonProcessingException objFormatFailed) {
            // Fallback to array format: [[lng, lat], ...]
            try {
                List<List<BigDecimal>> arrayCoords = OBJECT_MAPPER.readValue(
                    json, new TypeReference<List<List<BigDecimal>>>() {});
                List<GpsCoordinate> coordinates = new ArrayList<>();
                for (List<BigDecimal> pair : arrayCoords) {
                    if (pair.size() >= 2) {
                        coordinates.add(new GpsCoordinate(pair.get(1), pair.get(0)));
                    }
                }
                return coordinates;
            } catch (JsonProcessingException e) {
                throw new IllegalStateException("Failed to deserialize fence vertices", e);
            }
        }
    }
}
