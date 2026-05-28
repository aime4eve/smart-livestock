package com.smartlivestock.shared.scope;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class FarmScopeResolverTest {

    private final FarmScopeResolver resolver = new FarmScopeResolver();

    // === Write scope ===

    @Test
    void shouldResolveWriteScopeFromPath() {
        Long farmId = resolver.resolve(FarmScopeType.WRITE, 1L, null);
        assertThat(farmId).isEqualTo(1L);
    }

    @Test
    void shouldRejectWriteScopeWithOnlyHeader() {
        assertThatThrownBy(() -> resolver.resolve(FarmScopeType.WRITE, null, 1L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("path");
    }

    @Test
    void shouldRejectWriteScopeWithBothSources() {
        assertThatThrownBy(() -> resolver.resolve(FarmScopeType.WRITE, 1L, 2L))
            .isInstanceOf(ApiException.class)
            .extracting(e -> ((ApiException) e).getCode())
            .isEqualTo(ErrorCode.FARM_SCOPE_CONFLICT);
    }

    // === Read scope ===

    @Test
    void shouldResolveReadScopeFromPath() {
        Long farmId = resolver.resolve(FarmScopeType.READ, 1L, null);
        assertThat(farmId).isEqualTo(1L);
    }

    @Test
    void shouldResolveReadScopeFromHeaderOnly() {
        Long farmId = resolver.resolve(FarmScopeType.READ, null, 2L);
        assertThat(farmId).isEqualTo(2L);
    }

    @Test
    void shouldRejectReadScopeWithBothSources() {
        assertThatThrownBy(() -> resolver.resolve(FarmScopeType.READ, 1L, 2L))
            .isInstanceOf(ApiException.class);
    }

    // === No scope ===

    @Test
    void shouldReturnNullForNoScope() {
        Long farmId = resolver.resolve(FarmScopeType.NONE, null, null);
        assertThat(farmId).isNull();
    }
}
