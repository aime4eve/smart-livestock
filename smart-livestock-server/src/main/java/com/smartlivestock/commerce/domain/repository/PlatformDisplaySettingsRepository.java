package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.PlatformDisplaySettings;

import java.util.Optional;

/**
 * Single-row settings table: the seed row is always the lowest id, so the
 * read side is a plain find and the write side an upsert through
 * {@link #save}.
 */
public interface PlatformDisplaySettingsRepository {

    Optional<PlatformDisplaySettings> findFirst();

    PlatformDisplaySettings save(PlatformDisplaySettings settings);
}
