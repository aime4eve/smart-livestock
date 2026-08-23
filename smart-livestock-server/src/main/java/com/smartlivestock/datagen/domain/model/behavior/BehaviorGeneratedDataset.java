package com.smartlivestock.datagen.domain.model.behavior;

import java.util.List;

public record BehaviorGeneratedDataset(
        BehaviorGenerationManifest manifest,
        List<BehaviorGeneratedEpisode> episodes,
        List<BehaviorGeneratedWindow> windows) {
    public BehaviorGeneratedDataset {
        episodes = List.copyOf(episodes);
        windows = List.copyOf(windows);
    }
}
