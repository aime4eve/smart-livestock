package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;

/**
 * Daily temperature aggregation for the /health/stats 7-day trends
 * (NIX-323 data-truthfulness fix: replaces Math.random placeholders).
 * normalReadings counts readings with |delta| <= 0.5°C against baseline.
 */
public record DailyTemperatureStat(String date, BigDecimal avgTemperature,
                                   long readings, long normalReadings) {}
