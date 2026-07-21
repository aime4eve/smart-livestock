package com.smartlivestock.iot.application.service;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.InstallationApplicationService;
import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformDeviceClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformLicenseClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit-level integration test for DeviceApplicationService.
 * <p>
 * Tests device lifecycle (INVENTORY -> ACTIVE -> DECOMMISSIONED)
 * through the application service layer with mocked repository + platform clients.
 */
@ExtendWith(MockitoExtension.class)
class DeviceApplicationServiceTest {

    @Mock
    private DeviceRepository deviceRepository;

    @Mock
    private AgenticPlatformDeviceClient platformDeviceClient;

    @Mock
    private AgenticPlatformLicenseClient platformLicenseClient;

    @Mock
    private InstallationApplicationService installationApplicationService;

    @InjectMocks
    private DeviceApplicationService service;

    @AfterEach
    void clearTenantContext() {
        TenantContext.clear();
    }

    private Device createInventoryDevice() {
        Device device = new Device(1L, "DEV-001", DeviceType.TRACKER, "AABBCCDD");
        device.setId(1L);
        return device;
    }

    private Device createActiveDevice() {
        Device device = createInventoryDevice();
        device.activate();
        return device;
    }

    private Device createDecommissionedDevice() {
        Device device = createActiveDevice();
        device.decommission();
        return device;
    }

    private InternalResponse<DevicePageResp> emptyPage() {
        DevicePageResp page = new DevicePageResp();
        page.setTotal(0L);
        page.setRecords(Collections.emptyList());
        InternalResponse<DevicePageResp> resp = new InternalResponse<>();
        resp.setSuccess(true);
        resp.setCode(200);
        resp.setData(page);
        return resp;
    }

    private InternalResponse<DeviceRegistrationResp> registered(Long deviceId) {
        DeviceRegistrationResp data = new DeviceRegistrationResp();
        data.setDeviceId(String.valueOf(deviceId));
        InternalResponse<DeviceRegistrationResp> resp = new InternalResponse<>();
        resp.setSuccess(true);
        resp.setCode(200);
        resp.setData(data);
        return resp;
    }

    @Test
    @DisplayName("注册新设备（无 SN/EUI → 平台注册跳过，保持 INVENTORY）")
    void shouldRegisterNewDevice() {
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> {
            Device d = inv.getArgument(0);
            d.setId(1L);
            return d;
        });

        // No serialNo, no devEui → platform registration has no EUI and throws,
        // caught inside registerDevice → device stays INVENTORY.
        DeviceDto result = service.registerDevice(
                new RegisterDeviceCommand("DEV-001", DeviceType.TRACKER, 1L, null, null));

        assertThat(result.deviceCode()).isEqualTo("DEV-001");
        assertThat(result.deviceType()).isEqualTo("TRACKER");
        assertThat(result.status()).isEqualTo("INVENTORY");
        assertThat(result.tenantId()).isEqualTo(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        Device saved = captor.getValue();
        assertThat(saved.getStatus()).isEqualTo(DeviceStatus.INVENTORY);
        assertThat(saved.getTenantId()).isEqualTo(1L);
        assertThat(saved.getDeviceCode()).isEqualTo("DEV-001");
    }

    @Test
    @DisplayName("激活库存设备（平台注册成功 → ACTIVE）")
    void shouldActivateInventoryDevice() {
        Device device = createInventoryDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));
        when(platformDeviceClient.pageDevices(any())).thenReturn(emptyPage());
        when(platformDeviceClient.registerDevice(any())).thenReturn(registered(100L));

        DeviceDto result = service.activateDevice(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.ACTIVE);
        assertThat(captor.getValue().getPlatformDeviceId()).isEqualTo(100L);
        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(result.platformDeviceId()).isEqualTo(100L);
    }

    @Test
    @DisplayName("已激活设备重复激活（幂等，直接返回）")
    void shouldActivateActiveDeviceIdempotently() {
        Device device = createActiveDevice();
        device.setPlatformDeviceId(100L);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        DeviceDto result = service.activateDevice(1L);

        assertThat(result.status()).isEqualTo("ACTIVE");
        // No platform call, no save for an already-active device
        verify(platformDeviceClient, never()).pageDevices(any());
        verify(platformDeviceClient, never()).registerDevice(any());
        verify(deviceRepository, never()).save(any());
    }

    @Test
    @DisplayName("拒绝激活 DECOMMISSIONED 状态的设备")
    void shouldRejectActivateDecommissionedDevice() {
        Device device = createDecommissionedDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> service.activateDevice(1L))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });

        verify(deviceRepository, never()).save(any());
    }

    @Test
    @DisplayName("停用活跃设备")
    void shouldDecommissionActiveDevice() {
        Device device = createActiveDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.decommissionDevice(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.DECOMMISSIONED);
    }

    @Test
    @DisplayName("设备不存在时，抛出 RESOURCE_NOT_FOUND")
    void shouldThrowResourceNotFoundForMissingDevice() {
        when(deviceRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.activateDevice(999L))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND);
                });
    }

    // --- Soft delete ---

    @Test
    @DisplayName("删除有活跃绑定的设备（自动解绑 → 软删除，status 不变）")
    void shouldSoftDeleteDeviceWithActiveInstallation() {
        TenantContext.setCurrentTenant(1L);
        Device device = createActiveDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(installationApplicationService.getActiveInstallation(1L))
                .thenReturn(Optional.of(new InstallationDto(9L, 1L, 5L, 42L,
                        Instant.now(), null, true)));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.deleteDevice(1L, 42L);

        InOrder inOrder = inOrder(installationApplicationService, deviceRepository);
        inOrder.verify(installationApplicationService).getActiveInstallation(1L);
        inOrder.verify(installationApplicationService).remove(1L, 42L);
        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        inOrder.verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getDeletedAt()).isNotNull();
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.ACTIVE);
    }

    @Test
    @DisplayName("删除无活跃绑定的设备（直接软删除，不调用解绑）")
    void shouldSoftDeleteDeviceWithoutInstallation() {
        TenantContext.setCurrentTenant(1L);
        Device device = createInventoryDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(installationApplicationService.getActiveInstallation(1L)).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.deleteDevice(1L, 42L);

        verify(installationApplicationService, never()).remove(any(), any());
        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getDeletedAt()).isNotNull();
    }

    @Test
    @DisplayName("跨租户删除设备（抛 RESOURCE_NOT_FOUND，不暴露存在性）")
    void shouldRejectDeleteForOtherTenant() {
        TenantContext.setCurrentTenant(2L);
        Device device = createInventoryDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> service.deleteDevice(1L, 42L))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));

        verify(installationApplicationService, never()).getActiveInstallation(any());
        verify(deviceRepository, never()).save(any());
    }

    // --- Revive via findOrCreateByEui ---

    private Device createSoftDeletedDevice() {
        Device device = createActiveDevice();
        device.setId(7L);
        device.setPlatformDeviceId(555L);
        device.setDeletedAt(Instant.now());
        return device;
    }

    @Test
    @DisplayName("findOrCreateByEui 命中软删除设备 → 复活（restoreById 先于 save，platformDeviceId 复用）")
    void shouldReviveSoftDeletedDeviceOnFindOrCreateByEui() {
        Device deleted = createSoftDeletedDevice();
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(deleted));
        when(deviceRepository.findByDeviceCode("GPS-NEW")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceDto result = service.findOrCreateByEui("AABBCCDD", "GPS-NEW", 1L);

        InOrder inOrder = inOrder(deviceRepository);
        inOrder.verify(deviceRepository).restoreById(7L, "GPS-NEW");
        inOrder.verify(deviceRepository).save(any(Device.class));
        assertThat(result.status()).isEqualTo("INVENTORY");
        assertThat(result.deviceCode()).isEqualTo("GPS-NEW");
        assertThat(result.platformDeviceId()).isEqualTo(555L);
    }

    @Test
    @DisplayName("findOrCreateByEui 复活时传入空 code → 保留原 deviceCode")
    void shouldKeepOriginalDeviceCodeWhenBlankOnRevive() {
        Device deleted = createSoftDeletedDevice();
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(deleted));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceDto result = service.findOrCreateByEui("AABBCCDD", null, 1L);

        verify(deviceRepository, never()).findByDeviceCode(any());
        assertThat(result.deviceCode()).isEqualTo("DEV-001");
        assertThat(result.status()).isEqualTo("INVENTORY");
    }

    @Test
    @DisplayName("findOrCreateByEui 复活时 deviceCode 撞活跃设备 → DUPLICATE_RESOURCE")
    void shouldRejectReviveWhenDeviceCodeConflicts() {
        Device deleted = createSoftDeletedDevice();
        Device conflicting = createInventoryDevice();
        conflicting.setId(99L);
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(deleted));
        when(deviceRepository.findByDeviceCode("GPS-NEW")).thenReturn(Optional.of(conflicting));

        assertThatThrownBy(() -> service.findOrCreateByEui("AABBCCDD", "GPS-NEW", 1L))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                        .isEqualTo(ErrorCode.DUPLICATE_RESOURCE));

        verify(deviceRepository, never()).restoreById(any(), any());
        verify(deviceRepository, never()).save(any());
    }

    @Test
    @DisplayName("findOrCreateByEui 命中活跃 DECOMMISSIONED 记录（platformDeviceId 非空）→ 不复活不报错")
    void shouldReuseActiveDecommissionedDeviceAsIs() {
        Device device = createDecommissionedDevice();
        device.setPlatformDeviceId(555L);
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(device));

        DeviceDto result = service.findOrCreateByEui("AABBCCDD", null, 1L);

        assertThat(result.status()).isEqualTo("DECOMMISSIONED");
        assertThat(result.platformDeviceId()).isEqualTo(555L);
        verify(deviceRepository, never()).restoreById(any(), any());
        verify(deviceRepository, never()).save(any());
    }

    @Test
    @DisplayName("findOrCreateByEui 命中 ACTIVE 未绑定设备 → 尝试绑定平台（注册门放宽），status 不变且落库")
    void shouldTryBindingForActiveDeviceWithoutPlatformId() {
        Device device = createActiveDevice();
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(device));
        when(platformDeviceClient.pageDevices(any())).thenReturn(emptyPage());
        when(platformDeviceClient.registerDevice(any())).thenReturn(registered(100L));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceDto result = service.findOrCreateByEui("AABBCCDD", null, 1L);

        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(result.platformDeviceId()).isEqualTo(100L);
        verify(deviceRepository).save(any(Device.class));
    }

    // --- Revive via registerDevice ---

    @Test
    @DisplayName("registerDevice 的 EUI 命中软删除设备 → 复活并覆盖表单值")
    void shouldReviveSoftDeletedDeviceOnRegister() {
        Device deleted = createInventoryDevice();
        deleted.setId(9L);
        deleted.setSerialNo("OLD-SN");
        deleted.setDeletedAt(Instant.now());
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(deleted));
        when(deviceRepository.findByDeviceCode("NEW-CODE")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));
        when(platformDeviceClient.pageDevices(any())).thenReturn(emptyPage());
        when(platformDeviceClient.registerDevice(any())).thenReturn(registered(77L));

        DeviceDto result = service.registerDevice(
                new RegisterDeviceCommand("NEW-CODE", DeviceType.CAPSULE, 1L, "AABBCCDD", "NEW-SN"));

        InOrder inOrder = inOrder(deviceRepository);
        inOrder.verify(deviceRepository).restoreById(9L, "NEW-CODE");
        inOrder.verify(deviceRepository, org.mockito.Mockito.times(2)).save(any(Device.class));
        assertThat(result.id()).isEqualTo(9L);
        assertThat(result.deviceCode()).isEqualTo("NEW-CODE");
        assertThat(result.deviceType()).isEqualTo("CAPSULE");
        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(result.platformDeviceId()).isEqualTo(77L);
    }

    @Test
    @DisplayName("registerDevice 的 EUI 复活时 serialNo 为空 → 保留原 serialNo（不被 null 覆盖）")
    void shouldKeepOriginalSerialNoWhenBlankOnRegisterRevive() {
        Device deleted = createInventoryDevice();
        deleted.setId(9L);
        deleted.setSerialNo("OLD-SN");
        deleted.setDeletedAt(Instant.now());
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(deleted));
        when(deviceRepository.findByDeviceCode("NEW-CODE")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));
        when(platformDeviceClient.pageDevices(any())).thenReturn(emptyPage());
        when(platformDeviceClient.registerDevice(any())).thenReturn(registered(77L));

        DeviceDto result = service.registerDevice(
                new RegisterDeviceCommand("NEW-CODE", DeviceType.CAPSULE, 1L, "AABBCCDD", null));

        assertThat(result.serialNo()).isEqualTo("OLD-SN");
    }

    @Test
    @DisplayName("registerDevice 的 EUI 命中活跃设备 → DUPLICATE_RESOURCE（error.deviceEuiDuplicate）")
    void shouldRejectRegisterWhenEuiHitsActiveDevice() {
        Device active = createActiveDevice();
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted("AABBCCDD", 1L))
                .thenReturn(List.of(active));

        assertThatThrownBy(() -> service.registerDevice(
                new RegisterDeviceCommand("NEW-CODE", DeviceType.TRACKER, 1L, "AABBCCDD", "NEW-SN")))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                    assertThat(apiEx.getMessage()).isEqualTo("error.deviceEuiDuplicate");
                });

        verify(deviceRepository, never()).restoreById(any(), any());
        verify(deviceRepository, never()).save(any());
    }
}
