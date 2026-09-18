package com.smartlivestock.iot.infrastructure.client.devicehub;

import com.smartlivestock.iot.infrastructure.client.devicehub.dto.ReconcileReport;
import com.smartlivestock.iot.infrastructure.client.devicehub.dto.RegisterDeviceRequest;
import com.smartlivestock.iot.infrastructure.client.devicehub.dto.RegisterDeviceResult;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

/**
 * HKT-DeviceHub device provisioning REST (url mode, no Nacos — same pattern as
 * the agentic-platform clients). Endpoints mirror DeviceHub DeviceController:
 * register one device, batch import, reconcile TB inventory per project.
 */
@FeignClient(name = "devicehub", url = "${smartlivestock.devicehub.service-url}")
public interface DeviceHubClient {

    @PostMapping("/api/v1/devices/register")
    RegisterDeviceResult register(@RequestBody RegisterDeviceRequest request);

    @PostMapping("/api/v1/devices/import")
    List<RegisterDeviceResult> importBatch(@RequestBody List<RegisterDeviceRequest> requests);

    @GetMapping("/api/v1/devices/reconcile")
    ReconcileReport reconcile(@RequestParam("project") String project);
}
