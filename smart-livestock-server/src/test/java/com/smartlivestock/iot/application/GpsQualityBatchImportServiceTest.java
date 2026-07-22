package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.iot.interfaces.admin.dto.BatchParseResultDto;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.ByteArrayOutputStream;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * Datetime parsing coverage for the batch import startedAt/endedAt columns:
 * multiple text formats plus Excel date-formatted numeric cells.
 * Valid rows land on WARN because the mocked device lookup stays empty;
 * ERROR is reserved for unparseable values.
 */
@ExtendWith(MockitoExtension.class)
class GpsQualityBatchImportServiceTest {

    @Mock private GpsQualityTestRepository testRepository;
    @Mock private DeviceApplicationService deviceApplicationService;
    @Mock private DeviceRepository deviceRepository;
    @Mock private RtkReferencePointRepository rtkPointRepository;
    @Mock private DynamicTestRouteRepository routeRepository;

    @InjectMocks
    private GpsQualityBatchImportService service;

    @BeforeEach
    void setUp() {
        RtkReferencePoint point = new RtkReferencePoint();
        point.setId(11L);
        point.setPointLabel("11号点");
        when(rtkPointRepository.findAll()).thenReturn(List.of(point));
        when(routeRepository.findAll()).thenReturn(List.of());
        lenient().when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(anyString(), anyLong()))
                .thenReturn(List.of());
    }

    @Test
    void supportsDashFormatWithoutSeconds() throws Exception {
        BatchParseResultDto result = service.parseExcel(excelWith(
                new Object[][]{row("2026-07-18 09:00")}), 1L);

        assertThat(result.getErrorCount()).isZero();
        assertThat(result.getRows().get(0).preStatus()).isEqualTo("WARN");
        assertThat(result.getRows().get(0).startedAt())
                .isEqualTo(Instant.parse("2026-07-18T01:00:00Z"));
    }

    @Test
    void supportsSlashFormatsWithAndWithoutSeconds() throws Exception {
        BatchParseResultDto result = service.parseExcel(excelWith(new Object[][]{
                row("2026/07/18 09:00"),
                row("2026/07/18 09:00:30"),
        }), 1L);

        assertThat(result.getErrorCount()).isZero();
        assertThat(result.getRows().get(0).startedAt())
                .isEqualTo(Instant.parse("2026-07-18T01:00:00Z"));
        assertThat(result.getRows().get(1).startedAt())
                .isEqualTo(Instant.parse("2026-07-18T01:00:30Z"));
    }

    @Test
    void supportsUnpaddedMonthDayHour() throws Exception {
        BatchParseResultDto result = service.parseExcel(excelWith(new Object[][]{
                row("2026/7/8 9:05"),
                row("2026-7-8 9:05"),
        }), 1L);

        assertThat(result.getErrorCount()).isZero();
        assertThat(result.getRows().get(0).startedAt())
                .isEqualTo(Instant.parse("2026-07-08T01:05:00Z"));
        assertThat(result.getRows().get(1).startedAt())
                .isEqualTo(Instant.parse("2026-07-08T01:05:00Z"));
    }

    @Test
    void supportsExcelDateFormattedNumericCell() throws Exception {
        BatchParseResultDto result = service.parseExcel(excelWith(new Object[][]{
                new Object[]{"A84041CEFE380733", "GPS-001", "静态", "11号点",
                        LocalDateTime.of(2026, 7, 18, 9, 0),
                        LocalDateTime.of(2026, 7, 18, 11, 30)},
        }), 1L);

        assertThat(result.getErrorCount()).isZero();
        assertThat(result.getRows().get(0).preStatus()).isEqualTo("WARN");
        assertThat(result.getRows().get(0).startedAt())
                .isEqualTo(Instant.parse("2026-07-18T01:00:00Z"));
        assertThat(result.getRows().get(0).endedAt())
                .isEqualTo(Instant.parse("2026-07-18T03:30:00Z"));
    }

    @Test
    void keepsSupportingFullAndIsoFormats() throws Exception {
        BatchParseResultDto result = service.parseExcel(excelWith(new Object[][]{
                row("2026-07-18 09:00:00"),
                row("2026-07-18T01:00:00Z"),
        }), 1L);

        assertThat(result.getErrorCount()).isZero();
        assertThat(result.getRows().get(0).startedAt())
                .isEqualTo(Instant.parse("2026-07-18T01:00:00Z"));
        assertThat(result.getRows().get(1).startedAt())
                .isEqualTo(Instant.parse("2026-07-18T01:00:00Z"));
    }

    @Test
    void invalidFormatReportsErrorRow() throws Exception {
        BatchParseResultDto result = service.parseExcel(excelWith(new Object[][]{
                row("18/07/2026 09:00"),
        }), 1L);

        assertThat(result.getErrorCount()).isEqualTo(1);
        assertThat(result.getRows().get(0).preStatus()).isEqualTo("ERROR");
        assertThat(result.getRows().get(0).message()).contains("Invalid datetime format");
    }

    // --- helpers ---

    private Object[] row(String startedAt) {
        return new Object[]{"A84041CEFE380733", "GPS-001", "静态", "11号点", startedAt, null};
    }

    /** Builds a real .xlsx upload; LocalDateTime values become date-formatted numeric cells. */
    private MockMultipartFile excelWith(Object[][] rows) throws Exception {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet();
            Row header = sheet.createRow(0);
            String[] headers = {"EUI", "设备编号(可选)", "检验类型(静态/动态)", "真值参考", "开始时间", "结束时间(可选)"};
            for (int i = 0; i < headers.length; i++) {
                header.createCell(i).setCellValue(headers[i]);
            }
            CellStyle dateStyle = wb.createCellStyle();
            dateStyle.setDataFormat(wb.createDataFormat().getFormat("yyyy-mm-dd h:mm"));
            for (int i = 0; i < rows.length; i++) {
                Row r = sheet.createRow(i + 1);
                for (int j = 0; j < rows[i].length; j++) {
                    Object v = rows[i][j];
                    if (v == null) continue;
                    if (v instanceof LocalDateTime ldt) {
                        var cell = r.createCell(j);
                        cell.setCellValue(ldt);
                        cell.setCellStyle(dateStyle);
                    } else {
                        r.createCell(j).setCellValue(v.toString());
                    }
                }
            }
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            wb.write(bos);
            return new MockMultipartFile("file", "import.xlsx",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    bos.toByteArray());
        }
    }
}
