package com.smartlivestock.health.domain.model;

public enum EpidemicDispositionTier {
    CRITICAL(1),
    OBSERVATION(2),
    TRACKING(3),
    ARCHIVE(4);

    private final int rank;

    EpidemicDispositionTier(int rank) {
        this.rank = rank;
    }

    public int getRank() {
        return rank;
    }
}
