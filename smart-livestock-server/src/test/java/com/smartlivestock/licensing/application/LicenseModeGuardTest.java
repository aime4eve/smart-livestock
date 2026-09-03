package com.smartlivestock.licensing.application;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the HOSTED/ONPREM mutual-exclusion guard (NIX-184 T5).
 */
class LicenseModeGuardTest {

    @Test
    void onPremModeIsDetectedCaseInsensitively() {
        assertThat(new LicenseModeGuard("ONPREM").isOnPrem()).isTrue();
        assertThat(new LicenseModeGuard("onprem").isOnPrem()).isTrue();
        assertThat(new LicenseModeGuard("HOSTED").isOnPrem()).isFalse();
        assertThat(new LicenseModeGuard("HOSTED").modeName()).isEqualTo("HOSTED");
        assertThat(new LicenseModeGuard("onprem").modeName()).isEqualTo("ONPREM");
    }

    @Test
    void requireOnPremPassesOnlyInOnPremMode() {
        assertThatCode(new LicenseModeGuard("ONPREM")::requireOnPrem).doesNotThrowAnyException();

        assertThatThrownBy(new LicenseModeGuard("HOSTED")::requireOnPrem)
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode())
                        .isEqualTo(ErrorCode.AUTH_FORBIDDEN))
                .hasMessage("license.onpremOnly");
    }

    @Test
    void requireSelfServiceAllowedPassesOnlyInHostedMode() {
        assertThatCode(new LicenseModeGuard("HOSTED")::requireSelfServiceAllowed)
                .doesNotThrowAnyException();

        assertThatThrownBy(new LicenseModeGuard("ONPREM")::requireSelfServiceAllowed)
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode())
                        .isEqualTo(ErrorCode.LICENSE_REQUIRED))
                .hasMessage("license.selfServiceDisabled");
    }
}
