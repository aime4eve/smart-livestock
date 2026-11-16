package com.smartlivestock.platform.messaging.push;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataUserRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserFarmAssignmentJpaEntity;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserJpaEntity;
import com.smartlivestock.ranch.application.service.AlertMessageLocalizer;
import com.smartlivestock.ranch.application.signal.AlertCreatedEvent;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * NIX-430: the dispatch pipeline — recipient resolution (farm ACTIVE
 * assignments × per-user toggle), APNs environment filtering, payload
 * build and invalid-token reaping.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PushDispatchServiceTest {

    @Mock
    private ApnsPushService apnsPushService;
    @Mock
    private AlertRepository alertRepository;
    @Mock
    private AlertMessageLocalizer alertMessageLocalizer;
    @Mock
    private UserFarmAssignmentRepository userFarmAssignmentRepository;
    @Mock
    private SpringDataUserRepository userRepository;
    @Mock
    private SpringDataUserPushTokenRepository pushTokenRepository;

    private PushProperties properties;
    private PushDispatchService service;

    @BeforeEach
    void setUp() {
        properties = new PushProperties();
        properties.setEnabled(true);
        properties.setEnvironment("sandbox");
        service = new PushDispatchService(properties, apnsPushService, alertRepository,
                alertMessageLocalizer, userFarmAssignmentRepository, userRepository,
                pushTokenRepository, new ObjectMapper());
    }

    private UserJpaEntity user(long id, boolean pushEnabled) {
        UserJpaEntity u = new UserJpaEntity();
        u.setId(id);
        u.setPushAlertsEnabled(pushEnabled);
        return u;
    }

    private UserPushTokenJpaEntity token(long userId, String env) {
        UserPushTokenJpaEntity t = new UserPushTokenJpaEntity();
        t.setUserId(userId);
        t.setPlatform("ios");
        t.setToken("token-" + userId + "-" + env);
        t.setApnsEnv(env);
        return t;
    }

    private AlertCreatedEvent stubAlert() {
        Alert alert = new Alert(1L, 7L, null, AlertType.TEMPERATURE_ABNORMAL,
                Severity.WARNING, "fallback");
        alert.setId(42L);
        when(alertRepository.findById(42L)).thenReturn(Optional.of(alert));
        when(alertMessageLocalizer.localize(any(Alert.class), any())).thenReturn("体温异常：39.6°C");
        when(userFarmAssignmentRepository.findByFarmIdAndStatus(1L, "ACTIVE"))
                .thenAnswer(inv -> {
                    UserFarmAssignmentJpaEntity a = new UserFarmAssignmentJpaEntity();
                    a.setId(1L);
                    a.setUserId(100L);
                    return List.of(a);
                });
        return new AlertCreatedEvent(1L, 42L);
    }

    @Test
    void dispatchSendsToEnabledUsersTokensInServerEnvironment() {
        when(userRepository.findAllById(any())).thenReturn(List.of(user(100L, true)));
        when(pushTokenRepository.findByUserIdInAndPlatform(List.of(100L), "ios"))
                .thenReturn(List.of(token(100L, "sandbox"), token(100L, "production")));

        service.doDispatch(stubAlert());

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<UserPushTokenJpaEntity>> captor =
                ArgumentCaptor.forClass((Class) List.class);
        verify(apnsPushService).sendAll(captor.capture(), anyString(), any());
        assertThat(captor.getValue()).hasSize(1);
        assertThat(captor.getValue().get(0).getToken()).isEqualTo("token-100-sandbox");
    }

    @Test
    void payloadCarriesAlertIdentityForDeepLink() {
        when(userRepository.findAllById(any())).thenReturn(List.of(user(100L, true)));
        when(pushTokenRepository.findByUserIdInAndPlatform(List.of(100L), "ios"))
                .thenReturn(List.of(token(100L, "sandbox")));

        service.doDispatch(stubAlert());

        ArgumentCaptor<String> payload = ArgumentCaptor.forClass(String.class);
        verify(apnsPushService).sendAll(any(), payload.capture(), any());
        assertThat(payload.getValue()).contains("\"alertId\":42");
        assertThat(payload.getValue()).contains("\"farmId\":1");
        assertThat(payload.getValue()).contains("体温异常");
    }

    @Test
    void disabledSwitchSkipsEverything() {
        properties.setEnabled(false);
        service.doDispatch(stubAlert());
        verify(apnsPushService, never()).sendAll(any(), anyString(), any());
    }

    @Test
    void userToggleOffFiltersRecipients() {
        when(userRepository.findAllById(any())).thenReturn(List.of(user(100L, false)));
        service.doDispatch(stubAlert());
        verify(pushTokenRepository, never()).findByUserIdInAndPlatform(anyCollection(), anyString());
        verify(apnsPushService, never()).sendAll(any(), anyString(), any());
    }

    @Test
    void invalidTokenReportedByApnsIsReaped() {
        when(userRepository.findAllById(any())).thenReturn(List.of(user(100L, true)));
        when(pushTokenRepository.findByUserIdInAndPlatform(List.of(100L), "ios"))
                .thenReturn(List.of(token(100L, "sandbox")));
        UserPushTokenJpaEntity dead = token(100L, "sandbox");
        when(pushTokenRepository.findByToken("token-100-sandbox")).thenReturn(Optional.of(dead));

        List<Consumer<String>> sinks = new java.util.ArrayList<>();
        org.mockito.Mockito.doAnswer(inv -> {
            sinks.add(inv.getArgument(2));
            return null;
        }).when(apnsPushService).sendAll(any(), anyString(), any());

        service.doDispatch(stubAlert());

        assertThat(sinks).hasSize(1);
        sinks.get(0).accept("token-100-sandbox");
        // The sink hops to the dispatch executor (never blocks Pushy's event loop).
        verify(pushTokenRepository, org.mockito.Mockito.after(1000)).delete(dead);
    }

    @Test
    void vanishedAlertSkipsDispatch() {
        AlertCreatedEvent event = stubAlert();
        when(alertRepository.findById(42L)).thenReturn(Optional.empty());
        service.doDispatch(event);
        verify(userFarmAssignmentRepository, never()).findByFarmIdAndStatus(any(), anyString());
        verify(apnsPushService, never()).sendAll(any(), anyString(), any());
    }
}
