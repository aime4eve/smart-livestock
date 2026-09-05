package com.smartlivestock.licensing.infrastructure;

import com.smartlivestock.licensing.domain.HostFingerprint;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/**
 * Reads the host identity source (default {@code /etc/machine-id}; mounted
 * read-only into the app container in release deployments) and returns its
 * SHA-256 hex digest as a {@link HostFingerprint}.
 * <p>
 * The raw value is stripped of surrounding whitespace before hashing so a
 * trailing newline does not alter the fingerprint. A missing or blank source
 * file fails fast: enrollment must never silently produce a placeholder
 * fingerprint that licenses would then bind to.
 */
public class HostFingerprintReader {

    private final Path sourceFile;

    public HostFingerprintReader(Path sourceFile) {
        this.sourceFile = sourceFile;
    }

    /** Configured source path (for diagnostics and enrollment responses). */
    public Path getSourceFile() {
        return sourceFile;
    }

    /**
     * Read the host identifier and hash it.
     *
     * @return fingerprint of the stripped host identifier
     * @throws IllegalStateException when the source file is missing, unreadable
     *                               or blank (fail fast)
     */
    public HostFingerprint read() {
        if (!Files.isRegularFile(sourceFile)) {
            throw new IllegalStateException(
                    "host fingerprint source file not found: " + sourceFile
                            + " (mount the host machine-id into the container for ONPREM mode)");
        }
        String raw;
        try {
            raw = Files.readString(sourceFile).strip();
        } catch (IOException e) {
            throw new IllegalStateException(
                    "host fingerprint source file cannot be read: " + sourceFile + ": " + e.getMessage(), e);
        }
        if (raw.isEmpty()) {
            throw new IllegalStateException(
                    "host fingerprint source file is blank: " + sourceFile);
        }
        return HostFingerprint.of(sha256Hex(raw));
    }

    private static String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(
                    digest.digest(value.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            // JRE guarantee: SHA-256 is always available.
            throw new IllegalStateException("SHA-256 algorithm unavailable", e);
        }
    }
}
