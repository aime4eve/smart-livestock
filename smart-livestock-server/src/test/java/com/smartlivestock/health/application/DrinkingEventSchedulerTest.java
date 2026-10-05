package com.smartlivestock.health.application;

import com.smartlivestock.health.application.service.DrinkingRecalculationService;
import com.smartlivestock.health.application.service.DrinkingRecalculationService.FarmSweep;
import com.smartlivestock.health.application.service.DrinkingRecalculationService.RecalcWindow;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.Scheduled;

import java.lang.reflect.Method;
import java.time.Instant;
import java.time.ZoneId;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Pure unit tests for the NIX-256 Task 4 nightly scheduler: the
 * Asia/Shanghai day-boundary math (package-visible static), the
 * health.drinking.enabled conditional switch, and the delegation into
 * {@link DrinkingRecalculationService}. The farm-sweep semantics
 * (per-farm isolation, aggregation) live in DrinkingRecalculationServiceTest.
 */
class DrinkingEventSchedulerTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

    // ── Day-boundary math (F5 cow-day) ───────────────────────────

    @Test
    void yesterdayWindowUsesShanghaiMidnights() {
        // 2026-10-04T18:30Z is already 10-05 02:30 in Shanghai → today is
        // 10-05, so "yesterday" is 10-04: [10-04 00:00, 10-05 00:00) +08
        // = [2026-10-03T16:00Z, 2026-10-04T16:00Z).
        RecalcWindow window = DrinkingEventScheduler.yesterdayWindow(
                Instant.parse("2026-10-04T18:30:00Z"));
        assertThat(window.from()).isEqualTo(Instant.parse("2026-10-03T16:00:00Z"));
        assertThat(window.to()).isEqualTo(Instant.parse("2026-10-04T16:00:00Z"));
        assertThat(window.to()).isEqualTo(window.from().plus(java.time.Duration.ofDays(1)));
    }

    @Test
    void yesterdayWindowFlipsExactlyAtShanghaiMidnight() {
        // One nanosecond before midnight (10-04 23:59:59.999999999 Shanghai):
        // today is still 10-04 → window is [10-03, 10-04).
        RecalcWindow beforeMidnight = DrinkingEventScheduler.yesterdayWindow(
                Instant.parse("2026-10-04T15:59:59.999999999Z"));
        assertThat(beforeMidnight.from()).isEqualTo(Instant.parse("2026-10-02T16:00:00Z"));
        assertThat(beforeMidnight.to()).isEqualTo(Instant.parse("2026-10-03T16:00:00Z"));

        // At midnight sharp the cow-day flips: the just-finished day 10-04
        // becomes the recalculated "yesterday".
        RecalcWindow atMidnight = DrinkingEventScheduler.yesterdayWindow(
                Instant.parse("2026-10-04T16:00:00Z"));
        assertThat(atMidnight.from()).isEqualTo(Instant.parse("2026-10-03T16:00:00Z"));
        assertThat(atMidnight.to()).isEqualTo(Instant.parse("2026-10-04T16:00:00Z"));
    }

    // ── Conditional switch (health.drinking.enabled) ─────────────

    private final ApplicationContextRunner runner = new ApplicationContextRunner()
            .withBean(DrinkingRecalculationService.class, () -> mock(DrinkingRecalculationService.class))
            .withUserConfiguration(SchedulerOnlyScanConfig.class);

    @Test
    void schedulerBeanExistsByDefaultAndWhenExplicitlyEnabled() {
        runner.run(context -> assertThat(context).hasSingleBean(DrinkingEventScheduler.class));
        runner.withPropertyValues("health.drinking.enabled=true")
                .run(context -> assertThat(context).hasSingleBean(DrinkingEventScheduler.class));
    }

    @Test
    void schedulerBeanAbsentWhenDrinkingDisabled() {
        runner.withPropertyValues("health.drinking.enabled=false")
                .run(context -> assertThat(context).doesNotHaveBean(DrinkingEventScheduler.class));
    }

    @Test
    void schedulerCarriesConditionalAndScheduledAnnotations() throws Exception {
        assertThat(DrinkingEventScheduler.class.getAnnotation(ConditionalOnProperty.class))
                .as("switch must be health.drinking.enabled, default on")
                .satisfies(annotation -> {
                    assertThat(annotation.name()).containsExactly("health.drinking.enabled");
                    assertThat(annotation.havingValue()).isEqualTo("true");
                    assertThat(annotation.matchIfMissing()).isTrue();
                });
        Method nightly = DrinkingEventScheduler.class.getDeclaredMethod("nightlyRecalculate");
        Scheduled scheduled = nightly.getAnnotation(Scheduled.class);
        assertThat(scheduled).isNotNull();
        assertThat(scheduled.cron()).isEqualTo("${health.drinking.analysis-cron:0 40 3 * * *}");
    }

    // ── Delegation: run(now) sweeps yesterday's window ───────────

    @Test
    void runDelegatesYesterdaysWindowToTheSweep() {
        DrinkingRecalculationService service = mock(DrinkingRecalculationService.class);
        when(service.recalculateAllFarms(any(), any()))
                .thenReturn(new FarmSweep(3, 30, 210, 1));
        DrinkingEventScheduler scheduler = new DrinkingEventScheduler(service);

        Instant now = Instant.parse("2026-10-04T18:30:00Z");
        scheduler.run(now);

        RecalcWindow expected = DrinkingEventScheduler.yesterdayWindow(now);
        verify(service).recalculateAllFarms(eq(expected.from()), eq(expected.to()));
    }

    /** Registers ONLY DrinkingEventScheduler via scan so its class-level condition is evaluated. */
    @Configuration
    @ComponentScan(basePackageClasses = DrinkingEventScheduler.class,
            useDefaultFilters = false,
            includeFilters = @ComponentScan.Filter(
                    type = org.springframework.context.annotation.FilterType.ASSIGNABLE_TYPE,
                    classes = DrinkingEventScheduler.class))
    static class SchedulerOnlyScanConfig {
    }
}
