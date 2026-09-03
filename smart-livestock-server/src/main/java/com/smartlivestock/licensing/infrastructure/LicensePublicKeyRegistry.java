package com.smartlivestock.licensing.infrastructure;

import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;

import java.security.PublicKey;

/**
 * Trust anchor registry for offline license signature verification.
 * <p>
 * The on-premise trust root is the set of built-in issuer public keys (current
 * plus rotated). Keys are addressed by {@code keyId} carried in the license
 * envelope; an unknown keyId is a hard failure — the trust root can never be
 * extended at runtime through configuration.
 */
public interface LicensePublicKeyRegistry {

    /**
     * Resolve the Ed25519 public key for a keyId.
     *
     * @throws DomainException LICENSE_INVALID when the keyId is not trusted
     */
    PublicKey forKeyId(String keyId);

    /** True when the given keyId is present in the registry. */
    boolean supports(String keyId);
}
