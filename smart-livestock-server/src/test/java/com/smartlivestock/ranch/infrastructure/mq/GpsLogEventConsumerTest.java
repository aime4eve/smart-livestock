package com.smartlivestock.ranch.infrastructure.mq;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.service.FenceBreachDetector;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * NIX-79/D6: GPS points backfilled via manual file import must not trigger
 * fence alerts nor rewrite the livestock's current position.
 */
@ExtendWith(MockitoExtension.class)
class GpsLogEventConsumerTest {

    @Mock private IoTQueryPort ioTQueryPort;
    @Mock private LivestockRepository livestockRepository;
    @Mock private FenceRepository fenceRepository;
    @Mock private AlertRepository alertRepository;
    @Mock private FenceBreachDetector fenceBreachDetector;

    private GpsLogEventConsumer consumer;

    @BeforeEach
    void setUp() {
        consumer = new GpsLogEventConsumer(
                new ObjectMapper(), ioTQueryPort, livestockRepository,
                fenceRepository, alertRepository, fenceBreachDetector);
    }

    private static String message(String source) {
        String sourceField = source != null ? ",\"source\":\"" + source + "\"" : "";
        return "{\"deviceId\":7,\"latitude\":\"28.246777\",\"longitude\":\"112.851138\","
                + "\"recordedAt\":\"2026-07-23T16:09:11Z\"" + sourceField + "}";
    }

    /** Stub the normal path up to a livestock safely inside an active fence. */
    private void stubLivestockInsideFence() {
        InstallationInfo installation = new InstallationInfo(1L, 7L, 10L);
        when(ioTQueryPort.findActiveInstallation(7L)).thenReturn(Optional.of(installation));
        Livestock livestock = org.mockito.Mockito.mock(Livestock.class);
        lenient().when(livestock.getId()).thenReturn(10L);
        when(livestock.getFarmId()).thenReturn(1L);
        lenient().when(livestock.getLivestockCode()).thenReturn("C001");
        when(livestockRepository.findById(10L)).thenReturn(Optional.of(livestock));
        Fence fence = org.mockito.Mockito.mock(Fence.class);
        when(fence.isActive()).thenReturn(true);
        lenient().when(fence.contains(any(GpsCoordinate.class))).thenReturn(true);
        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of(fence));
    }

    @Test
    void onMessage_manualImport_earlyReturn_noFenceDetectionNoPositionUpdate() {
        consumer.onMessage(message("MANUAL_IMPORT"));

        verifyNoInteractions(ioTQueryPort, livestockRepository, fenceRepository,
                alertRepository, fenceBreachDetector);
    }

    @Test
    void onMessage_agenticPlatform_processesNormally() {
        stubLivestockInsideFence();

        consumer.onMessage(message("AGENTIC_PLATFORM"));

        // Position update + inside-fence path reached
        verify(livestockRepository).save(any(Livestock.class));
    }

    @Test
    void onMessage_missingSource_treatedAsAgenticPlatform() {
        stubLivestockInsideFence();

        consumer.onMessage(message(null));

        // In-flight messages without the source field keep the original behavior
        verify(livestockRepository).save(any(Livestock.class));
    }

    @Test
    void onMessage_manualImport_doesNotTouchLivestockEvenWhenInstalled() {
        consumer.onMessage(message("MANUAL_IMPORT"));

        verify(livestockRepository, never()).save(any());
        verify(alertRepository, never()).save(any());
    }

    @Test
    void onMessage_approachAlert_staysActiveUntilLivestockReturnsOrEscalates() {
        stubLivestockInsideFence();
        Fence fence = fenceRepository.findByFarmId(1L).get(0);
        when(fence.contains(any(GpsCoordinate.class))).thenReturn(false);
        when(fence.getId()).thenReturn(1L);
        when(fence.getName()).thenReturn("HKT");

        when(fenceBreachDetector.findBreachedFences(any(), any(GpsCoordinate.class)))
                .thenReturn(List.of(fence));
        when(fenceBreachDetector.isApproaching(eq(fence), any(GpsCoordinate.class)))
                .thenReturn(true);

        AtomicReference<Alert> saved = new AtomicReference<>();
        when(alertRepository.findByLivestockIdAndTypeAndStatus(
                10L, AlertType.FENCE_APPROACH, AlertStatus.ACTIVE))
                .thenReturn(List.of());
        when(alertRepository.save(any(Alert.class))).thenAnswer(invocation -> {
            saved.set(invocation.getArgument(0));
            return saved.get();
        });

        consumer.onMessage(message("DATAGEN"));

        assertEquals(AlertStatus.ACTIVE, saved.get().getStatus());
        assertEquals(AlertType.FENCE_APPROACH, saved.get().getType());
        assertEquals("alert.fence.approach", saved.get().getMessageKey());
        org.junit.jupiter.api.Assertions.assertTrue(saved.get().getMessageArgs().contains("C001"));
        verify(alertRepository, org.mockito.Mockito.times(1))
                .findByLivestockIdAndTypeAndStatus(10L, AlertType.FENCE_APPROACH, AlertStatus.ACTIVE);
    }
}
