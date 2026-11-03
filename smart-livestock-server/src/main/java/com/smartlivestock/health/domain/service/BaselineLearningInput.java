package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Objects;

/**
 * Immutable, self-contained input for one individual baseline learning run
 * (plan 2026-11-03 Task 2). Pure domain value: no Spring, no repositories.
 *
 * <p>Contract notes:</p>
 * <ul>
 *   <li>The event-time window is {@code [asOf - windowDays, asOf)} based on
 *       {@link TemperatureLog#getRecordedAt()}; {@code temperatures} may
 *       contain out-of-window rows, the kernel trims them silently.</li>
 *   <li>{@code drinkingWindows} intervals span drinking start..trough; the
 *       kernel itself appends the post-drinking recovery window.</li>
 *   <li>{@code feverAlertWindows} are only honoured when
 *       {@code previousSource} is {@code LEARNED} (DEFAULT cold start must
 *       not be vetoed by alerts produced with the fixed 38.50 baseline).</li>
 *   <li>Kernel results are deterministic: identical inputs produce identical
 *       results regardless of element order inside the lists.</li>
 * </ul>
 */
public record BaselineLearningInput(
        Long livestockId,
        Instant asOf,
        ZoneId farmZone,
        String previousSource,
        BigDecimal previousBaselineTemp,
        int windowDays,
        int minQualifiedDays,
        int minSamplesPerDay,
        BigDecimal madFloor,
        int feverBufferHours,
        int drinkingRecoveryWindowMin,
        int activityToleranceMin,
        List<String> allowedSources,
        List<TemperatureLog> temperatures,
        List<ActivityLog> activities,
        List<BaselineExclusionWindow> illnessWindows,
        List<BaselineExclusionWindow> feverAlertWindows,
        List<BaselineExclusionWindow> drinkingWindows) {

    public BaselineLearningInput {
        Objects.requireNonNull(madFloor, "madFloor is required");
        allowedSources = List.copyOf(allowedSources == null ? List.of() : allowedSources);
        temperatures = List.copyOf(temperatures == null ? List.of() : temperatures);
        activities = List.copyOf(activities == null ? List.of() : activities);
        illnessWindows = List.copyOf(illnessWindows == null ? List.of() : illnessWindows);
        feverAlertWindows = List.copyOf(feverAlertWindows == null ? List.of() : feverAlertWindows);
        drinkingWindows = List.copyOf(drinkingWindows == null ? List.of() : drinkingWindows);
    }

    public static Builder builder() {
        return new Builder();
    }

    /**
     * Builder whose defaults mirror {@code BaselineLearningProperties}
     * (plan defaults). They are restated here on purpose: the domain kernel
     * must not depend on infrastructure configuration classes.
     */
    public static final class Builder {
        private Long livestockId;
        private Instant asOf;
        private ZoneId farmZone;
        private String previousSource = "DEFAULT";
        private BigDecimal previousBaselineTemp = new BigDecimal("38.50");
        private int windowDays = 10;
        private int minQualifiedDays = 7;
        private int minSamplesPerDay = 2;
        private BigDecimal madFloor = new BigDecimal("0.05");
        private int feverBufferHours = 6;
        private int drinkingRecoveryWindowMin = 120;
        private int activityToleranceMin = 15;
        private List<String> allowedSources =
                List.of("AGENTIC_PLATFORM", "THINGSBOARD", "HTTP", "MANUAL_IMPORT");
        private List<TemperatureLog> temperatures = List.of();
        private List<ActivityLog> activities = List.of();
        private List<BaselineExclusionWindow> illnessWindows = List.of();
        private List<BaselineExclusionWindow> feverAlertWindows = List.of();
        private List<BaselineExclusionWindow> drinkingWindows = List.of();

        public Builder livestockId(Long livestockId) {
            this.livestockId = livestockId;
            return this;
        }

        public Builder asOf(Instant asOf) {
            this.asOf = asOf;
            return this;
        }

        public Builder farmZone(ZoneId farmZone) {
            this.farmZone = farmZone;
            return this;
        }

        public Builder previousSource(String previousSource) {
            this.previousSource = previousSource;
            return this;
        }

        public Builder previousBaselineTemp(BigDecimal previousBaselineTemp) {
            this.previousBaselineTemp = previousBaselineTemp;
            return this;
        }

        public Builder windowDays(int windowDays) {
            this.windowDays = windowDays;
            return this;
        }

        public Builder minQualifiedDays(int minQualifiedDays) {
            this.minQualifiedDays = minQualifiedDays;
            return this;
        }

        public Builder minSamplesPerDay(int minSamplesPerDay) {
            this.minSamplesPerDay = minSamplesPerDay;
            return this;
        }

        public Builder madFloor(BigDecimal madFloor) {
            this.madFloor = madFloor;
            return this;
        }

        public Builder feverBufferHours(int feverBufferHours) {
            this.feverBufferHours = feverBufferHours;
            return this;
        }

        public Builder drinkingRecoveryWindowMin(int drinkingRecoveryWindowMin) {
            this.drinkingRecoveryWindowMin = drinkingRecoveryWindowMin;
            return this;
        }

        public Builder activityToleranceMin(int activityToleranceMin) {
            this.activityToleranceMin = activityToleranceMin;
            return this;
        }

        public Builder allowedSources(List<String> allowedSources) {
            this.allowedSources = allowedSources;
            return this;
        }

        public Builder temperatures(List<TemperatureLog> temperatures) {
            this.temperatures = temperatures;
            return this;
        }

        public Builder activities(List<ActivityLog> activities) {
            this.activities = activities;
            return this;
        }

        public Builder illnessWindows(List<BaselineExclusionWindow> illnessWindows) {
            this.illnessWindows = illnessWindows;
            return this;
        }

        public Builder feverAlertWindows(List<BaselineExclusionWindow> feverAlertWindows) {
            this.feverAlertWindows = feverAlertWindows;
            return this;
        }

        public Builder drinkingWindows(List<BaselineExclusionWindow> drinkingWindows) {
            this.drinkingWindows = drinkingWindows;
            return this;
        }

        public BaselineLearningInput build() {
            Objects.requireNonNull(livestockId, "livestockId is required");
            Objects.requireNonNull(asOf, "asOf is required");
            Objects.requireNonNull(farmZone, "farmZone is required");
            Objects.requireNonNull(previousSource, "previousSource is required");
            return new BaselineLearningInput(livestockId, asOf, farmZone, previousSource,
                    previousBaselineTemp, windowDays, minQualifiedDays, minSamplesPerDay,
                    madFloor, feverBufferHours, drinkingRecoveryWindowMin, activityToleranceMin,
                    allowedSources, temperatures, activities, illnessWindows,
                    feverAlertWindows, drinkingWindows);
        }
    }
}
