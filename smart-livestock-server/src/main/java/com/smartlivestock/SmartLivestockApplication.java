package com.smartlivestock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class SmartLivestockApplication {
    public static void main(String[] args) {
        SpringApplication.run(SmartLivestockApplication.class, args);
    }
}
