package com.smartlivestock.health.domain.port;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * ACL port: Health → IoT. Resolves which in-body rumen capsules (active
 * CAPSULE installations) are bound to livestock — the device universe for
 * drinking detection and manual event back-fill.
 */
public interface DeviceQueryPort {

    /** Binding of one livestock to its currently installed capsule device. */
    record CapsuleBinding(Long livestockId, Long deviceId) {}

    /**
     * Active capsule bindings for the given livestock ids. Livestock without
     * an installed capsule are absent from the result.
     */
    List<CapsuleBinding> findActiveCapsuleBindings(Collection<Long> livestockIds);

    /** The livestock's currently installed in-body capsule, if any. */
    Optional<CapsuleBinding> findActiveCapsuleBinding(Long livestockId);

    /** Reverse lookup: the livestock a device is currently installed on. */
    Optional<CapsuleBinding> findActiveCapsuleBindingByDeviceId(Long deviceId);
}
