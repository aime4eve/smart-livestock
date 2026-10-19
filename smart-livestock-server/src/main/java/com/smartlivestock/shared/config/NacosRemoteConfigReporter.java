package com.smartlivestock.shared.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Reports the {@link NacosRemoteConfigLoader} outcome once the logging system
 * is up. The loader itself runs as an EnvironmentPostProcessor, before any
 * logger is configured, so its result is handed over via a system property.
 * When the property is absent the loader was disabled (feature off), which is
 * the normal release/ONPREM case and stays silent.
 */
@Slf4j
@Component
public class NacosRemoteConfigReporter {

    @PostConstruct
    void report() {
        String outcome = System.getProperty(NacosRemoteConfigLoader.OUTCOME_PROPERTY);
        if (StringUtils.hasText(outcome)) {
            log.info("nacos remote config: {}", outcome);
        }
    }
}
