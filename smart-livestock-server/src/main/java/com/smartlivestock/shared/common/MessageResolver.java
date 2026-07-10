package com.smartlivestock.shared.common;

import org.springframework.context.MessageSource;
import org.springframework.stereotype.Component;

import java.util.Locale;

/**
 * Resolves i18n message keys via Spring {@link MessageSource}.
 * <p>
 * Shared by {@link GlobalExceptionHandler} and controller-level catch blocks
 * (e.g. {@code FenceController}) so that message translation stays in one place.
 * <p>
 * When a key is not found in the properties files the key itself is returned
 * as the message, ensuring un-migrated legacy calls still display their raw text.
 */
@Component
public class MessageResolver {

    private final MessageSource messageSource;

    public MessageResolver(MessageSource messageSource) {
        this.messageSource = messageSource;
    }

    /**
     * Resolve a message key with optional placeholder args.
     *
     * @param key           the i18n key (or raw legacy message)
     * @param args          placeholder arguments ({@code {0}, {1} ...}), may be {@code null}
     * @param locale        target locale
     * @return the resolved message, or {@code key} if not found
     */
    public String resolve(String key, Object[] args, Locale locale) {
        return messageSource.getMessage(key, args, key, locale);
    }
}
