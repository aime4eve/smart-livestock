package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.commerce.application.service.PlatformDisplaySettingsService;
import com.smartlivestock.commerce.domain.model.LockedTilePolicy;
import com.smartlivestock.ranch.domain.port.LockedTilePolicyPort;
import org.springframework.stereotype.Component;

/**
 * ACL implementation bridging the Ranch overview (NIX-389) to the commerce
 * platform-display settings. Named bean like the other cross-context ACLs to
 * avoid duplicate simple-name conflicts.
 */
@Component("commerceLockedTilePolicyPort")
public class LockedTilePolicyPortImpl implements LockedTilePolicyPort {

    private final PlatformDisplaySettingsService settingsService;

    public LockedTilePolicyPortImpl(PlatformDisplaySettingsService settingsService) {
        this.settingsService = settingsService;
    }

    @Override
    public String getLockedTilePolicy() {
        LockedTilePolicy policy = settingsService.getLockedTilePolicy();
        return policy == null ? LockedTilePolicy.SHOW_LOCKED.name() : policy.name();
    }
}
