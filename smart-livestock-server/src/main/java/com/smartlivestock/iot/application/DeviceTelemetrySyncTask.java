package com.smartlivestock.iot.application;

import java.time.Instant;

/**
 * Message payload for device telemetry sync task (Dispatcher → Worker via RocketMQ).
 */
public record DeviceTelemetrySyncTask(Long deviceId, Instant scheduledAt) {}
