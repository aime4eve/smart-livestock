package com.smartlivestock.iot.domain.port.dto;

import com.smartlivestock.iot.domain.model.TrackMatchSource;

import java.math.BigDecimal;

/**
 * Outcome of pairing one RTK track point against its device coordinate.
 *
 * @param matchSource      FILE / GPS_LOG / UNPAIRED
 * @param deviceLatitude   resolved device latitude (null when UNPAIRED)
 * @param deviceLongitude  resolved device longitude (null when UNPAIRED)
 * @param matchedGpsLogId  gps_logs id when GPS_LOG, else null
 * @param timeDiffSeconds  0 for FILE; |recordedAt - collectedAt| for GPS_LOG; null when UNPAIRED
 */
public record TrackPairResult(
    TrackMatchSource matchSource,
    BigDecimal deviceLatitude,
    BigDecimal deviceLongitude,
    Long matchedGpsLogId,
    Integer timeDiffSeconds
) {}
