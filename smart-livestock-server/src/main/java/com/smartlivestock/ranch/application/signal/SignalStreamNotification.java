package com.smartlivestock.ranch.application.signal;

import java.util.List;

public record SignalStreamNotification(
        Long farmId,
        List<Long> livestockIds,
        List<Long> fenceIds,
        long statusRevision,
        long positionRevision,
        long fenceGeometryRevision
) {}
