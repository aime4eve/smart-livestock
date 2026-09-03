package com.smartlivestock.licensing.infrastructure;

import com.smartlivestock.licensing.domain.HostFingerprint;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HexFormat;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class HostFingerprintReaderTest {

    @TempDir
    Path tempDir;

    private static String sha256Hex(String value) {
        try {
            return HexFormat.of().formatHex(
                    MessageDigest.getInstance("SHA-256")
                            .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    @Nested
    @DisplayName("read")
    class Read {

        @Test
        @DisplayName("hashes the stripped machine-id content")
        void hashesStrippedContent() throws Exception {
            Path source = tempDir.resolve("machine-id");
            Files.writeString(source, "a1b2c3-machine-id\n");

            HostFingerprint fingerprint = new HostFingerprintReader(source).read();

            assertThat(fingerprint.getValue()).isEqualTo(sha256Hex("a1b2c3-machine-id"));
            assertThat(fingerprint.getValue()).hasSize(64).matches("[0-9a-f]{64}");
        }

        @Test
        @DisplayName("same host id yields a stable, equal fingerprint")
        void stableAndEqual() throws Exception {
            Path source = tempDir.resolve("machine-id");
            Files.writeString(source, "same-host\n");

            HostFingerprint first = new HostFingerprintReader(source).read();
            HostFingerprint second = new HostFingerprintReader(source).read();

            assertThat(first).isEqualTo(second);
            assertThat(first.matches(sha256Hex("same-host"))).isTrue();
        }
    }

    @Nested
    @DisplayName("fail fast")
    class FailFast {

        @Test
        @DisplayName("missing source file fails with the path in the message")
        void missingFile() {
            Path missing = tempDir.resolve("no-such-machine-id");

            assertThatThrownBy(() -> new HostFingerprintReader(missing).read())
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining(missing.toString());
        }

        @Test
        @DisplayName("blank source file fails")
        void blankFile() throws Exception {
            Path source = tempDir.resolve("machine-id");
            Files.writeString(source, "   \n");

            assertThatThrownBy(() -> new HostFingerprintReader(source).read())
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("blank");
        }
    }
}
