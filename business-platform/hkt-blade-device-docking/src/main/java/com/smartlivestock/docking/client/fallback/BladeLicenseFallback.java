package com.smartlivestock.docking.client.fallback;

import com.smartlivestock.docking.client.BladeLicenseClient;
import com.smartlivestock.docking.client.InternalResponse;
import com.smartlivestock.docking.dto.LicenseStatusResp;
import com.smartlivestock.docking.service.BladeServiceException;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

@Component
public class BladeLicenseFallback implements FallbackFactory<BladeLicenseClient> {

    @Override
    public BladeLicenseClient create(Throwable cause) {
        return deviceSn -> {
            throw new BladeServiceException("License service unavailable", cause);
        };
    }
}
