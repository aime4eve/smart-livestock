package com.smartlivestock.ranch.application.command;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;

public record UpdateFenceCommand(String name, List<GpsCoordinate> vertices, String color, Integer expectedVersion) {
}
