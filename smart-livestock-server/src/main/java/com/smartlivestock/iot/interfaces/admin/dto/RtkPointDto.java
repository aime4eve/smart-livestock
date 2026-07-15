package com.smartlivestock.iot.interfaces.admin.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * RTK reference point request/response DTO.
 * <p>
 * On create/update the client may send either decimal {@code latitude/longitude}
 * or DMS strings {@code dmsLat/dmsLng}.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class RtkPointDto {

    private Long id;
    private String locationName;
    private String pointLabel;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String dmsLat;
    private String dmsLng;
    private Instant createdAt;

    public RtkPointDto() {
    }

    public static RtkPointDto from(RtkReferencePoint p) {
        RtkPointDto dto = new RtkPointDto();
        dto.id = p.getId();
        dto.locationName = p.getLocationName();
        dto.pointLabel = p.getPointLabel();
        dto.latitude = p.getLatitude();
        dto.longitude = p.getLongitude();
        dto.createdAt = p.getCreatedAt();
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public String getPointLabel() { return pointLabel; }
    public void setPointLabel(String pointLabel) { this.pointLabel = pointLabel; }

    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }

    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }

    public String getDmsLat() { return dmsLat; }
    public void setDmsLat(String dmsLat) { this.dmsLat = dmsLat; }

    public String getDmsLng() { return dmsLng; }
    public void setDmsLng(String dmsLng) { this.dmsLng = dmsLng; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
