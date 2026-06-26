package com.smartlivestock.datagen.domain.port;

import com.smartlivestock.datagen.domain.port.dto.AlertInfo;

import java.time.Instant;
import java.util.List;

/** ACL port: datagen -> Ranch. Reads fence alerts for fence-breach evaluation. */
public interface AlertQueryPort {
    /** Find fence alerts (FENCE_BREACH / FENCE_APPROACH) within [from, to] for given livestockIds. */
    List<AlertInfo> findFenceAlertsByLivestockIds(List<Long> livestockIds, Instant from, Instant to);
}
