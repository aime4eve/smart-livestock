package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;

public class Farm extends AggregateRoot {

    private Long tenantId;
    private String name;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal areaHectares;

    public Farm() {}

    public Farm(Long tenantId, String name, BigDecimal latitude, BigDecimal longitude, BigDecimal areaHectares) {
        this.tenantId = tenantId;
        this.name = name;
        this.latitude = latitude;
        this.longitude = longitude;
        this.areaHectares = areaHectares;
    }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }

    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }

    public BigDecimal getAreaHectares() { return areaHectares; }
    public void setAreaHectares(BigDecimal areaHectares) { this.areaHectares = areaHectares; }
}
