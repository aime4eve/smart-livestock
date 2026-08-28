package com.smartlivestock.iot.application;

import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import com.smartlivestock.iot.infrastructure.client.ns.NsClient;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TbDeviceProvisioningServiceTest {

    private static final String EUI = "001a0103ff000262";
    private static final Instant LATEST = Instant.ofEpochMilli(1787938283391L);

    @Mock private NsClient nsClient;
    @Mock private TbClient tbClient;
    @Mock private DeviceRepository deviceRepository;
    @Mock private TbDeviceBindingRepository bindingRepository;
    @Mock private InstallationRepository installationRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private RanchQueryPort ranchQueryPort;

    private TbDeviceProvisioningService service;

    @BeforeEach
    void setUp() {
        service = new TbDeviceProvisioningService(nsClient, tbClient, deviceRepository,
                bindingRepository, installationRepository, auditLogRepository, ranchQueryPort);
    }

    @Test
    void normalizeEuiShouldLowercaseAndTrim() {
        assertThat(TbDeviceProvisioningService.normalizeEui(" 001A0103FF000262 "))
                .isEqualTo(EUI);
    }

    @Test
    void invalidEuiShouldFailBeforeExternalCalls() {
        assertThatThrownBy(() -> service.preflight("123", 1L))
                .isInstanceOf(Exception.class);
        verify(nsClient, never()).listDevices(any());
    }

    @Test
    void reconcileShouldBeReadOnlyAndReportMissingLocalLayers() {
        when(nsClient.listDevices(89)).thenReturn(List.of(
                new NsClient.NsDevice(EUI, 89, 18, "capsule-262")));
        when(tbClient.fetchDeviceProfiles()).thenReturn(Map.of("profile-1", "瘤胃胶囊-OC-配置-v2"));
        when(tbClient.findDevices(EUI)).thenReturn(List.of(
                new TbClient.TbDeviceView("tb-1", EUI, "profile-1")));
        when(tbClient.fetchLatestTelemetryTs("tb-1")).thenReturn(LATEST);
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(EUI, 1L))
                .thenReturn(List.of());

        var report = service.reconcile(89, 1L);
        var row = report.rows().get(0);

        assertThat(row.tbCandidates()).hasSize(1);
        assertThat(row.localDeviceId()).isNull();
        assertThat(row.bindingStatus()).isNull();
        assertThat(row.differenceCodes()).contains("LOCAL_MISSING");
        assertThat(row.importable()).isTrue();
        assertThat(row.action()).isEqualTo("CREATE_DEVICE_AND_BINDING");
        assertThat(report.counts().nsCount()).isEqualTo(1);
        verify(deviceRepository, never()).save(any());
        verify(bindingRepository, never()).save(any());
        verify(auditLogRepository, never()).save(any());
    }

    @Test
    void reconcileShouldRejectCaseTwins() {
        when(nsClient.listDevices(89)).thenReturn(List.of(
                new NsClient.NsDevice(EUI, 89, 18, null)));
        when(tbClient.fetchDeviceProfiles()).thenReturn(Map.of("profile-1", "瘤胃胶囊-OC-配置-v2"));
        when(tbClient.findDevices(EUI)).thenReturn(List.of(
                new TbClient.TbDeviceView("tb-lower", EUI, "profile-1"),
                new TbClient.TbDeviceView("tb-upper", EUI.toUpperCase(), "profile-1")));
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(EUI, 1L))
                .thenReturn(List.of());

        var row = service.reconcile(89, 1L).rows().get(0);

        assertThat(row.tbCandidates()).extracting("tbDeviceId")
                .containsExactly("tb-lower", "tb-upper");
        assertThat(row.differenceCodes()).contains("TB_AMBIGUOUS");
        assertThat(row.importable()).isFalse();
        verify(tbClient, never()).fetchLatestTelemetryTs(anyString());
    }

    @Test
    void repeatedImportShouldReuseLocalDeviceAndBinding() {
        when(nsClient.listDevices(89)).thenReturn(List.of(
                new NsClient.NsDevice(EUI, 89, 18, null)));
        when(tbClient.fetchDeviceProfiles()).thenReturn(Map.of("profile-1", "瘤胃胶囊-OC-配置-v2"));
        when(tbClient.findDevices(EUI)).thenReturn(List.of(
                new TbClient.TbDeviceView("tb-1", EUI, "profile-1")));

        Device created = device(100L, DeviceStatus.ACTIVE);
        when(deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(EUI, 1L))
                .thenReturn(List.of())
                .thenReturn(List.of(created));
        when(deviceRepository.findByDeviceCode("TB-89-" + EUI)).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(invocation -> {
            Device device = invocation.getArgument(0);
            device.setId(100L);
            return device;
        });
        when(bindingRepository.findByProviderAndExternalDeviceId("THINGSBOARD", "tb-1"))
                .thenReturn(Optional.empty())
                .thenReturn(Optional.of(binding(9L, 100L)));
        when(bindingRepository.findByDeviceIdAndProvider(100L, "THINGSBOARD"))
                .thenReturn(Optional.empty());
        when(bindingRepository.save(any(TbDeviceBinding.class))).thenAnswer(invocation -> {
            TbDeviceBinding binding = invocation.getArgument(0);
            if (binding.getId() == null) binding.setId(9L);
            return binding;
        });

        var first = service.importDevices(89,
                List.of(new TbDeviceProvisioningService.ImportItem(EUI, "tb-1", null)), 1L, 2L);
        var second = service.importDevices(89,
                List.of(new TbDeviceProvisioningService.ImportItem(EUI, "tb-1", null)), 1L, 2L);

        assertThat(first.results().get(0).result()).isEqualTo("IMPORTED");
        assertThat(second.results().get(0).result()).isEqualTo("ALREADY_BOUND");
        assertThat(second.results().get(0).localDeviceId()).isEqualTo(100L);
        assertThat(second.results().get(0).bindingId()).isEqualTo(9L);
        verify(deviceRepository, Mockito.times(2)).save(any(Device.class));
        verify(auditLogRepository, Mockito.times(2)).save(any());
    }

    private static Device device(Long id, DeviceStatus status) {
        Device device = new Device();
        device.setId(id);
        device.setTenantId(1L);
        device.setDeviceCode("TB-89-" + EUI);
        device.setSerialNo(EUI);
        device.setDevEui(EUI);
        device.setDeviceType(DeviceType.CAPSULE);
        device.setStatus(status);
        return device;
    }

    private static TbDeviceBinding binding(Long id, Long deviceId) {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setId(id);
        binding.setTenantId(1L);
        binding.setDeviceId(deviceId);
        binding.setProvider(TbDeviceBinding.PROVIDER_THINGSBOARD);
        binding.setDeviceEui(EUI);
        binding.setExternalDeviceId("tb-1");
        binding.setExternalDeviceName(EUI);
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        return binding;
    }
}
