package com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

@Configuration
public class AgenticPlatformOAuth2RestConfig {

    @Bean(name = "agenticPlatformOAuth2RestTemplate")
    public RestTemplate agenticPlatformOAuth2RestTemplate(AgenticPlatformOAuth2Properties props) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(props.getConnectTimeoutMs());
        factory.setReadTimeout(props.getReadTimeoutMs());
        return new RestTemplate(factory);
    }
}
