package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.FenceTrackParseResultDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit coverage for the fence GPX track parser (NIX-213): cleaning counters,
 * multi-segment merge, namespace tolerance, caps, and XXE rejection.
 */
class FenceTrackParseServiceTest {

    private final FenceTrackParseService service = new FenceTrackParseService();

    private MockMultipartFile gpx(String content) {
        return new MockMultipartFile("file", "北围栏.gpx", "application/gpx+xml",
                content.getBytes(StandardCharsets.UTF_8));
    }

    private static String trkpt(double lat, double lng) {
        return "<trkpt lat=\"" + lat + "\" lon=\"" + lng + "\"/>";
    }

    @Test
    void parsesTrackWithCleaningCountersAndDefaults() {
        var xml = "<?xml version=\"1.0\"?><gpx version=\"1.1\"><trk><name>测试轨迹</name><trkseg>"
                + trkpt(28.20, 112.90)
                + trkpt(28.20, 112.90) // consecutive duplicate → removed
                + trkpt(28.21, 112.90)
                + trkpt(28.22, 112.90)
                + trkpt(200, 112.90) // invalid latitude → invalid
                + "</trkseg></trk></gpx>";

        var dto = service.parse(gpx(xml));

        assertThat(dto.defaultName()).isEqualTo("测试轨迹");
        assertThat(dto.rawPointCount()).isEqualTo(5);
        assertThat(dto.pointCount()).isEqualTo(3);
        assertThat(dto.removedDuplicates()).isEqualTo(1);
        assertThat(dto.invalidPoints()).isEqualTo(1);
        assertThat(dto.lengthMeters()).isPositive();
        assertThat(dto.startLat()).isEqualTo(28.20);
        assertThat(dto.endLat()).isEqualTo(28.22);
        assertThat(dto.trackPoints()).hasSize(3);
        assertThat(dto.previewPoints()).hasSize(3);
        assertThat(dto.previewPoints().get(0).sequenceNo()).isEqualTo(1);
        assertThat(dto.metadataWarning()).isNull();
    }

    @Test
    void fallsBackToFileNameWhenNoNameElement() {
        var xml = "<?xml version=\"1.0\"?><gpx><trk><trkseg>"
                + trkpt(28.20, 112.90) + trkpt(28.21, 112.90)
                + "</trkseg></trk></gpx>";

        var dto = service.parse(gpx(xml));

        assertThat(dto.defaultName()).isEqualTo("北围栏");
    }

    @Test
    void mergesMultipleSegmentsWithWarning() {
        var xml = "<?xml version=\"1.0\"?><gpx><trk>"
                + "<trkseg>" + trkpt(28.20, 112.90) + trkpt(28.21, 112.90) + "</trkseg>"
                + "<trkseg>" + trkpt(28.22, 112.91) + trkpt(28.23, 112.92) + "</trkseg>"
                + "</trk></gpx>";

        var dto = service.parse(gpx(xml));

        assertThat(dto.pointCount()).isEqualTo(4);
        assertThat(dto.metadataWarning()).contains("轨迹段");
    }

    @Test
    void parsesNamespacedGpx() {
        var xml = "<?xml version=\"1.0\"?>"
                + "<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" version=\"1.1\">"
                + "<trk><trkseg><trkpt lat=\"28.20\" lon=\"112.90\"/><trkpt lat=\"28.21\" lon=\"112.90\"/>"
                + "</trkseg></trk></gpx>";

        var dto = service.parse(gpx(xml));

        assertThat(dto.pointCount()).isEqualTo(2);
    }

    @Test
    void parsesRoutePoints() {
        var xml = "<?xml version=\"1.0\"?><gpx><rte>"
                + "<rtept lat=\"28.20\" lon=\"112.90\"/><rtept lat=\"28.21\" lon=\"112.90\"/>"
                + "</rte></gpx>";

        var dto = service.parse(gpx(xml));

        assertThat(dto.pointCount()).isEqualTo(2);
    }

    @Test
    void rejectsWaypointsOnlyFile() {
        var xml = "<?xml version=\"1.0\"?><gpx><wpt lat=\"28.20\" lon=\"112.90\"/></gpx>";

        assertThatThrownBy(() -> service.parse(gpx(xml)))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).isEqualTo("error.gpxNoTrack");
                });
    }

    @Test
    void rejectsOversizedTrack() {
        StringBuilder sb = new StringBuilder("<?xml version=\"1.0\"?><gpx><trk><trkseg>");
        for (int i = 0; i <= FenceTrackParseService.MAX_POINTS; i++) {
            sb.append(trkpt(28.0 + i * 1e-7, 112.9));
        }
        sb.append("</trkseg></trk></gpx>");

        assertThatThrownBy(() -> service.parse(gpx(sb.toString())))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).isEqualTo("error.gpxTooManyPoints");
                });
    }

    @Test
    void rejectsMalformedXml() {
        assertThatThrownBy(() -> service.parse(gpx("<gpx><trk><trkseg>")))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).isEqualTo("error.gpxParseFailed");
                });
    }

    @Test
    void rejectsXxePayload() {
        var xml = "<?xml version=\"1.0\"?>"
                + "<!DOCTYPE gpx [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]>"
                + "<gpx><trk><trkseg><trkpt lat=\"&xxe;\" lon=\"112.90\"/></trkseg></trk></gpx>";

        assertThatThrownBy(() -> service.parse(gpx(xml)))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).isEqualTo("error.gpxParseFailed");
                });
    }

    @Test
    void decimatesTrackPointsForTransport() {
        StringBuilder sb = new StringBuilder("<?xml version=\"1.0\"?><gpx><trk><trkseg>");
        for (int i = 0; i < 6001; i++) {
            sb.append(trkpt(28.20, 112.90 + i * 1e-6));
        }
        sb.append("</trkseg></trk></gpx>");

        var dto = service.parse(gpx(sb.toString()));

        // pointCount keeps the cleaned size; transport payload is capped with
        // the final point preserved.
        assertThat(dto.pointCount()).isEqualTo(6001);
        assertThat(dto.trackPoints().size()).isLessThanOrEqualTo(FenceTrackParseService.MAX_TRANSPORT_POINTS);
        assertThat(dto.trackPoints().size()).isGreaterThanOrEqualTo(2500);
        var last = dto.trackPoints().get(dto.trackPoints().size() - 1);
        assertThat(last.lat()).isEqualTo(28.20);
        assertThat(last.lng()).isEqualTo(112.90 + 6000 * 1e-6);
        assertThat(dto.previewPoints()).hasSize(8);
    }

    // ── RTK 手簿 XLSX（轨迹检验线路版式，NIX-213 增补）──────────────

    private MockMultipartFile xlsx(String fileName, String coordinates,
                                   String aName, int extraRows) {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Sheet1");
            Row header = sheet.createRow(0);
            for (int c = 0; c < 8; c++) {
                header.createCell(c).setCellValue(c == 7 ? "坐标" : "col" + c);
            }
            Row data = sheet.createRow(1);
            data.createCell(0).setCellValue(aName);
            data.createCell(7).setCellValue(coordinates);
            for (int r = 0; r < extraRows; r++) {
                Row extra = sheet.createRow(2 + r);
                extra.createCell(0).setCellValue("另一条线路");
                extra.createCell(7).setCellValue("112.0,28.0,0");
            }
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            wb.write(out);
            return new MockMultipartFile("file", fileName,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    out.toByteArray());
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Test
    void parsesRtkXlsxTrackWithCleaningCounters() {
        var coords = "112.850487,28.245404,0\n"
                + "112.850487,28.245404,0\n" // consecutive duplicate → removed
                + "112.850486,28.245400,0\n"
                + "999,28.24,0\n" // invalid lng → invalid
                + "112.850488,28.245397,0";

        var dto = service.parse(xlsx("轨迹检验线路4.xlsx", coords, "自动追踪_20260729140734", 0));

        assertThat(dto.defaultName()).isEqualTo("自动追踪_20260729140734");
        assertThat(dto.rawPointCount()).isEqualTo(5);
        assertThat(dto.invalidPoints()).isEqualTo(1);
        assertThat(dto.removedDuplicates()).isEqualTo(1);
        assertThat(dto.pointCount()).isEqualTo(3);
        assertThat(dto.lengthMeters()).isPositive();
        assertThat(dto.startLng()).isEqualTo(112.850487);
        assertThat(dto.metadataWarning()).isNull();
    }

    @Test
    void xlsxMultipleDataRowsWarnsAndTakesFirst() {
        var dto = service.parse(xlsx("线路.xlsx",
                "112.850487,28.245404,0\n112.850486,28.245400,0", "第一条", 2));

        assertThat(dto.pointCount()).isEqualTo(2);
        assertThat(dto.metadataWarning()).contains("多条线路");
    }

    @Test
    void xlsxWithoutCoordinatesRejected() {
        assertThatThrownBy(() -> service.parse(xlsx("空.xlsx", "   ", "无坐标", 0)))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).isEqualTo("error.trackNoPoints");
                });
    }

    @Test
    void xlsxCorruptFileRejected() {
        var file = new MockMultipartFile("file", "bad.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "this is not a zip archive".getBytes(StandardCharsets.UTF_8));

        assertThatThrownBy(() -> service.parse(file))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).isEqualTo("error.trackFileParseFailed");
                });
    }
}
