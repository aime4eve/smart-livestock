package com.smartlivestock.iot.domain.model;

/**
 * Distinguishes a STATIC (single RTK point) test from a DYNAMIC (route) test,
 * a TRAJECTORY (imported RTK track) test and a LINE (standard track line) test.
 * Stored as VARCHAR(10) in {@code gps_quality_tests.test_type}.
 */
public enum TestType {
    STATIC,
    DYNAMIC,
    TRAJECTORY,
    LINE
}
