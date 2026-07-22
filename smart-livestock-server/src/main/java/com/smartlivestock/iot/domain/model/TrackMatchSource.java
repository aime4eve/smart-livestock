package com.smartlivestock.iot.domain.model;

/**
 * How a trajectory track point obtained its device coordinate.
 * Stored as VARCHAR(10) in {@code gps_quality_track_points.match_source}.
 */
public enum TrackMatchSource {
    /** Device coordinate came from the imported file (columns E/F). */
    FILE,
    /** Device coordinate was paired from gps_logs by device EUI + collection time. */
    GPS_LOG,
    /** No gps_logs report within the pairing tolerance; excluded from statistics. */
    UNPAIRED
}
