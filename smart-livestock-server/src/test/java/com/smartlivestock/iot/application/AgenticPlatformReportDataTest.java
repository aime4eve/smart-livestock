package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.ReportRecordPageResp;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AgenticPlatformReportDataTest {

    @Test
    void toReadings_capsule_decodesRawRumenTlvFrameAndMergesMetadata() {
        ReportRecordPageResp.ReportRecord record = new ReportRecordPageResp.ReportRecord();
        record.setHexData(
                "68 6B 74 00 32 01 10 07 4D 00 8B 0B DA 49 00 00 3F 10 4A DE 4B 02 4C 40 86 00 F0");
        record.setRssi(-89);

        Map<String, Object> readings = AgenticPlatformReportData.toReadings(record, DeviceType.CAPSULE);

        assertEquals(3034, readings.get("batteryVoltage"));
        assertEquals(89, readings.get("battery"));
        assertEquals(16144L, readings.get("gastricMotility"));
        assertEquals(-89, readings.get("rssi"));
    }
}
