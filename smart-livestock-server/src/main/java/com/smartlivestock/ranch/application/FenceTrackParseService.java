package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.FenceTrackParseResultDto;
import com.smartlivestock.ranch.application.dto.FenceTrackParseResultDto.TrackPointDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.ByteArrayInputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Stateless GPX track parser backing the fence "import GPX" flow (NIX-213).
 *
 * <p>The interaction mirrors the gps-quality track-lines parse contract
 * (statistics + preview points), but there is deliberately no import step:
 * the client runs its own envelope pipeline on {@code trackPoints} and the
 * resulting fence is saved through the regular POST /fences path, keeping
 * quota checks and optimistic locking in one place.</p>
 *
 * <p>Cleaning follows the same rules as track-lines (drop invalid coordinates,
 * merge consecutive duplicates, hard point cap). Points beyond
 * {@link #MAX_TRANSPORT_POINTS} are uniformly decimated for transport only —
 * the client envelope works at ≥25 m boundary scale, so 2 m-level sampling
 * density has ample headroom.</p>
 */
@Service
public class FenceTrackParseService {

    static final int MAX_POINTS = 20000;
    static final int MAX_TRANSPORT_POINTS = 5000;
    private static final int PREVIEW_POINT_COUNT = 8;

    public FenceTrackParseResultDto parse(MultipartFile file) {
        String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "track.gpx";

        Document doc;
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            // XXE hardening: GPX is third-party data — never resolve externals.
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);
            factory.setNamespaceAware(true);
            doc = factory.newDocumentBuilder()
                    .parse(new InputSource(new ByteArrayInputStream(file.getBytes())));
        } catch (Exception e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.gpxParseFailed");
        }

        // <trkpt> (track) first, then <rtept> (route), in document order;
        // standalone <wpt> waypoints do not form a track and are ignored.
        List<double[]> raw = new ArrayList<>();
        raw.addAll(readCoordinates(doc.getElementsByTagNameNS("*", "trkpt")));
        raw.addAll(readCoordinates(doc.getElementsByTagNameNS("*", "rtept")));
        int rawCount = raw.size();
        if (rawCount > MAX_POINTS) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.gpxTooManyPoints");
        }

        List<double[]> points = new ArrayList<>(rawCount);
        int invalid = 0;
        int removed = 0;
        for (double[] p : raw) {
            if (!isValid(p)) {
                invalid++;
                continue;
            }
            if (!points.isEmpty()) {
                double[] prev = points.get(points.size() - 1);
                if (prev[0] == p[0] && prev[1] == p[1]) {
                    removed++;
                    continue;
                }
            }
            points.add(p);
        }
        if (points.size() < 2) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.gpxNoTrack");
        }

        String defaultName = firstName(doc);
        if (defaultName == null || defaultName.isBlank()) {
            defaultName = fileName.replaceAll("(?i)\\.(gpx|xml)$", "");
        }

        String metadataWarning = metadataWarning(doc);

        double lengthMeters = polylineLengthMeters(points);
        double[] first = points.get(0);
        double[] last = points.get(points.size() - 1);

        List<double[]> transport = decimateForTransport(points);
        List<TrackPointDto> trackPoints = new ArrayList<>(transport.size());
        for (int i = 0; i < transport.size(); i++) {
            double[] p = transport.get(i);
            trackPoints.add(new TrackPointDto(i + 1, p[0], p[1]));
        }
        int previewLimit = Math.min(PREVIEW_POINT_COUNT, trackPoints.size());

        return new FenceTrackParseResultDto(
                defaultName,
                rawCount,
                points.size(),
                removed,
                invalid,
                lengthMeters,
                first[0], first[1],
                last[0], last[1],
                metadataWarning,
                trackPoints.subList(0, previewLimit),
                trackPoints);
    }

    private static List<double[]> readCoordinates(NodeList nodes) {
        List<double[]> result = new ArrayList<>(nodes.getLength());
        for (int i = 0; i < nodes.getLength(); i++) {
            var node = nodes.item(i);
            var latAttr = node.getAttributes().getNamedItem("lat");
            var lngAttr = node.getAttributes().getNamedItem("lon");
            if (latAttr == null || lngAttr == null) continue;
            try {
                result.add(new double[]{
                        Double.parseDouble(latAttr.getNodeValue().trim()),
                        Double.parseDouble(lngAttr.getNodeValue().trim()),
                });
            } catch (NumberFormatException e) {
                // Treated as an invalid point by the cleaning pass.
                result.add(new double[]{Double.NaN, Double.NaN});
            }
        }
        return result;
    }

    private static boolean isValid(double[] p) {
        return !Double.isNaN(p[0]) && !Double.isNaN(p[1])
                && p[0] >= -90 && p[0] <= 90 && p[1] >= -180 && p[1] <= 180;
    }

    private static String firstName(Document doc) {
        NodeList names = doc.getElementsByTagNameNS("*", "name");
        for (int i = 0; i < names.getLength(); i++) {
            String text = names.item(i).getTextContent();
            if (text != null && !text.isBlank()) return text.trim();
        }
        return null;
    }

    private static String metadataWarning(Document doc) {
        int segments = doc.getElementsByTagNameNS("*", "trkseg").getLength();
        if (segments > 1) {
            return "文件包含 " + segments + " 个轨迹段，已合并处理";
        }
        return null;
    }

    private static double polylineLengthMeters(List<double[]> points) {
        double total = 0;
        for (int i = 1; i < points.size(); i++) {
            total += haversineMeters(points.get(i - 1), points.get(i));
        }
        return Math.round(total * 10) / 10.0;
    }

    private static double haversineMeters(double[] a, double[] b) {
        double radLatA = Math.toRadians(a[0]);
        double radLatB = Math.toRadians(b[0]);
        double dLat = radLatB - radLatA;
        double dLng = Math.toRadians(b[1] - a[1]);
        double h = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(radLatA) * Math.cos(radLatB) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return 2 * 6371000 * Math.asin(Math.min(1, Math.sqrt(h)));
    }

    /** Uniform stride decimation that always keeps the final point. */
    private static List<double[]> decimateForTransport(List<double[]> points) {
        if (points.size() <= MAX_TRANSPORT_POINTS) return points;
        int stride = (int) Math.ceil(points.size() / (double) MAX_TRANSPORT_POINTS);
        List<double[]> out = new ArrayList<>(points.size() / stride + 1);
        for (int i = 0; i < points.size(); i += stride) {
            out.add(points.get(i));
        }
        double[] last = points.get(points.size() - 1);
        if (out.get(out.size() - 1) != last) {
            out.add(last);
        }
        return out;
    }
}
