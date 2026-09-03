package com.smartlivestock.licensing.infrastructure;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.FileSystemResource;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ClasspathLicensePublicKeyRegistryTest {

    /** Raw 32 bytes of the test public key, base64 encoded (test resources). */
    private static final String TEST_RAW_KEY_B64 = "TjwpF7USYaTreaj5AbVHJ/+BLIdBplea+c3+20jRJ1w=";

    private static String keysJson(String keyId, String status) {
        return "{\"keys\":[{\"keyId\":\"" + keyId + "\",\"publicKey\":\"" + TEST_RAW_KEY_B64
                + "\",\"status\":\"" + status + "\"}]}";
    }

    @Nested
    @DisplayName("loading")
    class Loading {

        @Test
        @DisplayName("loads the committed production key list from main resources")
        void loadsProductionKeyList() {
            // src/main/resources is also on the test classpath; reference the file
            // directly so the test classpath shadowing of license-public-keys.json
            // (test variant) does not hide production key corruption.
            ClasspathLicensePublicKeyRegistry registry = new ClasspathLicensePublicKeyRegistry(
                    new FileSystemResource("src/main/resources/licensing/license-public-keys.json"));

            assertThat(registry.supports("sl-license-2026q3")).isTrue();
            assertThat(registry.size()).isEqualTo(1);
            // JDK reports Ed25519 keys as "Ed25519" or generic "EdDSA" depending on version.
            assertThat(registry.forKeyId("sl-license-2026q3").getAlgorithm())
                    .isIn("Ed25519", "EdDSA");
        }

        @Test
        @DisplayName("loads the test key list via classpath resource")
        void loadsTestClasspathKeyList() {
            ClasspathLicensePublicKeyRegistry registry = new ClasspathLicensePublicKeyRegistry(
                    new ClassPathResource("licensing/license-public-keys.json"));

            assertThat(registry.supports("sl-license-test")).isTrue();
            assertThat(registry.forKeyId("sl-license-test")).isNotNull();
        }

        @Test
        @DisplayName("accepts an explicit stream (tests / custom provisioning)")
        void loadsFromStream() {
            ClasspathLicensePublicKeyRegistry registry = new ClasspathLicensePublicKeyRegistry(
                    new ByteArrayInputStream(keysJson("k1", "rotated").getBytes(StandardCharsets.UTF_8)));

            assertThat(registry.supports("k1")).isTrue();
        }

        @Test
        @DisplayName("missing resource fails fast")
        void missingResourceFailsFast() {
            assertThatThrownBy(() -> new ClasspathLicensePublicKeyRegistry(
                    new ClassPathResource("licensing/does-not-exist.json")))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID));
        }
    }

    @Nested
    @DisplayName("resolution")
    class Resolution {

        @Test
        @DisplayName("unknown keyId is rejected with LICENSE_INVALID")
        void unknownKeyId() {
            ClasspathLicensePublicKeyRegistry registry = new ClasspathLicensePublicKeyRegistry(
                    new ByteArrayInputStream(keysJson("k1", "active").getBytes(StandardCharsets.UTF_8)));

            assertThat(registry.supports("unknown")).isFalse();
            assertThatThrownBy(() -> registry.forKeyId("unknown"))
                    .isInstanceOfSatisfying(DomainException.class, e -> {
                        assertThat(e.getCode()).isEqualTo(ErrorCode.LICENSE_INVALID);
                        assertThat(e.getMessage()).contains("unknown");
                    });
        }
    }

    @Nested
    @DisplayName("malformed key lists fail fast")
    class Malformed {

        @Test
        void rejectsInvalidJson() {
            assertThatThrownBy(() -> new ClasspathLicensePublicKeyRegistry(
                    new ByteArrayInputStream("not json".getBytes(StandardCharsets.UTF_8))))
                    .isInstanceOf(DomainException.class);
        }

        @Test
        void rejectsEmptyKeysArray() {
            assertThatThrownBy(() -> new ClasspathLicensePublicKeyRegistry(
                    new ByteArrayInputStream("{\"keys\":[]}".getBytes(StandardCharsets.UTF_8))))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("keys"));
        }

        @Test
        void rejectsWrongRawKeyLength() {
            String shortKey = Base64.getEncoder().encodeToString(new byte[16]);
            String json = "{\"keys\":[{\"keyId\":\"k1\",\"publicKey\":\"" + shortKey
                    + "\",\"status\":\"active\"}]}";

            assertThatThrownBy(() -> new ClasspathLicensePublicKeyRegistry(
                    new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8))))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("32 bytes"));
        }

        @Test
        void rejectsUnsupportedStatus() {
            assertThatThrownBy(() -> new ClasspathLicensePublicKeyRegistry(
                    new ByteArrayInputStream(keysJson("k1", "draft").getBytes(StandardCharsets.UTF_8))))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("status"));
        }

        @Test
        void rejectsDuplicateKeyId() {
            String json = "{\"keys\":["
                    + "{\"keyId\":\"k1\",\"publicKey\":\"" + TEST_RAW_KEY_B64 + "\",\"status\":\"active\"},"
                    + "{\"keyId\":\"k1\",\"publicKey\":\"" + TEST_RAW_KEY_B64 + "\",\"status\":\"rotated\"}"
                    + "]}";

            assertThatThrownBy(() -> new ClasspathLicensePublicKeyRegistry(
                    new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8))))
                    .isInstanceOfSatisfying(DomainException.class, e ->
                            assertThat(e.getMessage()).contains("duplicate"));
        }
    }
}
