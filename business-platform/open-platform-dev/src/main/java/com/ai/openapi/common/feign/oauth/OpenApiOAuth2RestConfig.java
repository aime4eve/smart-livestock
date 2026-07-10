package com.ai.openapi.common.feign.oauth;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

@Configuration
public class OpenApiOAuth2RestConfig {

    @Bean(name = "openApiOAuth2RestTemplate")
    public RestTemplate openApiOAuth2RestTemplate(OpenApiOAuth2Properties props) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(props.getConnectTimeoutMs());
        factory.setReadTimeout(props.getReadTimeoutMs());
        return new RestTemplate(factory);
    }
}
