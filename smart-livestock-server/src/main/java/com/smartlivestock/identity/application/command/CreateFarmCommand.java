package com.smartlivestock.identity.application.command;

import java.math.BigDecimal;

public record CreateFarmCommand(String name, BigDecimal latitude, BigDecimal longitude, BigDecimal areaHectares) {
}
