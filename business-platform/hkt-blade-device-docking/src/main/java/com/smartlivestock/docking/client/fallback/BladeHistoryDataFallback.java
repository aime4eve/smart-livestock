package com.smartlivestock.docking.client.fallback;

import com.smartlivestock.docking.client.BladeHistoryDataClient;
import com.smartlivestock.docking.client.InternalResponse;
import com.smartlivestock.docking.dto.ReportRecordPageResp;
import com.smartlivestock.docking.dto.TelemetryQueryReq;
import com.smartlivestock.docking.dto.TelemetryResp;
import com.smartlivestock.docking.service.BladeServiceException;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class BladeHistoryDataFallback implements FallbackFactory<BladeHistoryDataClient> {

    @Override
    public BladeHistoryDataClient create(Throwable cause) {
        return new BladeHistoryDataClient() {
            @Override
            public InternalResponse<List<TelemetryResp>> queryLatest(TelemetryQueryReq request) {
                throw new BladeServiceException("Telemetry service unavailable", cause);
            }
            @Override
            public InternalResponse<List<TelemetryResp>> queryHistory(TelemetryQueryReq request) {
                throw new BladeServiceException("Telemetry service unavailable", cause);
            }
            @Override
            public InternalResponse<ReportRecordPageResp> queryReportRecords(
                    String deviceId, Integer current, Integer size) {
                throw new BladeServiceException("Report record service unavailable", cause);
            }
        };
    }
}
