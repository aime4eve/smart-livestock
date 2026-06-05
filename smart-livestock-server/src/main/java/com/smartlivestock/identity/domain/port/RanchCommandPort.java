package com.smartlivestock.identity.domain.port;

import java.math.BigDecimal;
import java.util.List;

/**
 * ACL command port for Identity context to execute Ranch context operations.
 */
public interface RanchCommandPort {
    /**
     * Create boundary fence and detect map tiles for a farm.
     */
    void createBoundaryFenceAndDetectTiles(Long farmId, String farmName,
                                            List<BigDecimal> latitudes, List<BigDecimal> longitudes);
}
