package com.smartlivestock.ranch.domain.port;

/**
 * ACL command port for Ranch context to operate IoT context data.
 * Defined in Ranch (the calling context) per DDD anti-corruption layer convention.
 */
public interface IoTCommandPort {
    /**
     * Remove all active installations for a livestock.
     * Used during livestock deletion cascade.
     */
    void removeAllActiveInstallations(Long livestockId);
}
