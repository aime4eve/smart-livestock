package com.smartlivestock.datagen.domain.model.behavior;

import java.time.Instant;
import java.util.UUID;

public record BehaviorGeneratedEpisode(
        UUID id,
        BehaviorSubject subject,
        BehaviorDominant dominantBehavior,
        Instant startAt,
        Instant endAt) {
}
