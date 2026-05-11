package com.smartlivestock.integration;

import com.smartlivestock.iot.domain.event.GpsLogUpdatedEvent;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.service.FenceBreachDetector;
import com.smartlivestock.ranch.infrastructure.event.GpsLogEventHandler;
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
 * <p>
 * Wires GpsLogEventHandler with mocked repositories to verify the complete
 * cross-context event bridge without Spring context or database.
 */
@ExtendWith(MockitoExtension.class)
class GpsAlertFlowTest {

    @Mock
    private InstallationRepository installationRepository;
    @Mock
    private LivestockRepository livestockRepository;
    @Mock
    private FenceRepository fenceRepository;
    @Mock
    private AlertRepository alertRepository;

    private FenceBreachDetector fenceBreachDetector;
    private GpsLogEventHandler handler;

    @BeforeEach
    void setUp() {
        fenceBreachDetector = new FenceBreachDetector();
        handler = new GpsLogEventHandler(
                installationRepository, livestockRepository,
                fenceRepository, alertRepository, fenceBreachDetector
        );
    }

    // --- Helper methods ---

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

    private Installation createInstallation(Long id, Long deviceId, Long livestockId) {
        Installation installation = new Installation(deviceId, livestockId, 1L);
        installation.setId(id);
        return installation;
    }

    // --- Tests ---

    @Nested
    @DisplayName("GPS -> Alert 端到端流程")
    class EndToEndFlow {

        @Test
        @DisplayName("当牲畜在围栏外时，应创建告警")
        void shouldCreateAlertWhenLivestockOutsideFence() {
            // Given: a fence covering a small area around (28.245, 112.850)
            Long farmId = 1L;
            Fence fence = createSquareFence(farmId, 10L, "牧场围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));
            Livestock livestock = createLivestock(100L, farmId, "LIV-001");
            Installation installation = createInstallation(200L, 300L, 100L);

            when(installationRepository.findActiveByDeviceId(300L)).thenReturn(Optional.of(installation));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence));
            when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> inv.getArgument(0));
            when(livestockRepository.save(any(Livestock.class))).thenAnswer(inv -> inv.getArgument(0));

            // GPS position well outside the fence
            GpsLogUpdatedEvent event = new GpsLogUpdatedEvent(
                    300L, new BigDecimal("28.260"), new BigDecimal("112.860"), Instant.now());

            // When
            handler.onGpsLogUpdated(event);

            // Then: alert created
            ArgumentCaptor<Alert> alertCaptor = ArgumentCaptor.forClass(Alert.class);
            verify(alertRepository).save(alertCaptor.capture());
            Alert createdAlert = alertCaptor.getValue();

            assertThat(createdAlert.getType()).isEqualTo(AlertType.FENCE_BREACH);
            assertThat(createdAlert.getSeverity()).isEqualTo(Severity.WARNING);
            assertThat(createdAlert.getFarmId()).isEqualTo(farmId);
            assertThat(createdAlert.getLivestockId()).isEqualTo(100L);
            assertThat(createdAlert.getFenceId()).isEqualTo(10L);
            assertThat(createdAlert.getMessage()).contains("LIV-001");
            assertThat(createdAlert.getMessage()).contains("牧场围栏");

            // Livestock position should be updated
            verify(livestockRepository).save(any(Livestock.class));
        }

        @Test
        @DisplayName("当牲畜在围栏内时，不应创建告警")
        void shouldNotCreateAlertWhenLivestockInsideFence() {
            Long farmId = 1L;
            Fence fence = createSquareFence(farmId, 10L, "牧场围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));
            Livestock livestock = createLivestock(100L, farmId, "LIV-002");
            Installation installation = createInstallation(200L, 300L, 100L);

            when(installationRepository.findActiveByDeviceId(300L)).thenReturn(Optional.of(installation));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence));

            // GPS position inside the fence
            GpsLogUpdatedEvent event = new GpsLogUpdatedEvent(
                    300L, new BigDecimal("28.245"), new BigDecimal("112.850"), Instant.now());

            // When
            handler.onGpsLogUpdated(event);

            // Then: no alert created
            verify(alertRepository, never()).save(any());
            verify(livestockRepository, never()).save(any());
        }

        @Test
        @DisplayName("当牲畜越出多个围栏时，应为每个围栏创建告警")
        void shouldCreateMultipleAlertsForMultipleBreachedFences() {
            Long farmId = 1L;

            // Two small, non-overlapping fences
            Fence fence1 = createSquareFence(farmId, 10L, "北围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.245"),
                    new BigDecimal("112.845"), new BigDecimal("112.850"));
            Fence fence2 = createSquareFence(farmId, 11L, "南围栏",
                    new BigDecimal("28.230"), new BigDecimal("28.235"),
                    new BigDecimal("112.845"), new BigDecimal("112.850"));

            Livestock livestock = createLivestock(100L, farmId, "LIV-003");
            Installation installation = createInstallation(200L, 300L, 100L);

            when(installationRepository.findActiveByDeviceId(300L)).thenReturn(Optional.of(installation));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence1, fence2));
            when(alertRepository.save(any(Alert.class))).thenAnswer(inv -> inv.getArgument(0));

            // GPS position outside both fences
            GpsLogUpdatedEvent event = new GpsLogUpdatedEvent(
                    300L, new BigDecimal("28.260"), new BigDecimal("112.860"), Instant.now());

            // When
            handler.onGpsLogUpdated(event);

            // Then: 2 alerts created
            verify(alertRepository, times(2)).save(any(Alert.class));
        }

        @Test
        @DisplayName("应跳过已禁用的围栏")
        void shouldSkipDisabledFences() {
            Long farmId = 1L;
            Fence fence = createSquareFence(farmId, 10L, "牧场围栏",
                    new BigDecimal("28.240"), new BigDecimal("28.250"),
                    new BigDecimal("112.845"), new BigDecimal("112.855"));
            fence.disable();

            Livestock livestock = createLivestock(100L, farmId, "LIV-004");
            Installation installation = createInstallation(200L, 300L, 100L);

            when(installationRepository.findActiveByDeviceId(300L)).thenReturn(Optional.of(installation));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(List.of(fence));

            // GPS position outside the disabled fence
            GpsLogUpdatedEvent event = new GpsLogUpdatedEvent(
                    300L, new BigDecimal("28.260"), new BigDecimal("112.860"), Instant.now());

            // When
            handler.onGpsLogUpdated(event);

            // Then: no alert - disabled fence skipped by FenceBreachDetector
            verify(alertRepository, never()).save(any());
        }
    }

    @Nested
    @DisplayName("边界条件和缺失数据")
    class EdgeCases {

        @Test
        @DisplayName("设备无安装记录时，应静默跳过")
        void shouldSkipWhenNoActiveInstallation() {
            when(installationRepository.findActiveByDeviceId(999L)).thenReturn(Optional.empty());

            GpsLogUpdatedEvent event = new GpsLogUpdatedEvent(
                    999L, new BigDecimal("28.260"), new BigDecimal("112.860"), Instant.now());

            // When/Then: no exception, no further interactions
            assertThatNoException().isThrownBy(() -> handler.onGpsLogUpdated(event));
            verify(livestockRepository, never()).findById(any());
            verify(alertRepository, never()).save(any());
        }

        @Test
        @DisplayName("牲畜不存在时，应静默跳过")
        void shouldSkipWhenLivestockNotFound() {
            Installation installation = createInstallation(200L, 300L, 999L);

            when(installationRepository.findActiveByDeviceId(300L)).thenReturn(Optional.of(installation));
            when(livestockRepository.findById(999L)).thenReturn(Optional.empty());

            GpsLogUpdatedEvent event = new GpsLogUpdatedEvent(
                    300L, new BigDecimal("28.260"), new BigDecimal("112.860"), Instant.now());

            assertThatNoException().isThrownBy(() -> handler.onGpsLogUpdated(event));
            verify(fenceRepository, never()).findByFarmId(any());
            verify(alertRepository, never()).save(any());
        }

        @Test
        @DisplayName("牧场无围栏时，应静默跳过")
        void shouldSkipWhenFarmHasNoFences() {
            Long farmId = 1L;
            Livestock livestock = createLivestock(100L, farmId, "LIV-005");
            Installation installation = createInstallation(200L, 300L, 100L);

            when(installationRepository.findActiveByDeviceId(300L)).thenReturn(Optional.of(installation));
            when(livestockRepository.findById(100L)).thenReturn(Optional.of(livestock));
            when(fenceRepository.findByFarmId(farmId)).thenReturn(Collections.emptyList());

            GpsLogUpdatedEvent event = new GpsLogUpdatedEvent(
                    300L, new BigDecimal("28.260"), new BigDecimal("112.860"), Instant.now());

            assertThatNoException().isThrownBy(() -> handler.onGpsLogUpdated(event));
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
