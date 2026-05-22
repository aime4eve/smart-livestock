package com.smartlivestock.shared.web;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class FarmIdPathParserTest {

    @Nested
    class ExtractFarmId {

        @Test
        void standardFarmPath() {
            assertThat(FarmIdPathParser.extractFarmId("/api/v1/farms/42/livestock"))
                    .isEqualTo(42L);
        }

        @Test
        void openApiFarmPath() {
            assertThat(FarmIdPathParser.extractFarmId("/api/v1/open/farms/7/fences"))
                    .isEqualTo(7L);
        }

        @Test
        void adminNestedFarmPath() {
            assertThat(FarmIdPathParser.extractFarmId("/api/v1/admin/tenants/3/farms/15/livestock"))
                    .isEqualTo(15L);
        }

        @Test
        void noFarmSegment_returnsNull() {
            assertThat(FarmIdPathParser.extractFarmId("/api/v1/auth/login"))
                    .isNull();
        }

        @Test
        void farmSegmentNotNumber_returnsNull() {
            assertThat(FarmIdPathParser.extractFarmId("/api/v1/farms/abc/livestock"))
                    .isNull();
        }

        @Test
        void farmAtEndOfPath_returnsNull() {
            assertThat(FarmIdPathParser.extractFarmId("/api/v1/farms"))
                    .isNull();
        }
    }
}
