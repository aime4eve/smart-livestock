package com.smartlivestock.iot.application;

import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.iot.domain.model.DeviceProfileRule;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceProfileRuleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeviceProfileRuleServiceTest {

    @Mock private DeviceProfileRuleRepository ruleRepository;
    @Mock private AuditLogRepository auditLogRepository;

    private DeviceProfileRuleService service;

    @BeforeEach
    void setUp() {
        service = new DeviceProfileRuleService(ruleRepository, auditLogRepository);
    }

    @Test
    void resolveActiveTypeMapShouldSkipDisabledAndBlankEntries() {
        DeviceProfileRule active = rule("牛羊追踪器-OC-配置-v2", DeviceType.TRACKER, true);
        DeviceProfileRule disabled = rule("旧链路-profile", DeviceType.TRACKER, false);
        DeviceProfileRule noType = rule("无类型-profile", null, true);
        when(ruleRepository.findAllOrderedByName())
                .thenReturn(List.of(active, disabled, noType));

        Map<String, DeviceType> map = service.resolveActiveTypeMap();

        assertThat(map).containsOnlyKeys("牛羊追踪器-OC-配置-v2");
    }

    @Test
    void createShouldNormalizeNameAndRejectDuplicate() {
        when(ruleRepository.existsByProfileName("a-profile")).thenReturn(true);

        assertThatThrownBy(() -> service.create(" a-profile ", DeviceType.TRACKER,
                true, null, 2L))
                .isInstanceOf(Exception.class);
        verify(ruleRepository, never()).save(any());
    }

    @Test
    void createShouldSaveTrimmedRuleAndAudit() {
        when(ruleRepository.existsByProfileName("a-profile")).thenReturn(false);
        when(ruleRepository.save(any())).thenAnswer(inv -> {
            DeviceProfileRule rule = inv.getArgument(0);
            rule.setId(7L);
            return rule;
        });

        DeviceProfileRule created = service.create(" a-profile ", DeviceType.CAPSULE,
                true, " 备注 ", 2L);

        assertThat(created.getProfileName()).isEqualTo("a-profile");
        assertThat(created.getRemark()).isEqualTo("备注");
        assertThat(created.getCreatedBy()).isEqualTo(2L);
        ArgumentCaptor<com.smartlivestock.identity.domain.model.AuditLog> audit =
                ArgumentCaptor.forClass(com.smartlivestock.identity.domain.model.AuditLog.class);
        verify(auditLogRepository).save(audit.capture());
        assertThat(audit.getValue().getEventType()).isEqualTo("DEVICE_PROFILE_RULE_CREATED");
    }

    @Test
    void updateShouldRequireExistingRule() {
        when(ruleRepository.findById(9L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(9L, DeviceType.TRACKER, true, null, 2L))
                .isInstanceOf(Exception.class);
        verify(ruleRepository, never()).save(any());
    }

    @Test
    void updateShouldRejectMissingDeviceType() {
        when(ruleRepository.findById(9L)).thenReturn(Optional.of(rule("p", DeviceType.TRACKER, true)));

        assertThatThrownBy(() -> service.update(9L, null, true, null, 2L))
                .isInstanceOf(Exception.class);
    }

    @Test
    void deleteShouldRequireExistingRule() {
        when(ruleRepository.findById(5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.delete(5L, 2L)).isInstanceOf(Exception.class);
        verify(ruleRepository, never()).deleteById(any());
    }

    private static DeviceProfileRule rule(String name, DeviceType type, boolean enabled) {
        DeviceProfileRule rule = new DeviceProfileRule();
        rule.setId(1L);
        rule.setProfileName(name);
        rule.setDeviceType(type);
        rule.setEnabled(enabled);
        return rule;
    }
}
