package com.smartlivestock.licensing.infrastructure;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.canonicalVectorFile;
import static com.smartlivestock.licensing.testsupport.LicenseTestSupport.serializer;
import static org.assertj.core.api.Assertions.assertThat;

/**
 * Canonical JSON rules are pinned by the shared issuer/verifier test vectors in
 * {@code license-issuer/test-vectors/canonical-json-v1.json}; both implementations
 * must reproduce the expected bytes exactly.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class CanonicalJsonSerializerTest {

    private static final ObjectMapper JSON = new ObjectMapper();

    private List<Case> vectorCases;

    @BeforeAll
    void loadSharedVectors() throws Exception {
        Path vectorFile = canonicalVectorFile();
        JsonNode root = JSON.readTree(Files.readAllBytes(vectorFile));
        assertThat(root.get("name").asText()).isEqualTo("canonical-json-v1");
        vectorCases = new ArrayList<>();
        for (JsonNode caseNode : root.get("cases")) {
            Case c = new Case();
            c.name = caseNode.get("name").asText();
            c.expectedCanonical = caseNode.get("expectedCanonical").asText();
            c.input = JSON.convertValue(caseNode.get("input"), Map.class);
            c.instantKeys = new ArrayList<>();
            caseNode.get("instantKeys").forEach(k -> c.instantKeys.add(k.asText()));
            vectorCases.add(c);
        }
        assertThat(vectorCases).hasSize(3);
    }

    @Test
    @DisplayName("shared vectors: Java canonical form matches expectedCanonical")
    void sharedVectorsAreReproduced() {
        for (Case c : vectorCases) {
            Map<String, Object> input = new LinkedHashMap<>(c.input);
            for (String instantKey : c.instantKeys) {
                Object raw = input.get(instantKey);
                assertThat(raw).isInstanceOf(String.class);
                input.put(instantKey, Instant.parse((String) raw));
            }
            byte[] canonicalBytes = serializer().serialize(input);
            String canonical = new String(canonicalBytes, java.nio.charset.StandardCharsets.UTF_8);
            assertThat(canonical)
                    .as("vector case '%s'", c.name)
                    .isEqualTo(c.expectedCanonical);
        }
    }

    @Test
    @DisplayName("keys sorted lexicographically at every level")
    void sortsNestedKeys() {
        Map<String, Object> nested = new LinkedHashMap<>();
        nested.put("zz", 1);
        Map<String, Object> inner = new LinkedHashMap<>();
        inner.put("b", 2);
        inner.put("a", 3);
        nested.put("mm", inner);

        String canonical = new String(serializer().serialize(nested),
                java.nio.charset.StandardCharsets.UTF_8);

        assertThat(canonical).isEqualTo("{\"mm\":{\"a\":3,\"b\":2},\"zz\":1}");
    }

    @Test
    @DisplayName("instants rendered as UTC seconds form; integral doubles lose the decimal point")
    void formatsInstantsAndIntegers() {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("issuedAt", Instant.parse("2026-08-31T12:34:56Z"));
        payload.put("count", 5.0);
        payload.put("big", 9007199254740993L);

        String canonical = new String(serializer().serialize(payload),
                java.nio.charset.StandardCharsets.UTF_8);

        assertThat(canonical).isEqualTo(
                "{\"big\":9007199254740993,\"count\":5,\"issuedAt\":\"2026-08-31T12:34:56Z\"}");
    }

    @Test
    @DisplayName("strings escape mandatory JSON characters, non-ASCII stays raw")
    void escapesStrings() {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("s", "a\"b\\c\nd\te 智慧畜牧");

        String canonical = new String(serializer().serialize(payload),
                java.nio.charset.StandardCharsets.UTF_8);

        assertThat(canonical).isEqualTo("{\"s\":\"a\\\"b\\\\c\\nd\\te 智慧畜牧\"}");
    }

    @Test
    @DisplayName("serialize/parse round trip preserves structure")
    void roundTripsThroughParse() {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("payloadVersion", 1);
        payload.put("name", "许可证");
        payload.put("nested", Map.of("y", 2, "x", 1));
        payload.put("flags", List.of(true, false));

        byte[] bytes = serializer().serialize(payload);
        Map<String, Object> parsed = serializer().parse(bytes);

        assertThat(parsed).containsEntry("payloadVersion", 1).containsEntry("name", "许可证");
        assertThat((Map<String, Object>) parsed.get("nested"))
                .containsEntry("x", 1).containsEntry("y", 2);
        assertThat((List<Object>) parsed.get("flags")).containsExactly(true, false);
    }

    private static final class Case {
        String name;
        Map<String, Object> input;
        List<String> instantKeys;
        String expectedCanonical;
    }
}
