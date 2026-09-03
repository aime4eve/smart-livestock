package com.smartlivestock.licensing.domain;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

import java.util.HexFormat;
import java.util.regex.Pattern;

/**
 * Value object holding a host fingerprint hash.
 * <p>
 * The fingerprint is the SHA-256 hex digest of the host identifier source
 * (e.g. {@code /etc/machine-id} on Linux). It binds an offline license to one
 * physical/virtual machine. Only lowercase 64-character hex form is accepted.
 */
public final class HostFingerprint {

    private static final Pattern SHA256_HEX = Pattern.compile("^[0-9a-f]{64}$");

    private final String value;

    private HostFingerprint(String value) {
        this.value = value;
    }

    /**
     * Create a fingerprint from a hex digest. Input is normalized to lowercase.
     *
     * @throws DomainException LICENSE_INVALID when the input is not a 64-char hex digest
     */
    public static HostFingerprint of(String hexDigest) {
        if (hexDigest == null) {
            throw new DomainException(ErrorCode.LICENSE_INVALID, "host fingerprint is required");
        }
        String normalized = hexDigest.strip().toLowerCase();
        if (!SHA256_HEX.matcher(normalized).matches()) {
            throw new DomainException(ErrorCode.LICENSE_INVALID,
                    "host fingerprint must be a 64-character sha256 hex digest: " + mask(normalized));
        }
        return new HostFingerprint(normalized);
    }

    /** Returns true when the given hex digest denotes the same fingerprint. */
    public boolean matches(String otherHexDigest) {
        if (otherHexDigest == null) {
            return false;
        }
        return value.equals(otherHexDigest.strip().toLowerCase());
    }

    /** Raw sha256 bytes of this fingerprint's hex form. */
    public byte[] toBytes() {
        return HexFormat.of().parseHex(value);
    }

    public String getValue() {
        return value;
    }

    private static String mask(String input) {
        return input.length() <= 12 ? input : input.substring(0, 12) + "...";
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof HostFingerprint other && value.equals(other.value);
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }

    @Override
    public String toString() {
        return "HostFingerprint[" + mask(value) + "]";
    }
}
