package com.smartlivestock.ranch.application.signal;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

@Configuration
class SignalStreamThrottleConfig {

    @Bean(destroyMethod = "shutdown")
    ScheduledExecutorService signalStreamThrottleExecutor() {
        return Executors.newSingleThreadScheduledExecutor(runnable -> {
            Thread thread = new Thread(runnable, "signal-stream-throttle");
            thread.setDaemon(true);
            return thread;
        });
    }

    @Bean
    Clock signalStreamClock() {
        return Clock.systemUTC();
    }

    @Bean
    SignalStreamNotificationService.ThrottleScheduler signalStreamThrottleScheduler(
            ScheduledExecutorService executor
    ) {
        return (command, delay) -> {
            executor.schedule(command, delay.toMillis(), java.util.concurrent.TimeUnit.MILLISECONDS);
            return command;
        };
    }
}
