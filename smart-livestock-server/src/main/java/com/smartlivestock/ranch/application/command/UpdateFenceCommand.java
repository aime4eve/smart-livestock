package com.smartlivestock.ranch.application.command;

import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;

/**
 * @param shape persisted form shape (NIX-410): polygon | circle | rectangle;
 *              null leaves the stored shape untouched (whitelist update)
 */
public record UpdateFenceCommand(String name, List<GpsCoordinate> vertices, String color,
                                 String shape, Integer expectedVersion) {
}
