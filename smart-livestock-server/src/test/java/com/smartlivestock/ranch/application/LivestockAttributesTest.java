package com.smartlivestock.ranch.application;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Regression: an explicit "OTHER" from the client used to be rejected even
 * though OTHER is in the allowed list and blank input silently maps to it.
 */
class LivestockAttributesTest {

    @Test
    void explicitOtherIsAccepted() {
        assertThat(LivestockAttributes.normalizeBreed("OTHER")).isEqualTo("OTHER");
        assertThat(LivestockAttributes.normalizeBreed("other")).isEqualTo("OTHER");
    }

    @Test
    void chineseOtherAliasesAreAccepted() {
        assertThat(LivestockAttributes.normalizeBreed("其他")).isEqualTo("OTHER");
        assertThat(LivestockAttributes.normalizeBreed("其它")).isEqualTo("OTHER");
    }

    @Test
    void blankMapsToOther() {
        assertThat(LivestockAttributes.normalizeBreed(null)).isEqualTo("OTHER");
        assertThat(LivestockAttributes.normalizeBreed("  ")).isEqualTo("OTHER");
    }

    @Test
    void knownAliasesStillResolve() {
        assertThat(LivestockAttributes.normalizeBreed("西门塔尔")).isEqualTo("SIMMENTAL");
        assertThat(LivestockAttributes.normalizeBreed("angus")).isEqualTo("ANGUS");
    }

    @Test
    void unknownBreedIsRejected() {
        assertThatThrownBy(() -> LivestockAttributes.normalizeBreed("HOLSTEIN"))
                .isInstanceOf(ApiException.class);
    }
}
