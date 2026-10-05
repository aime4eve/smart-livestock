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

    /**
     * Every active capsule binding across all farms — the nightly drinking
     * batch universe (NIX-256 Task 4). Callers reverse-map livestock → farm
     * via {@code RanchQueryPort}.
     */
    List<CapsuleBinding> findAllActiveCapsuleBindings();

    /** The livestock's currently installed in-body capsule, if any. */
    Optional<CapsuleBinding> findActiveCapsuleBinding(Long livestockId);

    /** Reverse lookup: the livestock a device is currently installed on. */
    Optional<CapsuleBinding> findActiveCapsuleBindingByDeviceId(Long deviceId);

    /**
     * Whether the device id exists at all (any type/status). Admin manual
     * recalculation accepts removed capsules too — their history still
     * recalculates against the old owner (F6) — so existence, not binding,
     * is the validation.
     */
    boolean deviceExists(Long deviceId);
}
