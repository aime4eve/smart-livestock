package com.smartlivestock.iot.application;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.iot.domain.model.DeviceProfileRule;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceProfileRuleRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * CRUD for the TB device profile allowlist (NIX-214). Platform-level data:
 * no tenant scoping, gated by PLATFORM_ADMIN/B2B_ADMIN at the controller.
 */
@Service
@RequiredArgsConstructor
public class DeviceProfileRuleService {

    private final DeviceProfileRuleRepository ruleRepository;
    private final AuditLogRepository auditLogRepository;

    @Transactional(readOnly = true)
    public List<DeviceProfileRule> list() {
        return ruleRepository.findAllOrderedByName();
    }

    @Transactional(readOnly = true)
    public Map<String, DeviceType> resolveActiveTypeMap() {
        Map<String, DeviceType> result = new LinkedHashMap<>();
        for (DeviceProfileRule rule : ruleRepository.findAllOrderedByName()) {
            if (rule.isEnabled() && rule.getDeviceType() != null) {
                result.putIfAbsent(rule.getProfileName(), rule.getDeviceType());
            }
        }
        return result;
    }

    @Transactional
    public DeviceProfileRule create(String profileName, DeviceType deviceType,
                                    boolean enabled, String remark, Long operatorId) {
        String normalized = normalizeName(profileName);
        if (ruleRepository.existsByProfileName(normalized)) {
            throw new ApiException(ErrorCode.DUPLICATE_RESOURCE,
                    "iot.profileRule.duplicate", new Object[]{normalized});
        }
        DeviceProfileRule rule = new DeviceProfileRule();
        rule.setProfileName(normalized);
        applyMutableFields(rule, deviceType, enabled, remark, operatorId);
        rule.setCreatedBy(operatorId);
        DeviceProfileRule saved = ruleRepository.save(rule);
        recordAudit("DEVICE_PROFILE_RULE_CREATED", operatorId, saved);
        return saved;
    }

    @Transactional
    public DeviceProfileRule update(Long id, DeviceType deviceType,
                                    boolean enabled, String remark, Long operatorId) {
        DeviceProfileRule rule = ruleRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "iot.profileRule.notFound", new Object[]{id}));
        applyMutableFields(rule, deviceType, enabled, remark, operatorId);
        DeviceProfileRule saved = ruleRepository.save(rule);
        recordAudit("DEVICE_PROFILE_RULE_UPDATED", operatorId, saved);
        return saved;
    }

    @Transactional
    public void delete(Long id, Long operatorId) {
        DeviceProfileRule rule = ruleRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "iot.profileRule.notFound", new Object[]{id}));
        ruleRepository.deleteById(id);
        recordAudit("DEVICE_PROFILE_RULE_DELETED", operatorId, rule);
    }

    private void applyMutableFields(DeviceProfileRule rule, DeviceType deviceType,
                                    boolean enabled, String remark, Long operatorId) {
        if (deviceType == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "iot.profileRule.invalidDeviceType", new Object[]{});
        }
        rule.setDeviceType(deviceType);
        rule.setEnabled(enabled);
        rule.setRemark(remark == null || remark.isBlank() ? null : remark.trim());
        rule.setUpdatedBy(operatorId);
    }

    private static String normalizeName(String profileName) {
        if (profileName == null || profileName.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "iot.profileRule.nameRequired", new Object[]{});
        }
        return profileName.trim();
    }

    private void recordAudit(String action, Long operatorId, DeviceProfileRule rule) {
        auditLogRepository.save(new AuditLog(UUID.randomUUID().toString(), action,
                null, operatorId, action,
                Map.of("ruleId", rule.getId() == null ? "" : rule.getId(),
                        "profileName", rule.getProfileName(),
                        "deviceType", rule.getDeviceType() == null ? "" : rule.getDeviceType().name(),
                        "enabled", rule.isEnabled()),
                java.time.Instant.now()));
    }
}
