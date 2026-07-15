package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.iot.domain.service.DmsCoordinateConverter;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

/**
 * CRUD for RTK reference points. Accepts coordinates either as decimals
 * or DMS strings (converted via {@link DmsCoordinateConverter}).
 */
@Service
@RequiredArgsConstructor
public class RtkReferencePointService {

    private final RtkReferencePointRepository rtkPointRepository;

    public List<RtkReferencePoint> findAll(String locationName) {
        if (locationName != null && !locationName.isBlank()) {
            return rtkPointRepository.findByLocationName(locationName);
        }
        return rtkPointRepository.findAll();
    }

    public RtkReferencePoint findById(Long id) {
        return rtkPointRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + id));
    }

    public RtkReferencePoint create(String locationName, String pointLabel,
                                    BigDecimal latitude, BigDecimal longitude,
                                    String dmsLat, String dmsLng) {
        requireNonBlank(locationName, "locationName");
        requireNonBlank(pointLabel, "pointLabel");
        BigDecimal lat = resolveCoordinate(latitude, dmsLat);
        BigDecimal lng = resolveCoordinate(longitude, dmsLng);
        return rtkPointRepository.save(new RtkReferencePoint(locationName, pointLabel, lat, lng));
    }

    public RtkReferencePoint update(Long id, String locationName, String pointLabel,
                                    BigDecimal latitude, BigDecimal longitude,
                                    String dmsLat, String dmsLng) {
        RtkReferencePoint existing = findById(id);
        if (locationName != null) existing.setLocationName(locationName);
        if (pointLabel != null) existing.setPointLabel(pointLabel);
        if (latitude != null) existing.setLatitude(latitude);
        if (longitude != null) existing.setLongitude(longitude);
        if (dmsLat != null && !dmsLat.isBlank()) existing.setLatitude(DmsCoordinateConverter.parse(dmsLat));
        if (dmsLng != null && !dmsLng.isBlank()) existing.setLongitude(DmsCoordinateConverter.parse(dmsLng));
        return rtkPointRepository.save(existing);
    }

    public void delete(Long id) {
        if (!rtkPointRepository.existsById(id)) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "RTK point not found: " + id);
        }
        rtkPointRepository.deleteById(id);
    }

    private void requireNonBlank(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " is required");
        }
    }

    private BigDecimal resolveCoordinate(BigDecimal decimal, String dms) {
        if (dms != null && !dms.isBlank()) {
            return DmsCoordinateConverter.parse(dms);
        }
        if (decimal != null) {
            return decimal;
        }
        throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "Coordinate is required (decimal or DMS)");
    }
}
