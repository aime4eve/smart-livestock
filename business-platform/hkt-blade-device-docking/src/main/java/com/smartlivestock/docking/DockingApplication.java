package com.smartlivestock.docking;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * Phase C PoC: verifies Feign + url mode against hkt-blade-device without Nacos.
 */
@SpringBootApplication
@EnableFeignClients(basePackages = "com.smartlivestock.docking.client")
public class DockingApplication {
    public static void main(String[] args) {
        SpringApplication.run(DockingApplication.class, args);
    }
}
