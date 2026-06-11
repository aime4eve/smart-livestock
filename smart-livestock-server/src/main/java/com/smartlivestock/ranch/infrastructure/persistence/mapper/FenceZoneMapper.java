package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.FenceZone;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.infrastructure.persistence.entity.FenceZoneJpaEntity;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public final class FenceZoneMapper {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private FenceZoneMapper() {}

    public static FenceZoneJpaEntity toJpaEntity(FenceZone zone) {
        FenceZoneJpaEntity jpa = new FenceZoneJpaEntity();
        jpa.setId(zone.getId());
        jpa.setFenceId(zone.getFenceId());
        jpa.setFarmId(zone.getFarmId());
        jpa.setName(zone.getName());
        jpa.setZoneType(zone.getZoneType());
        jpa.setVertices(toVerticesJson(zone.getVertices()));
        jpa.setAlertRadius(zone.getAlertRadius());
        jpa.setSeverity(zone.getSeverity());
        jpa.setActive(zone.isActive());
        return jpa;
    }

    public static FenceZone toDomain(FenceZoneJpaEntity jpa) {
        FenceZone zone = new FenceZone();
        zone.setId(jpa.getId());
        zone.setFenceId(jpa.getFenceId());
        zone.setFarmId(jpa.getFarmId());
        zone.setName(jpa.getName());
        zone.setZoneType(jpa.getZoneType());
        zone.setVertices(fromVerticesJson(jpa.getVertices()));
        zone.setAlertRadius(jpa.getAlertRadius() != null ? jpa.getAlertRadius() : 20);
        zone.setSeverity(jpa.getSeverity() != null ? jpa.getSeverity() : "INFO");
        zone.setActive(jpa.getActive() != null ? jpa.getActive() : true);
        return zone;
    }

    private static String toVerticesJson(List<GpsCoordinate> vertices) {
        if (vertices == null || vertices.isEmpty()) return null;
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
            throw new IllegalStateException("Failed to serialize fence zone vertices", e);
        }
    }

    private static List<GpsCoordinate> fromVerticesJson(String json) {
        if (json == null || json.isBlank() || "[]".equals(json.trim())) return null;
        try {
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
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to deserialize fence zone vertices", e);
        }
    }
}
