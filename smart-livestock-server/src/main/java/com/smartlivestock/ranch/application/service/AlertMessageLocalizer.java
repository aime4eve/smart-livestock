package com.smartlivestock.ranch.application.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.shared.common.MessageResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Renders rule-generated alert messages in the locale of the current request.
 * Alerts persisted before this field existed (and manually-created alerts)
 * keep their original message text.
 */
@Component
@RequiredArgsConstructor
public class AlertMessageLocalizer {

    private final MessageResolver messageResolver;
    private final ObjectMapper objectMapper;

    public String localize(Alert alert) {
        if (alert.getMessageKey() == null || alert.getMessageKey().isBlank()) {
            return alert.getMessage();
        }

        Locale locale = LocaleContextHolder.getLocale();
        return messageResolver.resolve(
                alert.getMessageKey(), parseArgs(alert.getMessageArgs()), locale);
    }

    private Object[] parseArgs(String json) {
        if (json == null || json.isBlank()) return new Object[0];
        try {
            JsonNode root = objectMapper.readTree(json);
            if (!root.isArray()) return new Object[0];

            List<Object> args = new ArrayList<>();
            root.forEach(node -> {
                if (node.isNumber()) args.add(node.numberValue());
                else args.add(node.asText());
            });
            return args.toArray();
        } catch (Exception ignored) {
            return new Object[0];
        }
    }
}
