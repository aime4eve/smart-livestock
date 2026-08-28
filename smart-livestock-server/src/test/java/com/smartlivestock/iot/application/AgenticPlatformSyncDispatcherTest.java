package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AgenticPlatformSyncDispatcherTest {

    @Mock private DeviceRepository deviceRepository;
    @Mock private AgenticPlatformTelemetrySyncJob syncJob;
    @Mock private TbDeviceBindingRepository bindingRepository;

    private AgenticPlatformSyncDispatcher dispatcher;

    @BeforeEach
    void setUp() {
        dispatcher = new AgenticPlatformSyncDispatcher(deviceRepository, syncJob, bindingRepository);
        ReflectionTestUtils.setField(dispatcher, "batchSize", 2);
        ReflectionTestUtils.setField(dispatcher, "concurrency", 1);
        ReflectionTestUtils.setField(dispatcher, "tbBladeExclusion", true);
        ReflectionTestUtils.setField(dispatcher, "tbTenantId", 1L);
    }

    @AfterEach
    void tearDown() {
        dispatcher.shutdown();
    }

    @Test
    void dispatch_shouldSkipTenantBoundDeviceWhenExclusionEnabled() {
        when(deviceRepository.findActivePlatformDeviceIds(eq(0), anyInt()))
                .thenReturn(List.of(122L, 123L));
        when(deviceRepository.findActivePlatformDeviceIds(eq(2), anyInt()))
                .thenReturn(List.of());
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding(122L)));

        dispatcher.dispatch();

        verify(syncJob, timeout(1000)).syncDevice(123L);
        verify(syncJob, never()).syncDevice(122L);
    }

    @Test
    void dispatch_shouldNotQueryBindingsWhenExclusionDisabled() {
        ReflectionTestUtils.setField(dispatcher, "tbBladeExclusion", false);
        when(deviceRepository.findActivePlatformDeviceIds(eq(0), anyInt()))
                .thenReturn(List.of(122L));
        when(deviceRepository.findActivePlatformDeviceIds(eq(2), anyInt()))
                .thenReturn(List.of());

        dispatcher.dispatch();

        verify(syncJob, timeout(1000)).syncDevice(122L);
        verifyNoInteractions(bindingRepository);
    }

    private TbDeviceBinding binding(Long deviceId) {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setTenantId(1L);
        binding.setDeviceId(deviceId);
        binding.setProvider(TbDeviceBinding.PROVIDER_THINGSBOARD);
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        return binding;
    }
}
