package com.smartlivestock.iot.infrastructure.client.agenticplatform.client.fallback;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformHistoryDataClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformServiceException;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.ReportRecordPageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.TelemetryQueryReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.TelemetryResp;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class AgenticPlatformHistoryDataFallback implements FallbackFactory<AgenticPlatformHistoryDataClient> {

    @Override
    public AgenticPlatformHistoryDataClient create(Throwable cause) {
        return new AgenticPlatformHistoryDataClient() {
            @Override
            public InternalResponse<List<TelemetryResp>> queryLatest(TelemetryQueryReq request) {
                throw new AgenticPlatformServiceException("Telemetry service unavailable", cause);
            }
            @Override
            public InternalResponse<List<TelemetryResp>> queryHistory(TelemetryQueryReq request) {
                throw new AgenticPlatformServiceException("Telemetry service unavailable", cause);
            }
            @Override
            public InternalResponse<ReportRecordPageResp> queryReportRecords(
                    String deviceId, Integer current, Integer size) {
                throw new AgenticPlatformServiceException("Report record service unavailable", cause);
            }
        };
    }
}
