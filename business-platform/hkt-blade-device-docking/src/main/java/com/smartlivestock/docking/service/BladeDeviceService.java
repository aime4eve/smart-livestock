package com.smartlivestock.docking.service;

import com.smartlivestock.docking.client.BladeDeviceServiceClient;
import com.smartlivestock.docking.client.BladeHistoryDataClient;
import com.smartlivestock.docking.client.BladeLicenseClient;
import com.smartlivestock.docking.client.InternalResponse;
import com.smartlivestock.docking.dto.DevicePageReq;
import com.smartlivestock.docking.dto.DevicePageResp;
import com.smartlivestock.docking.dto.DeviceRegistrationReq;
import com.smartlivestock.docking.dto.DeviceRegistrationResp;
import com.smartlivestock.docking.dto.DeviceTelemetryResp;
import com.smartlivestock.docking.dto.LicenseStatusResp;
import com.smartlivestock.docking.dto.LoginUser;
import com.smartlivestock.docking.dto.ReportRecordPageResp;
import com.smartlivestock.docking.dto.TelemetryQueryReq;
import com.smartlivestock.docking.dto.TelemetryResp;
import com.smartlivestock.docking.oauth.BladeOAuth2Properties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Orchestrates blade device + telemetry + history calls.
 * Verified against real blade at 172.22.4.17 on 2026-07-07.
 */
@Slf4j
@Service
public class BladeDeviceService {

    private final BladeLicenseClient licenseClient;
    private final BladeDeviceServiceClient deviceClient;
    private final BladeHistoryDataClient telemetryClient;
    private final BladeOAuth2Properties oauthProps;

    @Value("${blade.service-account.user-id:2074385063398711296}")
    private String serviceUserId;

    @Value("${blade.service-account.tenant-id:000000}")
    private String serviceTenantId;

    public BladeDeviceService(BladeLicenseClient licenseClient,
                              BladeDeviceServiceClient deviceClient,
                              BladeHistoryDataClient telemetryClient,
                              BladeOAuth2Properties oauthProps) {
        this.licenseClient = licenseClient;
        this.deviceClient = deviceClient;
        this.telemetryClient = telemetryClient;
        this.oauthProps = oauthProps;
    }

    public DevicePageResp listDevices(int page, int size) {
        DevicePageReq req = new DevicePageReq();
        req.setCurrent(page);
        req.setSize(size);
        InternalResponse<DevicePageResp> resp = deviceClient.pageDevices(req);
        if (!resp.isOk() || resp.getData() == null) {
            throw new BladeServiceException("pageDevices failed: " + resp.getMsg());
        }
        log.info("[PhaseC] pageDevices total={}", resp.getData().getTotal());
        return resp.getData();
    }

    public DeviceTelemetryResp getDeviceWithTelemetry(String deviceId) {
        InternalResponse<DeviceTelemetryResp> resp = deviceClient.getDeviceDetailWithTelemetry(deviceId);
        if (!resp.isOk() || resp.getData() == null) {
            throw new BladeServiceException("getDeviceDetailWithTelemetry failed: " + resp.getMsg());
        }
        return resp.getData();
    }

    public List<TelemetryResp> queryLatestTelemetry(List<String> deviceIds, String deviceTypeCode) {
        TelemetryQueryReq req = new TelemetryQueryReq();
        req.setDeviceIds(deviceIds);
        req.setDeviceTypeCode(deviceTypeCode);
        InternalResponse<List<TelemetryResp>> resp = telemetryClient.queryLatest(req);
        if (!resp.isOk() || resp.getData() == null) {
            throw new BladeServiceException("telemetry latest failed: " + resp.getMsg());
        }
        return resp.getData();
    }

    /**
     * Device uplink history records (primary time-series data source).
     * Each record contains hexData + decodeData with all reported properties.
     */
    public ReportRecordPageResp queryReportRecords(String deviceId, int page, int size) {
        InternalResponse<ReportRecordPageResp> resp = telemetryClient.queryReportRecords(deviceId, page, size);
        if (!resp.isOk() || resp.getData() == null) {
            throw new BladeServiceException("report-record query failed: " + resp.getMsg());
        }
        log.info("[PhaseC] report-records deviceId={}, total={}", deviceId, resp.getData().getTotal());
        return resp.getData();
    }

    public String registerDevice(String sn) {
        InternalResponse<LicenseStatusResp> licenseResp = licenseClient.getLicenseStatusBySn(sn);
        if (!licenseResp.isOk() || licenseResp.getData() == null) {
            throw new BladeServiceException("SN not found or license service error: "
                    + (licenseResp.getMsg() != null ? licenseResp.getMsg() : ""));
        }
        LicenseStatusResp license = licenseResp.getData();
        if (license.getIsValid() == null || !license.getIsValid()) {
            throw new BladeServiceException("SN not activated or invalid");
        }

        LoginUser loginUser = LoginUser.from(serviceUserId, serviceTenantId);
        DeviceRegistrationReq regReq = new DeviceRegistrationReq();
        regReq.setUser(loginUser);
        regReq.setDeviceIdentifier(license.getDeviceEui());
        regReq.setDeviceTypeCode(license.getDeviceTypeCode());

        InternalResponse<DeviceRegistrationResp> regResp = deviceClient.registerDevice(regReq);
        if (!regResp.isOk() || regResp.getData() == null) {
            throw new BladeServiceException("device registration failed: "
                    + (regResp.getMsg() != null ? regResp.getMsg() : ""));
        }

        log.info("[PhaseC] device registered on blade, sn={}, bladeDeviceId={}",
                sn, regResp.getData().getDeviceId());
        return regResp.getData().getDeviceId();
    }
}
