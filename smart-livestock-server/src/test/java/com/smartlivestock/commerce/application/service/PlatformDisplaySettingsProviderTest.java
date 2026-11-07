package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.LockedTilePolicy;
import com.smartlivestock.commerce.domain.model.PlatformDisplaySettings;
import com.smartlivestock.commerce.domain.repository.PlatformDisplaySettingsRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

/**
 * Read-fallback behaviour of the NIX-389 policy provider: a missing row or a
 * failing repository read degrades to SHOW_LOCKED (tiles stay visible) — the
 * overview hot path must never take a settings outage as "hide everything".
 */
@ExtendWith(MockitoExtension.class)
class PlatformDisplaySettingsProviderTest {

    @Mock
    private PlatformDisplaySettingsRepository settingsRepository;

    @InjectMocks
    private PlatformDisplaySettingsProvider provider;

    @Test
    @DisplayName("missing settings row falls back to SHOW_LOCKED")
    void missingRow_fallsBackToShowLocked() {
        when(settingsRepository.findFirst()).thenReturn(Optional.empty());

        assertThat(provider.current()).isEqualTo(LockedTilePolicy.SHOW_LOCKED);
    }

    @Test
    @DisplayName("repository failure falls back to SHOW_LOCKED")
    void repositoryFailure_fallsBackToShowLocked() {
        when(settingsRepository.findFirst()).thenThrow(new IllegalStateException("db down"));

        assertThat(provider.current()).isEqualTo(LockedTilePolicy.SHOW_LOCKED);
    }

    @Test
    @DisplayName("persisted HIDE policy is returned")
    void persistedHide_isReturned() {
        when(settingsRepository.findFirst())
                .thenReturn(Optional.of(new PlatformDisplaySettings(1L, LockedTilePolicy.HIDE, null, "seed")));

        assertThat(provider.current()).isEqualTo(LockedTilePolicy.HIDE);
    }

    @Test
    @DisplayName("cache hit within TTL does not re-read the repository")
    void cacheHit_skipsRepository() {
        when(settingsRepository.findFirst())
                .thenReturn(Optional.of(new PlatformDisplaySettings(1L, LockedTilePolicy.HIDE, null, "seed")));
        provider.current();

        assertThat(provider.current()).isEqualTo(LockedTilePolicy.HIDE);
        verify(settingsRepository, times(1)).findFirst();
        verifyNoMoreInteractions(settingsRepository);

        // invalidate() forces the next read back to the repository.
        provider.invalidate();
        provider.current();
        verify(settingsRepository, times(2)).findFirst();
    }
}
