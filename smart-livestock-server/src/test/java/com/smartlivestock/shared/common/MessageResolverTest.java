package com.smartlivestock.shared.common;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.support.ResourceBundleMessageSource;

import java.util.Locale;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class MessageResolverTest {

    private MessageResolver messageResolver;

    @BeforeEach
    void setUp() {
        ResourceBundleMessageSource source = new ResourceBundleMessageSource();
        source.setBasename("messages");
        source.setDefaultEncoding("UTF-8");
        messageResolver = new MessageResolver(source);
    }

    @Test
    void resolvesChineseMessage() {
        String msg = messageResolver.resolve("error.demo.notFound", new Object[]{"abc"}, Locale.SIMPLIFIED_CHINESE);
        assertTrue(msg.contains("示例资源不存在"), () -> "Expected Chinese message, got: " + msg);
        assertTrue(msg.contains("abc"));
    }

    @Test
    void resolvesEnglishMessage() {
        String msg = messageResolver.resolve("error.demo.notFound", new Object[]{"abc"}, Locale.ENGLISH);
        assertTrue(msg.contains("Demo resource not found"), () -> "Expected English message, got: " + msg);
        assertTrue(msg.contains("abc"));
    }

    @Test
    void fallsBackToKeyWhenNotFound() {
        String msg = messageResolver.resolve("nonexistent.key.xyz", null, Locale.ENGLISH);
        assertEquals("nonexistent.key.xyz", msg);
    }

    @Test
    void accessDeniedTranslatesByLocale() {
        String zh = messageResolver.resolve("error.accessDenied", null, Locale.SIMPLIFIED_CHINESE);
        String en = messageResolver.resolve("error.accessDenied", null, Locale.ENGLISH);
        assertEquals("权限不足", zh);
        assertEquals("Access denied", en);
    }
}
