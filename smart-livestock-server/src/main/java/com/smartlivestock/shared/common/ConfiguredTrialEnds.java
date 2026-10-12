package com.smartlivestock.shared.common;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.Optional;

/**
 * Parses the platform-wide fixed free-trial deadline configured under
 * {@code smartlivestock.trial.ends-at} (env {@code SMARTLIVESTOCK_TRIAL_ENDS_AT}).
 * <p>
 * Ruling 2026-10-12: every free trial / pilot grant ends at one shared wall-clock
 * deadline (Kenya campaign: 2027-10-01 00:00 EAT = 2027-09-30T21:00:00Z) instead of
 * a rolling now+N days. When the property is blank the callers fall back to their
 * legacy rolling windows. An unparseable value must fail startup, never silently
 * degrade (lessons-learned #18: lenient parsing hides data errors).
 */
public final class ConfiguredTrialEnds {

    private ConfiguredTrialEnds() {
    }

    /**
     * @param raw configured value (nullable/blank = not configured)
     * @return empty when not configured
     * @throws IllegalStateException when configured but unparseable
     */
    public static Optional<Instant> parse(String raw) {
        if (raw == null || raw.isBlank()) {
            return Optional.empty();
        }
        try {
            return Optional.of(Instant.parse(raw.trim()));
        } catch (DateTimeParseException e) {
            throw new IllegalStateException(
                    "Invalid smartlivestock.trial.ends-at value (expect ISO-8601 instant): " + raw, e);
        }
    }
}
