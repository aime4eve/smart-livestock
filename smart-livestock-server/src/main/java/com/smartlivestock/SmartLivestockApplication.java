package com.smartlivestock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableAsync
@EnableScheduling
@EnableFeignClients(basePackages = "com.smartlivestock.iot.infrastructure.client.agenticplatform")
public class SmartLivestockApplication {
    public static void main(String[] args) {
        SpringApplication.run(SmartLivestockApplication.class, args);
    }
}
