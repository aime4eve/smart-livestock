package com.ai.openapi.key.generator;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;

@Component
public class ApiKeyGenerator {

    private static final String ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    private static final SecureRandom RANDOM = new SecureRandom();

    @Value("${open-api.security.api-key-prefix:ak_live_}")
    private String prefix;

    @Value("${open-api.security.api-key-length:48}")
    private int totalLength;

    public String generate() {
        int randomLength = totalLength - prefix.length();
        StringBuilder sb = new StringBuilder(prefix);
        for (int i = 0; i < randomLength; i++) {
            sb.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }

    public String generateKeyId() {
        StringBuilder sb = new StringBuilder("key_");
        for (int i = 0; i < 16; i++) {
            sb.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
