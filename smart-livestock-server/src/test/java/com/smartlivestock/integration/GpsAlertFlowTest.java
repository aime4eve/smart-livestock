package com.smartlivestock.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.*;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.service.FenceBreachDetector;
import com.smartlivestock.ranch.infrastructure.mq.GpsLogEventConsumer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNoException;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Integration test for the GPS -> Fence breach -> Alert flow.
 * Wires GpsLogEventConsumer with mocked repositories to verify the complete
 * cross-context event bridge without Spring context or database.
 */
@ExtendWith(MockitoExtension.class)
class GpsAlertFlowTest {

    @Mock private IoTQueryPort ioTQueryPort;
    @Mock private LivestockRepository livestockRepository;
    @Mock private FenceRepository fenceRepository;
    @Mock private AlertRepository alertRepository;

    private FenceBreachDetector fenceBreachDetector;
    private GpsLogEventConsumer consumer;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        fenceBreachDetector = new FenceBreachDetector();
        consumer = new GpsLogEventConsumer(objectMapper, ioTQueryPort,
                livestockRepository, fenceRepository, alertRepository, fenceBreachDetector);
    }

    private String gpsMessage(Long deviceId, String lat, String lon) {
        return "{\"deviceId\":" + deviceId + ",\"latitude\":\"" + lat + "\",\"longitude\":\"" + lon + "\"}";
    }

    private Fence createSquareFence(Long farmId, Long fenceId, String name,
                                    BigDecimal minLat, BigDecimal maxLat,
                                    BigDecimal minLon, BigDecimal maxLon) {
        Fence fence = new Fence(farmId, name, List.of(
                new GpsCoordinate(minLat, minLon),
                new GpsCoordinate(maxLat, minLon),
                new GpsCoordinate(maxLat, maxLon),
                new GpsCoordinate(minLat, maxLon)
        ), "#FF0000");
        fence.setId(fenceId);
        return fence;
    }

    private Livestock createLivestock(Long id, Long farmId, String code) {
        Livestock livestock = new Livestock(farmId, code, "安格斯", "MALE", null, null);
        livestock.setId(id);
        return livestock;
    }

    @Nested
    @DisplayName("GPS -> Alert 端到端流程")
    class EndToEndFlow {

        @Test
        @DisplayName("当牲畜在围栏外时，应创建告警")
        void shouldCreateAlertWhenLivestockOutsideFence() {
            Long farmId = 1L;
            Fence fence = createSquareFence(farmId, 10L, "牧场围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));
            Livestock livestock = createLivestock(100L, farmId, "LIV-001");
            InstallationInfo installInfo = new InstallationInfo(200L, 300L, 100L);

            when(ioTQueryPort.findActiveInstallation(300L)).thenReturn(Optional.of(installInfo));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence));

            consumer.onMessage(gpsMessage(300L, "28.260", "112.860"));

            verify(alertRepository).save(any(Alert.class));
        }

        @Test
        @DisplayName("当牲畜在围栏内时，不应创建告警")
        void shouldNotCreateAlertWhenLivestockInsideFence() {
            Long farmId = 1L;
            Fence fence = createSquareFence(farmId, 10L, "牧场围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));
            Livestock livestock = createLivestock(100L, farmId, "LIV-002");
            InstallationInfo installInfo = new InstallationInfo(200L, 300L, 100L);

            when(ioTQueryPort.findActiveInstallation(300L)).thenReturn(Optional.of(installInfo));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence));

            consumer.onMessage(gpsMessage(300L, "28.245", "112.850"));

            verify(alertRepository, never()).save(any());
        }

        @Test
        @DisplayName("越出多个围栏时，应为每个围栏创建告警")
        void shouldCreateMultipleAlertsWhenBreachingMultipleFences() {
            Long farmId = 1L;
            Fence fence1 = createSquareFence(farmId, 10L, "围栏A",
                    new BigDecimal("28.240"), new BigDecimal("28.245"),
                    new BigDecimal("112.845"), new BigDecimal("112.850"));
            Fence fence2 = createSquareFence(farmId, 11L, "围栏B",
                    new BigDecimal("28.246"), new BigDecimal("28.250"),
                    new BigDecimal("112.850"), new BigDecimal("112.855"));
            Livestock livestock = createLivestock(100L, farmId, "LIV-003");
            InstallationInfo installInfo = new InstallationInfo(200L, 300L, 100L);

            when(ioTQueryPort.findActiveInstallation(300L)).thenReturn(Optional.of(installInfo));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence1, fence2));

            consumer.onMessage(gpsMessage(300L, "28.260", "112.860"));

            verify(alertRepository, times(2)).save(any(Alert.class));
        }

        @Test
        @DisplayName("告警应包含正确的围栏ID")
        void shouldIncludeCorrectFenceIdInAlert() {
            Long farmId = 1L;
            Fence fence = createSquareFence(farmId, 42L, "重要围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));
            Livestock livestock = createLivestock(100L, farmId, "LIV-004");
            InstallationInfo installInfo = new InstallationInfo(200L, 300L, 100L);

            when(ioTQueryPort.findActiveInstallation(300L)).thenReturn(Optional.of(installInfo));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence));

            consumer.onMessage(gpsMessage(300L, "28.260", "112.860"));

            ArgumentCaptor<Alert> alertCaptor = ArgumentCaptor.forClass(Alert.class);
            verify(alertRepository).save(alertCaptor.capture());
            assertThat(alertCaptor.getValue().getFenceId()).isEqualTo(42L);
        }

        @Test
        @DisplayName("已禁用的围栏不应触发告警")
        void shouldNotAlertForDisabledFence() {
            Long farmId = 1L;
            Fence fence = createSquareFence(farmId, 10L, "已禁用围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));
            fence.disable();
            Livestock livestock = createLivestock(100L, farmId, "LIV-005");
            InstallationInfo installInfo = new InstallationInfo(200L, 300L, 100L);

            when(ioTQueryPort.findActiveInstallation(300L)).thenReturn(Optional.of(installInfo));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence));

            consumer.onMessage(gpsMessage(300L, "28.260", "112.860"));

            verify(alertRepository, never()).save(any());
        }
    }

    @Nested
    @DisplayName("边界条件和缺失数据")
    class EdgeCases {

        @Test
        @DisplayName("设备无安装记录时，应静默跳过")
        void shouldSkipWhenNoActiveInstallation() {
            when(ioTQueryPort.findActiveInstallation(999L)).thenReturn(Optional.empty());

            consumer.onMessage(gpsMessage(999L, "28.260", "112.860"));

            verify(livestockRepository, never()).findById(any());
            verify(alertRepository, never()).save(any());
        }

        @Test
        @DisplayName("牲畜不存在时，应静默跳过")
        void shouldSkipWhenLivestockNotFound() {
            InstallationInfo installInfo = new InstallationInfo(200L, 300L, 999L);

            when(ioTQueryPort.findActiveInstallation(300L)).thenReturn(Optional.of(installInfo));
            when(livestockRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatNoException().isThrownBy(() ->
                    consumer.onMessage(gpsMessage(300L, "28.260", "112.860")));
            verify(fenceRepository, never()).findByFarmId(any());
            verify(alertRepository, never()).save(any());
        }

        @Test
        @DisplayName("牧场无围栏时，应静默跳过")
        void shouldSkipWhenFarmHasNoFences() {
            Long farmId = 1L;
            Livestock livestock = createLivestock(100L, farmId, "LIV-005");
            InstallationInfo installInfo = new InstallationInfo(200L, 300L, 100L);

            when(ioTQueryPort.findActiveInstallation(300L)).thenReturn(Optional.of(installInfo));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(Collections.emptyList());

            assertThatNoException().isThrownBy(() ->
                    consumer.onMessage(gpsMessage(300L, "28.260", "112.860")));
            verify(alertRepository, never()).save(any());
        }
    }

    @Nested
    @DisplayName("纯领域层 GPS->围栏检测")
    class PureDomainFlow {

        @Test
        @DisplayName("FenceBreachDetector 正确检测围栏外的点")
        void detectorShouldFindBreachedFences() {
            Fence fence = createSquareFence(1L, 10L, "测试围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));

            GpsCoordinate outsidePoint = new GpsCoordinate("28.260", "112.860");
            List<Fence> breached = fenceBreachDetector.findBreachedFences(List.of(fence), outsidePoint);

            assertThat(breached).hasSize(1);
            assertThat(breached.get(0).getName()).isEqualTo("测试围栏");
        }

        @Test
        @DisplayName("FenceBreachDetector 正确确认围栏内的点")
        void detectorShouldConfirmInsideFences() {
            Fence fence = createSquareFence(1L, 10L, "测试围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));

            GpsCoordinate insidePoint = new GpsCoordinate("28.245", "112.850");
            List<Fence> breached = fenceBreachDetector.findBreachedFences(List.of(fence), insidePoint);

            assertThat(breached).isEmpty();
        }
    }
}
