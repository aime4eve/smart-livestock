package com.smartlivestock.datagen.application.dto;

import java.util.List;

public record DatagenControlRequest(boolean enabled, List<Long> deviceIds) {}
