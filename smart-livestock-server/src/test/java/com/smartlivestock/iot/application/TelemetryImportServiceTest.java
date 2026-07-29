package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.port.IdentityQueryPort;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.FarmInfo;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.interfaces.admin.dto.TelemetryImportResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.TelemetryParseResultDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * TelemetryImportService tests (NIX-79): classification matrix, whole-file
 * device match errors, duplicate detection, microsecond times, idempotent replay.
 */
@ExtendWith(MockitoExtension.class)
class TelemetryImportServiceTest {

    private static final String EUI = "0095690600028577";
    private static final String FILE_NAME = EUI + "-历史数据.xlsx";

    /** Real periodic frame of device 0095690600028577 (fcnt=119): battery 99,
     *  28.246777/112.851138, 27 steps, accel (-921,-665,-1280). */
    private static final String REAL_FRAME =
            "68 6B 74 00 BC 01 04 04 03 63 10 01 AF 02 F9 11 06 B9 F8 C2 15 00 1B "
                    + "0B FC 67 0C FD 67 0D FB 00 39 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01";

    private static final String T1 = "2026-07-23 16:09:11.026000";
    private static final String T2 = "2026-07-23 16:08:04.221000";
    private static final String T3 = "2026-07-23 16:07:02.340000";
    private static final Instant T1_INSTANT = Instant.parse("2026-07-23T16:09:11.026Z");
    private static final Instant T2_INSTANT = Instant.parse("2026-07-23T16:08:04.221Z");
    private static final Instant T3_INSTANT = Instant.parse("2026-07-23T16:07:02.340Z");

    @Mock private DeviceRepository deviceRepository;
    @Mock private DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    @Mock private InstallationRepository installationRepository;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private IdentityQueryPort identityQueryPort;
    @Mock private TelemetryIngestionService telemetryIngestionService;

    private TelemetryImportService service;

    @BeforeEach
    void setUp() {
        service = new TelemetryImportService(
                deviceRepository, deviceTelemetryLogRepository, installationRepository,
                ranchQueryPort, identityQueryPort, telemetryIngestionService);
    }

    // ------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------

    private Device trackerDevice() {
        Device d = new Device();
        d.setId(7L);
        d.setTenantId(1L);
        d.setDeviceCode("TRACKER-001");
        d.setDeviceType(DeviceType.TRACKER);
        d.setStatus(DeviceStatus.ACTIVE);
        d.setDevEui(EUI);
        return d;
    }

    private void stubMatchedDevice(Device device) {
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(EUI, 1L))
                .thenReturn(List.of(device));
    }

    /** Build an xlsx: header row + one row per entry (A..F = type/fcnt/hex/rssi/snr/time). */
    private static MockMultipartFile xlsx(String filename, List<String[]> rows) throws IOException {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet();
            org.apache.poi.ss.usermodel.Row header = sheet.createRow(0);
            String[] headers = {"数据类型", "帧计数器", "数据", "RSSI", "SNR", "创建时间"};
            for (int c = 0; c < headers.length; c++) {
                header.createCell(c).setCellValue(headers[c]);
            }
            int r = 1;
            for (String[] row : rows) {
                org.apache.poi.ss.usermodel.Row excelRow = sheet.createRow(r++);
                for (int c = 0; c < row.length; c++) {
                    if (row[c] != null) excelRow.createCell(c).setCellValue(row[c]);
                }
            }
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            wb.write(bos);
            return new MockMultipartFile("file", filename,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    bos.toByteArray());
        }
    }

    private static String[] uplink(String fcnt, String hex, String rssi, String snr, String time) {
        return new String[]{"上行", fcnt, hex, rssi, snr, time};
    }

    private static TelemetryParseResultDto.Row rowOf(TelemetryParseResultDto dto, int rowNo) {
        return dto.rows().stream().filter(r -> r.rowNo() == rowNo).findFirst().orElseThrow();
    }

    // ------------------------------------------------------------------
    // Classification matrix
    // ------------------------------------------------------------------

    @Test
    void parse_classificationMatrix_coversAllStatuses() throws IOException {
        Device device = trackerDevice();
        stubMatchedDevice(device);
        when(installationRepository.findActiveByDeviceId(7L)).thenReturn(Optional.empty());
        when(deviceTelemetryLogRepository.findReportTimesByDeviceIdAndReportTimeBetween(
                eq(7L), any(), any())).thenReturn(List.of(T2_INSTANT));

        MockMultipartFile file = xlsx(FILE_NAME, List.of(
                new String[]{"下行", null, "68 6B 74 00 01 39", "-", "-", T1},          // row1 downlink
                uplink("118", "ZZ ZZ", "-90", "3", T1),                                // row2 bad hex
                uplink("117", REAL_FRAME, "-90", "3", "not-a-time"),                   // row3 bad time
                uplink("116", "61 00 01 00 04 06 00 00", "-90", "3", T1),              // row4 non sync head
                uplink("119", REAL_FRAME, "-99", "-9", T1),                            // row5 importable (+gps)
                uplink("119", REAL_FRAME, "-99", "-9", T1),                            // row6 in-file duplicate
                uplink("117", REAL_FRAME, "-91", "-1.5", T2),                          // row7 db duplicate
                uplink("115", REAL_FRAME, "-90", "3", T3)                              // row8 importable
        ));

        TelemetryParseResultDto dto = service.parse(file, 1L);

        assertEquals(8, dto.totalRows());
        assertEquals(7, dto.uplinkRows());
        assertEquals(4, dto.decodableRows());
        assertEquals(2, dto.importableRows());
        assertEquals(2, dto.gpsPointRows());
        assertEquals(2, dto.duplicateRows());
        assertEquals(2, dto.skippedRows());
        assertEquals(2, dto.invalidRows());

        // Row numbers match the spreadsheet (header = row 1, first data row = 2)
        assertEquals("SKIPPED_DOWNLINK", rowOf(dto, 2).status());
        assertEquals("INVALID", rowOf(dto, 3).status());
        assertEquals("error.telemetryImport.invalidHex", rowOf(dto, 3).error());
        assertEquals("INVALID", rowOf(dto, 4).status());
        assertEquals("error.telemetryImport.invalidTime", rowOf(dto, 4).error());
        assertEquals("SKIPPED_UNSUPPORTED", rowOf(dto, 5).status());
        assertEquals("IMPORTABLE", rowOf(dto, 6).status());
        assertEquals("DUPLICATE", rowOf(dto, 7).status());
        assertEquals("DUPLICATE", rowOf(dto, 8).status());
        assertEquals("IMPORTABLE", rowOf(dto, 9).status());

        // Decoded values surfaced in the preview row
        TelemetryParseResultDto.Row row6 = rowOf(dto, 6);
        assertEquals(99, row6.battery());
        assertEquals(new BigDecimal("28.246777"), row6.latitude());
        assertEquals(new BigDecimal("112.851138"), row6.longitude());
        assertEquals(27, row6.stepCount());
        assertEquals(T1_INSTANT, row6.recordTime());

        assertTrue(dto.device().matched());
        assertEquals(EUI, dto.device().devEui());
        assertEquals("TRACKER-001", dto.device().deviceCode());
        assertEquals("TRACKER", dto.device().deviceType());
        assertNull(dto.device().error());
    }

    @Test
    void parse_matchedDeviceWithInstallation_resolvesLivestockAndFarmNames() throws IOException {
        Device device = trackerDevice();
        stubMatchedDevice(device);
        Installation installation = new Installation(7L, 10L, 1L);
        when(installationRepository.findActiveByDeviceId(7L)).thenReturn(Optional.of(installation));
        when(ranchQueryPort.findLivestockById(10L))
                .thenReturn(Optional.of(new LivestockInfo(10L, 1L, "C001", "FEMALE", null, null)));
        when(identityQueryPort.findFarmById(1L))
                .thenReturn(Optional.of(new FarmInfo(1L, "Demo Farm", null, null)));
        when(deviceTelemetryLogRepository.findReportTimesByDeviceIdAndReportTimeBetween(
                eq(7L), any(), any())).thenReturn(List.of());

        MockMultipartFile file = xlsx(FILE_NAME, List.<String[]>of(uplink("119", REAL_FRAME, "-99", "-9", T1)));

        TelemetryParseResultDto dto = service.parse(file, 1L);

        assertTrue(dto.device().matched());
        assertEquals("C001", dto.device().livestockName());
        assertEquals("Demo Farm", dto.device().farmName());
    }

    // ------------------------------------------------------------------
    // Whole-file device match errors (D4)
    // ------------------------------------------------------------------

    @Test
    void parse_deviceNotRegistered_matchedFalseWithKey() throws IOException {
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(EUI, 1L))
                .thenReturn(List.of());

        MockMultipartFile file = xlsx(FILE_NAME, List.<String[]>of(uplink("119", REAL_FRAME, "-99", "-9", T1)));

        TelemetryParseResultDto dto = service.parse(file, 1L);

        assertFalse(dto.device().matched());
        assertEquals("error.telemetryImport.deviceNotRegistered", dto.device().error());
        assertNull(dto.device().deviceCode());
    }

    @Test
    void parse_deviceNotActive_matchedFalseWithKey() throws IOException {
        Device device = trackerDevice();
        device.setStatus(DeviceStatus.INVENTORY);
        stubMatchedDevice(device);

        MockMultipartFile file = xlsx(FILE_NAME, List.<String[]>of(uplink("119", REAL_FRAME, "-99", "-9", T1)));

        TelemetryParseResultDto dto = service.parse(file, 1L);

        assertFalse(dto.device().matched());
        assertEquals("error.telemetryImport.deviceNotActive", dto.device().error());
        assertEquals("TRACKER-001", dto.device().deviceCode());
    }

    @Test
    void parse_nonTrackerDevice_matchedFalseWithKey() throws IOException {
        Device device = trackerDevice();
        device.setDeviceType(DeviceType.CAPSULE);
        stubMatchedDevice(device);

        MockMultipartFile file = xlsx(FILE_NAME, List.<String[]>of(uplink("119", REAL_FRAME, "-99", "-9", T1)));

        TelemetryParseResultDto dto = service.parse(file, 1L);

        assertFalse(dto.device().matched());
        assertEquals("error.telemetryImport.unsupportedDeviceType", dto.device().error());
        assertEquals("CAPSULE", dto.device().deviceType());
    }

    @Test
    void import_deviceNotRegistered_throwsBeforeIngest() {
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(EUI, 1L))
                .thenReturn(List.of());

        MockMultipartFile file = new MockMultipartFile("file", FILE_NAME, null, new byte[0]);

        ApiException ex = assertThrows(ApiException.class, () -> service.importFile(file, 1L));
        assertEquals(ErrorCode.VALIDATION_ERROR, ex.getCode());
        assertEquals("error.telemetryImport.deviceNotRegistered", ex.getMessage());
        verifyNoInteractions(telemetryIngestionService);
    }

    @Test
    void parse_badFileName_throws() {
        MockMultipartFile file = new MockMultipartFile("file", "telemetry.xlsx", null, new byte[0]);

        ApiException ex = assertThrows(ApiException.class, () -> service.parse(file, 1L));
        assertEquals(ErrorCode.VALIDATION_ERROR, ex.getCode());
        assertEquals("error.telemetryImport.badFileName", ex.getMessage());
    }

    // ------------------------------------------------------------------
    // Time parsing (microseconds, no now() fallback)
    // ------------------------------------------------------------------

    @Test
    void parse_microsecondTime_parsedAtFaceValueUtc() throws IOException {
        Device device = trackerDevice();
        stubMatchedDevice(device);
        when(installationRepository.findActiveByDeviceId(7L)).thenReturn(Optional.empty());
        when(deviceTelemetryLogRepository.findReportTimesByDeviceIdAndReportTimeBetween(
                eq(7L), any(), any())).thenReturn(List.of());

        MockMultipartFile file = xlsx(FILE_NAME, List.<String[]>of(
                uplink("119", REAL_FRAME, "-99", "-9", "2026-07-27 20:16:47.828000")));

        TelemetryParseResultDto dto = service.parse(file, 1L);

        assertEquals(Instant.parse("2026-07-27T20:16:47.828Z"), rowOf(dto, 2).recordTime());
        assertEquals("IMPORTABLE", rowOf(dto, 2).status());
    }

    // ------------------------------------------------------------------
    // Import
    // ------------------------------------------------------------------

    @Test
    void import_success_ingestsImportableRowsAscendingWithManualImportSource() throws IOException {
        Device device = trackerDevice();
        stubMatchedDevice(device);
        when(deviceTelemetryLogRepository.findReportTimesByDeviceIdAndReportTimeBetween(
                eq(7L), any(), any())).thenReturn(List.of());

        // File order: later time first — import must reorder ascending
        MockMultipartFile file = xlsx(FILE_NAME, List.of(
                uplink("119", REAL_FRAME, "-99", "-9", T1),
                new String[]{"下行", null, "68 6B 74", "-", "-", T2},
                uplink("115", REAL_FRAME, "-90", "3", T3)
        ));

        TelemetryImportResultDto result = service.importFile(file, 1L);

        assertEquals(2, result.telemetryCreated());
        assertEquals(2, result.gpsCreated());
        assertEquals(0, result.duplicateSkipped());
        assertEquals(1, result.skippedRows());
        assertEquals(0, result.invalidRows());
        assertEquals(0, result.failedRows());
        assertEquals(EUI, result.devEui());
        assertEquals("TRACKER-001", result.deviceCode());

        ArgumentCaptor<Instant> timeCaptor = ArgumentCaptor.forClass(Instant.class);
        ArgumentCaptor<Map> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(telemetryIngestionService, times(2)).ingest(
                eq(7L), readingsCaptor.capture(), timeCaptor.capture(), eq(TelemetrySource.MANUAL_IMPORT));
        assertEquals(List.of(T3_INSTANT, T1_INSTANT), timeCaptor.getAllValues());

        Map<String, Object> readings = readingsCaptor.getAllValues().get(0);
        assertEquals(99, readings.get("battery"));
        assertEquals(27, readings.get("stepCount"));
        assertFalse(readings.containsKey("stepNumber"));
        assertEquals(-90, readings.get("rssi"));
        assertEquals(new BigDecimal("3"), readings.get("snr"));
        assertEquals("intense", readings.get("activityClass"));
    }

    @Test
    void import_idempotentReplay_allRowsDuplicate_nothingIngested() throws IOException {
        Device device = trackerDevice();
        stubMatchedDevice(device);
        when(deviceTelemetryLogRepository.findReportTimesByDeviceIdAndReportTimeBetween(
                eq(7L), any(), any())).thenReturn(List.of(T1_INSTANT, T3_INSTANT));

        MockMultipartFile file = xlsx(FILE_NAME, List.of(
                uplink("119", REAL_FRAME, "-99", "-9", T1),
                uplink("115", REAL_FRAME, "-90", "3", T3)
        ));

        TelemetryImportResultDto result = service.importFile(file, 1L);

        assertEquals(0, result.telemetryCreated());
        assertEquals(0, result.gpsCreated());
        assertEquals(2, result.duplicateSkipped());
        assertEquals(0, result.failedRows());
        verify(telemetryIngestionService, never()).ingest(any(), any(), any(), any());
    }

    @Test
    void import_singleRowFailure_countedAndContinues() throws IOException {
        Device device = trackerDevice();
        stubMatchedDevice(device);
        when(deviceTelemetryLogRepository.findReportTimesByDeviceIdAndReportTimeBetween(
                eq(7L), any(), any())).thenReturn(List.of());
        doThrow(new RuntimeException("db down"))
                .doNothing()
                .when(telemetryIngestionService)
                .ingest(eq(7L), any(), any(), eq(TelemetrySource.MANUAL_IMPORT));

        MockMultipartFile file = xlsx(FILE_NAME, List.of(
                uplink("119", REAL_FRAME, "-99", "-9", T1),
                uplink("115", REAL_FRAME, "-90", "3", T3)
        ));

        TelemetryImportResultDto result = service.importFile(file, 1L);

        assertEquals(1, result.telemetryCreated());
        assertEquals(1, result.failedRows());
        verify(telemetryIngestionService, times(2)).ingest(any(), any(), any(), any());
    }

    /**
     * Regression (dev integration finding): blade exports frame counter / RSSI
     * / SNR as NUMERIC cells, which arrive as "119.0" / "-99.0". Whole numbers
     * must render without the ".0" suffix so RSSI parses and counters display.
     */
    @Test
    void parse_numericCells_wholeNumbersRenderWithoutDecimalPoint() throws IOException {
        Device device = trackerDevice();
        stubMatchedDevice(device);
        when(installationRepository.findActiveByDeviceId(7L)).thenReturn(Optional.empty());
        when(deviceTelemetryLogRepository.findReportTimesByDeviceIdAndReportTimeBetween(
                eq(7L), any(), any())).thenReturn(List.of());

        MockMultipartFile file = numericXlsx(FILE_NAME);

        TelemetryParseResultDto dto = service.parse(file, 1L);

        TelemetryParseResultDto.Row row = rowOf(dto, 2);
        assertEquals("119", row.frameCounter());
        assertEquals("IMPORTABLE", row.status());

        service.importFile(numericXlsx(FILE_NAME), 1L);
        ArgumentCaptor<Map> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(telemetryIngestionService).ingest(eq(7L), readingsCaptor.capture(),
                any(), eq(TelemetrySource.MANUAL_IMPORT));
        Map<String, Object> readings = readingsCaptor.getValue();
        assertEquals(-99, readings.get("rssi"));
        assertEquals(new BigDecimal("-9"), readings.get("snr"));
    }

    /** xlsx whose fcnt/rssi/snr cells are NUMERIC (doubles), like the real blade export. */
    private static MockMultipartFile numericXlsx(String filename) throws IOException {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet();
            org.apache.poi.ss.usermodel.Row header = sheet.createRow(0);
            String[] headers = {"数据类型", "帧计数器", "数据", "RSSI", "SNR", "创建时间"};
            for (int c = 0; c < headers.length; c++) {
                header.createCell(c).setCellValue(headers[c]);
            }
            org.apache.poi.ss.usermodel.Row row = sheet.createRow(1);
            row.createCell(0).setCellValue("上行");
            row.createCell(1).setCellValue(119.0);
            row.createCell(2).setCellValue(REAL_FRAME);
            row.createCell(3).setCellValue(-99.0);
            row.createCell(4).setCellValue(-9.0);
            row.createCell(5).setCellValue(T1);
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            wb.write(bos);
            return new MockMultipartFile("file", filename,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    bos.toByteArray());
        }
    }
}
