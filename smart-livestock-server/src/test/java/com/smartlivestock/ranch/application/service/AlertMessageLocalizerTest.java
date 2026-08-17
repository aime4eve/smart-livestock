package com.smartlivestock.ranch.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.shared.common.MessageResolver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.i18n.LocaleContextHolder;

import java.util.Locale;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AlertMessageLocalizerTest {

    @Mock private MessageResolver messageResolver;

    @AfterEach
    void tearDown() {
        LocaleContextHolder.resetLocaleContext();
    }

    @Test
    void localize_parsesArgsAndUsesRequestLocale() {
        LocaleContextHolder.setLocale(Locale.ENGLISH);
        Alert alert = alert("legacy", "alert.fence.breach",
                "[\"C001\",\"North\",\"28.1\",\"112.1\"]");
        AlertMessageLocalizer localizer = new AlertMessageLocalizer(
                messageResolver, new ObjectMapper());
        when(messageResolver.resolve(
                eq("alert.fence.breach"), any(), eq(Locale.ENGLISH)))
                .thenReturn("localized");

        assertEquals("localized", localizer.localize(alert));
    }

    @Test
    void localize_withoutKeyKeepsLegacyMessage() {
        Alert alert = alert("历史告警", null, null);
        AlertMessageLocalizer localizer = new AlertMessageLocalizer(
                messageResolver, new ObjectMapper());

        assertEquals("历史告警", localizer.localize(alert));
    }

    @Test
    void localize_invalidArgsFallsBackToNoArguments() {
        LocaleContextHolder.setLocale(Locale.SIMPLIFIED_CHINESE);
        Alert alert = alert("legacy", "alert.device.tamper", "invalid-json");
        AlertMessageLocalizer localizer = new AlertMessageLocalizer(
                messageResolver, new ObjectMapper());
        when(messageResolver.resolve(
                eq("alert.device.tamper"), eq(new Object[0]),
                eq(Locale.SIMPLIFIED_CHINESE)))
                .thenReturn("localized-no-args");

        assertEquals("localized-no-args", localizer.localize(alert));
        verify(messageResolver).resolve(
                eq("alert.device.tamper"), any(), eq(Locale.SIMPLIFIED_CHINESE));
    }

    private static Alert alert(String message, String key, String args) {
        Alert alert = new Alert(1L, null, null,
                AlertType.FENCE_BREACH, Severity.WARNING, message);
        alert.setMessageKey(key);
        alert.setMessageArgs(args);
        return alert;
    }
}
