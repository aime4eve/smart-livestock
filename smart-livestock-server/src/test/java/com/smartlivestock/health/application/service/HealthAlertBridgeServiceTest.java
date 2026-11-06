package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import com.smartlivestock.identity.application.TenantZoneResolver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class HealthAlertBridgeServiceTest {

    private static final Long LIVESTOCK_ID = 3L;
    private static final Long FARM_ID = 1L;
    /** UTC+8 without DST: fixed expectations for the calving window text. */
    private static final ZoneId FARM_ZONE = ZoneId.of("Asia/Shanghai");

    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RanchCommandPort ranchCommandPort;
    @Mock private TenantZoneResolver tenantZoneResolver;

    private HealthAlertBridgeService service;

    @BeforeEach
    void setUp() {
        service = new HealthAlertBridgeService(ranchQueryPort, ranchCommandPort,
                tenantZoneResolver, new CalvingPredictionProperties());
        when(ranchQueryPort.findLivestockById(LIVESTOCK_ID)).thenReturn(Optional.of(
                new LivestockInfo(LIVESTOCK_ID, FARM_ID, "ST-22", "FEMALE", "ANGUS")));
        when(tenantZoneResolver.zoneForFarm(eq(FARM_ID), isNull())).thenReturn(FARM_ZONE);
    }

    private HealthSnapshot snapshot(TempStatus tempStatus, MotilityStatus motilityStatus, Integer estrusScore) {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(LIVESTOCK_ID);
        snapshot.setFarmId(FARM_ID);
        snapshot.setTempStatus(tempStatus);
        snapshot.setMotilityStatus(motilityStatus);
        snapshot.setEstrusScore(estrusScore);
        return snapshot;
    }

    private AlertInfo capturedAlert() {
        ArgumentCaptor<AlertInfo> captor = ArgumentCaptor.forClass(AlertInfo.class);
        verify(ranchCommandPort).createAlert(captor.capture());
        return captor.getValue();
    }

    @Test
    void tempCritical_noActiveAlert_createsCriticalTemperatureTicket() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "TEMPERATURE_ABNORMAL")).thenReturn(false);
        HealthSnapshot snapshot = snapshot(TempStatus.CRITICAL, MotilityStatus.NORMAL, 0);
        snapshot.setCurrentTemp(new BigDecimal("40.80"));
        snapshot.setBaselineTemp(new BigDecimal("38.50"));

        service.syncAlertsWithSnapshot(snapshot, "THINGSBOARD");

        AlertInfo info = capturedAlert();
        assertEquals(FARM_ID, info.farmId());
        assertEquals(LIVESTOCK_ID, info.livestockId());
        assertEquals("TEMPERATURE_ABNORMAL", info.alertType());
        assertEquals("CRITICAL", info.severity());
        assertEquals("RULE", info.source());
        assertEquals("alert.health.temperature", info.messageKey());
        assertEquals(List.of("ST-22", "40.80", "38.50"), info.messageArgs());
        assertEquals("牲畜 [ST-22] 体温异常：当前 40.80°C，基线 38.50°C", info.message());
    }

    @Test
    void tempElevated_createsWarningTemperatureTicket() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "TEMPERATURE_ABNORMAL")).thenReturn(false);
        HealthSnapshot snapshot = snapshot(TempStatus.ELEVATED, MotilityStatus.NORMAL, 0);
        snapshot.setCurrentTemp(new BigDecimal("39.60"));
        snapshot.setBaselineTemp(new BigDecimal("38.50"));

        service.syncAlertsWithSnapshot(snapshot, "DATAGEN");

        AlertInfo info = capturedAlert();
        assertEquals("TEMPERATURE_ABNORMAL", info.alertType());
        assertEquals("WARNING", info.severity());
        assertEquals("DATAGEN", info.source());
    }

    @Test
    void tempAlarming_activeAlertExists_skipsDuplicateCreation() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "TEMPERATURE_ABNORMAL")).thenReturn(true);
        HealthSnapshot snapshot = snapshot(TempStatus.FEVER, MotilityStatus.NORMAL, 0);

        service.syncAlertsWithSnapshot(snapshot, "DATAGEN");

        verify(ranchCommandPort, never()).createAlert(any());
    }

    @Test
    void tempBackToNormal_resolvesTemperatureTicket() {
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.NORMAL, 0);

        service.syncAlertsWithSnapshot(snapshot, "THINGSBOARD");

        verify(ranchCommandPort).resolveAlert(LIVESTOCK_ID, "TEMPERATURE_ABNORMAL");
        verify(ranchCommandPort, never()).createAlert(any());
    }

    @Test
    void motilityAbnormal_createsDigestiveTicket() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "DIGESTIVE_ABNORMAL")).thenReturn(false);
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.ABNORMAL, 0);
        snapshot.setCurrentMotility(new BigDecimal("1.37"));
        snapshot.setMotilityBaseline(new BigDecimal("3.00"));

        service.syncAlertsWithSnapshot(snapshot, "DATAGEN");

        AlertInfo info = capturedAlert();
        assertEquals("DIGESTIVE_ABNORMAL", info.alertType());
        assertEquals("WARNING", info.severity());
        assertEquals("alert.health.digestive", info.messageKey());
        assertEquals(List.of("ST-22", "1.37", "3.00"), info.messageArgs());
    }

    @Test
    void motilityLow_doesNotCreateDigestiveTicket() {
        // LOW does not color the map marker (see deriveHealthStatus), so no ticket either
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.LOW, 0);

        service.syncAlertsWithSnapshot(snapshot, "THINGSBOARD");

        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort).resolveAlert(LIVESTOCK_ID, "DIGESTIVE_ABNORMAL");
    }

    @Test
    void estrusAtThreshold_createsEstrusTicket() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "ESTRUS")).thenReturn(false);
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.NORMAL, 72);

        service.syncAlertsWithSnapshot(snapshot, "DATAGEN");

        AlertInfo info = capturedAlert();
        assertEquals("ESTRUS", info.alertType());
        assertEquals("WARNING", info.severity());
        assertEquals("alert.health.estrus", info.messageKey());
        assertEquals(List.of("ST-22", "72"), info.messageArgs());
    }

    @Test
    void estrusBelowThreshold_resolvesEstrusTicket() {
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.NORMAL, 69);

        service.syncAlertsWithSnapshot(snapshot, "THINGSBOARD");

        verify(ranchCommandPort).resolveAlert(LIVESTOCK_ID, "ESTRUS");
        verify(ranchCommandPort, never()).createAlert(any());
    }

    @Test
    void hasStateChanged_noTransition_returnsFalse() {
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.NORMAL, 65);

        boolean changed = HealthAlertBridgeService.hasStateChanged(
                snapshot, TempStatus.NORMAL, MotilityStatus.NORMAL, 68);

        assertEquals(false, changed);
    }

    @Test
    void hasStateChanged_motilityTransition_returnsTrue() {
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.ABNORMAL, 0);

        boolean changed = HealthAlertBridgeService.hasStateChanged(
                snapshot, TempStatus.NORMAL, MotilityStatus.NORMAL, 0);

        assertEquals(true, changed);
    }

    @Test
    void hasStateChanged_nullPreviousStates_firstAssessmentCountsAsChange() {
        // Fresh snapshot row: previous states unknown (null) — self-heals missing tickets
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.ABNORMAL, 0);

        boolean changed = HealthAlertBridgeService.hasStateChanged(
                snapshot, null, MotilityStatus.NORMAL, null);

        assertEquals(true, changed);
    }

    @Test
    void hasStateChanged_estrusCrossesThreshold_returnsTrue() {
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.NORMAL, 75);

        boolean changed = HealthAlertBridgeService.hasStateChanged(
                snapshot, TempStatus.NORMAL, MotilityStatus.NORMAL, 60);

        assertEquals(true, changed);
    }

    @Test
    void hasStateChanged_estrusFluctuatesBelowThreshold_returnsFalse() {
        HealthSnapshot snapshot = snapshot(TempStatus.NORMAL, MotilityStatus.NORMAL, 68);

        boolean changed = HealthAlertBridgeService.hasStateChanged(
                snapshot, TempStatus.NORMAL, MotilityStatus.NORMAL, 65);

        assertEquals(false, changed);
    }

    @Test
    void multipleAlarmingDimensions_createOneTicketPerType() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "TEMPERATURE_ABNORMAL")).thenReturn(false);
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "DIGESTIVE_ABNORMAL")).thenReturn(false);
        HealthSnapshot snapshot = snapshot(TempStatus.FEVER, MotilityStatus.ABNORMAL, 0);
        snapshot.setCurrentTemp(new BigDecimal("40.20"));
        snapshot.setBaselineTemp(new BigDecimal("38.50"));
        snapshot.setCurrentMotility(new BigDecimal("1.10"));
        snapshot.setMotilityBaseline(new BigDecimal("3.00"));

        service.syncAlertsWithSnapshot(snapshot, "THINGSBOARD");

        ArgumentCaptor<AlertInfo> captor = ArgumentCaptor.forClass(AlertInfo.class);
        verify(ranchCommandPort, org.mockito.Mockito.times(2)).createAlert(captor.capture());
        List<String> types = captor.getAllValues().stream().map(AlertInfo::alertType).toList();
        assertTrue(types.contains("TEMPERATURE_ABNORMAL"));
        assertTrue(types.contains("DIGESTIVE_ABNORMAL"));
    }

    // ── Calving (NIX-381 evidence presentation, 2×2 key grid) ────

    @Test
    void calvingRaise_withPriorWithWindow_createsEvidenceTicketKeepingDatagenSource() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);

        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 75, "11-07 02:00 ~ 11-08 06:00", "DATAGEN",
                new BigDecimal("0.30"), new BigDecimal("1.36"), 281);

        AlertInfo info = capturedAlert();
        assertEquals(FARM_ID, info.farmId());
        assertEquals(LIVESTOCK_ID, info.livestockId());
        assertEquals("CALVING_WARNING", info.alertType());
        assertEquals("WARNING", info.severity());
        assertEquals("DATAGEN", info.source());
        assertEquals("alert.health.calving.evidence.withPrior.withWindow", info.messageKey());
        assertEquals(List.of("ST-22", "75", "0.30", "1.36", "281", "11-07 02:00 ~ 11-08 06:00"),
                info.messageArgs());
        assertEquals("牲畜 [ST-22] 临产风险偏高：75 分。分析依据：体温较参考期变化 0.30℃；活动量为常态的 1.36 倍；"
                + "配种后 281 天。预计分娩窗口 11-07 02:00 ~ 11-08 06:00", info.message());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    @Test
    void calvingRaise_withPriorNoWindow_createsEvidenceTicketAsRuleSource() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);

        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 70, null, "THINGSBOARD",
                new BigDecimal("0.20"), new BigDecimal("1.20"), 275);

        AlertInfo info = capturedAlert();
        assertEquals("CALVING_WARNING", info.alertType());
        assertEquals("WARNING", info.severity());
        assertEquals("RULE", info.source());
        assertEquals("alert.health.calving.evidence.withPrior.noWindow", info.messageKey());
        assertEquals(List.of("ST-22", "70", "0.20", "1.20", "275"), info.messageArgs());
        assertEquals("牲畜 [ST-22] 临产风险偏高：70 分。分析依据：体温较参考期变化 0.20℃；活动量为常态的 1.20 倍；"
                + "配种后 275 天", info.message());
    }

    @Test
    void calvingRaise_noPriorWithWindow_createsEvidenceTicket() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);

        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 75, "11-07 02:00 ~ 11-08 06:00", "DATAGEN",
                new BigDecimal("0.30"), new BigDecimal("1.36"), null);

        AlertInfo info = capturedAlert();
        assertEquals("DATAGEN", info.source());
        assertEquals("alert.health.calving.evidence.noPrior.withWindow", info.messageKey());
        assertEquals(List.of("ST-22", "75", "0.30", "1.36", "11-07 02:00 ~ 11-08 06:00"), info.messageArgs());
        assertEquals("牲畜 [ST-22] 临产风险偏高：75 分。分析依据：体温较参考期变化 0.30℃；活动量为常态的 1.36 倍；"
                + "未录配种记录。预计分娩窗口 11-07 02:00 ~ 11-08 06:00", info.message());
    }

    @Test
    void calvingRaise_noPriorNoWindow_missingFeaturesRenderDash() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);

        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 70, null, "THINGSBOARD", null, null, null);

        AlertInfo info = capturedAlert();
        assertEquals("RULE", info.source());
        assertEquals("alert.health.calving.evidence.noPrior.noWindow", info.messageKey());
        assertEquals(List.of("ST-22", "70", "—", "—"), info.messageArgs());
        assertEquals("牲畜 [ST-22] 临产风险偏高：70 分。分析依据：体温较参考期变化 —℃；活动量为常态的 — 倍；"
                + "未录配种记录", info.message());
    }

    @Test
    void calvingRaise_activeTicketExists_skipsDuplicateCreation() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(true);

        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 88, "11-07 02:00 ~ 11-08 06:00", "DATAGEN",
                new BigDecimal("0.30"), new BigDecimal("1.36"), 281);

        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    @Test
    void calvingBelowAlertThreshold_resolvesTicket() {
        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 40, null, "DATAGEN", null, null, null);
        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, null, null, "DATAGEN", null, null, null);

        verify(ranchCommandPort, org.mockito.Mockito.times(2)).resolveAlert(LIVESTOCK_ID, "CALVING_WARNING");
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchQueryPort, never()).hasActiveAlert(anyLong(), anyString());
    }

    @Test
    void calvingAlarming_followsConfiguredAlertThreshold() {
        CalvingPredictionProperties properties = new CalvingPredictionProperties();
        properties.setAlertThreshold(65);
        HealthAlertBridgeService tuned = new HealthAlertBridgeService(
                ranchQueryPort, ranchCommandPort, tenantZoneResolver, properties);
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);

        tuned.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 66, null, "DATAGEN", null, null, null);

        assertEquals("CALVING_WARNING", capturedAlert().alertType());
    }

    @Test
    void calvingWindowInstants_formattedInFarmZone() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);

        // 18:00Z / 22:00Z next day = 02:00 / 06:00 in UTC+8, across a date change
        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 75,
                Instant.parse("2026-11-06T18:00:00Z"), Instant.parse("2026-11-07T22:00:00Z"), "DATAGEN",
                new BigDecimal("0.27"), new BigDecimal("1.50"), 281);

        AlertInfo info = capturedAlert();
        assertEquals("alert.health.calving.evidence.withPrior.withWindow", info.messageKey());
        assertEquals(List.of("ST-22", "75", "0.27", "1.50", "281", "11-07 02:00 ~ 11-08 06:00"),
                info.messageArgs());
        verify(tenantZoneResolver).zoneForFarm(FARM_ID, null);
    }

    @Test
    void calvingWindowInstants_missingBound_dropsWindowFromText() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);

        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 75, null, Instant.parse("2026-11-07T22:00:00Z"),
                "DATAGEN", new BigDecimal("0.27"), new BigDecimal("1.50"), 281);

        AlertInfo info = capturedAlert();
        assertEquals("alert.health.calving.evidence.withPrior.noWindow", info.messageKey());
        assertEquals(List.of("ST-22", "75", "0.27", "1.50", "281"), info.messageArgs());
    }

    @Test
    void calvingWindowInstants_emptyOrInvertedWindow_dropsWindowFromText() {
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);
        Instant at = Instant.parse("2026-11-07T22:00:00Z");

        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 75, at, at, "DATAGEN",
                new BigDecimal("0.27"), new BigDecimal("1.50"), 281);
        service.syncCalvingAlert(FARM_ID, LIVESTOCK_ID, 75, at, at.minusSeconds(3600), "DATAGEN",
                new BigDecimal("0.27"), new BigDecimal("1.50"), 281);

        ArgumentCaptor<AlertInfo> captor = ArgumentCaptor.forClass(AlertInfo.class);
        verify(ranchCommandPort, org.mockito.Mockito.times(2)).createAlert(captor.capture());
        captor.getAllValues().forEach(info -> {
            assertEquals("alert.health.calving.evidence.withPrior.noWindow", info.messageKey());
            assertEquals(List.of("ST-22", "75", "0.27", "1.50", "281"), info.messageArgs());
        });
    }
}
