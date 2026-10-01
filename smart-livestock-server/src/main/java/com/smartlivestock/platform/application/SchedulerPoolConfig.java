package com.smartlivestock.platform.application;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;

/**
 * Explicit scheduler for every @Scheduled task in the app.
 *
 * Why this bean must exist: SignalStreamThrottleConfig exposes a
 * ScheduledExecutorService bean (the signal-stream throttle), which makes
 * Boot's TaskSchedulingAutoConfiguration back off
 * (ConditionalOnMissingBean(TaskScheduler.class, ScheduledExecutorService.class)).
 * With no TaskScheduler bean, @Scheduled tasks fall back to
 * ScheduledAnnotationBeanPostProcessor's private single-thread executor —
 * which in the field (2026-09-30/10-01, test env) sometimes never dispatched
 * at all or died after the first round: every @Scheduled job silently hung
 * (GPS consumption, TB polling, epidemic checks, signal dispatch...) while
 * HTTP/MQ/DB stayed healthy, no error logged. Diagnosed via a heartbeat
 * probe (SchedulerHealthProbe) that never fired, a 10-min-interval job that
 * never logged its first line, and thread dumps without any scheduler
 * thread.
 *
 * An explicit ThreadPoolTaskScheduler bean takes priority over the fallback,
 * gives the 19 scheduled jobs 8 isolated threads (one stuck task can no
 * longer starve the rest), and names the threads so future dumps are
 * readable.
 */
@Configuration
@EnableScheduling
class SchedulerPoolConfig {

    @Bean
    ThreadPoolTaskScheduler taskScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(8);
        scheduler.setThreadNamePrefix("app-sched-");
        scheduler.setRemoveOnCancelPolicy(true);
        scheduler.setWaitForTasksToCompleteOnShutdown(false);
        return scheduler;
    }
}
