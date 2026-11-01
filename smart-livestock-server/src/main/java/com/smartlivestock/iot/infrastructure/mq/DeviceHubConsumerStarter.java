package com.smartlivestock.iot.infrastructure.mq;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.client.consumer.DefaultMQPushConsumer;
import org.apache.rocketmq.client.consumer.listener.ConsumeConcurrentlyStatus;
import org.apache.rocketmq.client.consumer.listener.MessageListenerConcurrently;
import org.apache.rocketmq.common.message.MessageExt;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.ContextClosedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * DeviceHub push channel consumer lifecycle: builds a fresh
 * {@link DefaultMQPushConsumer} and starts it after the application is up,
 * retrying every 30s while the broker is unreachable (the 2026-11-01
 * 206-outage fallout fix: "downstream infra unavailable" must degrade to a
 * retrying background start, never a failed Spring context).
 * <p>
 * Each retry builds a NEW consumer instance: RocketMQ's
 * {@code DefaultMQPushConsumerImpl.start()} flips its internal state to
 * RUNNING before the nameserver connect check, so a failed start leaves the
 * instance poisoned ("service state not OK, maybe started once, RUNNING") and
 * re-calling start() on it can never succeed even after the broker recovers.
 * Annotation listener semantics preserved (group/topic/tag/consumeThreadMax=20/
 * CONCURRENTLY, exception → RECONSUME_LATER).
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "smartlivestock.devicehub.enabled", havingValue = "true")
class DeviceHubConsumerStarter {

    private static final Duration START_RETRY_INTERVAL = Duration.ofSeconds(30);

    private final DeviceHubChannelConsumer listener;
    private final String nameServer;
    private final String topic;
    private final String consumerGroup;

    private final AtomicBoolean shuttingDown = new AtomicBoolean(false);
    private final AtomicReference<DefaultMQPushConsumer> running = new AtomicReference<>();
    private ExecutorService startExecutor;

    DeviceHubConsumerStarter(DeviceHubChannelConsumer listener,
                             @Value("${smartlivestock.devicehub.mq-name-server}") String nameServer,
                             @Value("${smartlivestock.devicehub.mq-topic}") String topic,
                             @Value("${smartlivestock.devicehub.mq-consumer-group}") String consumerGroup) {
        this.listener = listener;
        this.nameServer = nameServer;
        this.topic = topic;
        this.consumerGroup = consumerGroup;
    }

    private DefaultMQPushConsumer buildConsumer() throws Exception {
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer(consumerGroup);
        consumer.setNamesrvAddr(nameServer);
        consumer.subscribe(topic, "LIVESTOCK");
        consumer.setConsumeThreadMax(20);
        consumer.registerMessageListener((MessageListenerConcurrently) (msgs, context) -> {
            for (MessageExt msg : msgs) {
                try {
                    listener.onMessage(new String(msg.getBody(), StandardCharsets.UTF_8));
                } catch (Exception e) {
                    log.warn("[DeviceHub] consume failed, will RECONSUME_LATER (msgId={}): {}",
                            msg.getMsgId(), e.getMessage());
                    return ConsumeConcurrentlyStatus.RECONSUME_LATER;
                }
            }
            return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
        });
        return consumer;
    }

    /** Retrying start after the app is fully up — never blocks or fails startup. */
    @EventListener(ApplicationReadyEvent.class)
    void startWithRetry() {
        if (shuttingDown.get()) {
            return;
        }
        startExecutor = Executors.newSingleThreadExecutor(r -> {
            Thread t = new Thread(r, "devicehub-consumer-start");
            t.setDaemon(true);
            return t;
        });
        startExecutor.execute(() -> {
            while (!shuttingDown.get()) {
                DefaultMQPushConsumer consumer = null;
                try {
                    consumer = buildConsumer();
                    consumer.start();
                    running.set(consumer);
                    log.info("[DeviceHub] push consumer started (group={}, topic={} tag LIVESTOCK)",
                            consumerGroup, topic);
                    return;
                } catch (Exception e) {
                    quietShutdown(consumer);
                    log.warn("[DeviceHub] consumer start failed, rebuilding + retrying in {}s: {}",
                            START_RETRY_INTERVAL.toSeconds(), e.getMessage());
                }
                try {
                    TimeUnit.SECONDS.sleep(START_RETRY_INTERVAL.toSeconds());
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    return;
                }
            }
        });
    }

    @EventListener(ContextClosedEvent.class)
    void stopAndShutdown() {
        shuttingDown.set(true);
        if (startExecutor != null) {
            startExecutor.shutdownNow();
        }
        quietShutdown(running.get());
    }

    private static void quietShutdown(DefaultMQPushConsumer consumer) {
        if (consumer == null) {
            return;
        }
        try {
            consumer.shutdown();
        } catch (Exception e) {
            log.debug("[DeviceHub] discard consumer shutdown ignored: {}", e.getMessage());
        }
    }
}
