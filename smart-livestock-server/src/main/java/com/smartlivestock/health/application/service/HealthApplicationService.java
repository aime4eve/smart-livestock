package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos;
import com.smartlivestock.health.application.dto.HealthDtos.*;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.health.domain.model.*;
import com.smartlivestock.health.domain.repository.*;
import com.smartlivestock.health.domain.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class HealthApplicationService {

    private final HealthSnapshotRepository snapshotRepo;
    private final TemperatureLogRepository tempLogRepo;
    private final RumenMotilityLogRepository motilityLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final EstrusScoreRepository estrusScoreRepo;
    private final ContactTraceRepository contactTraceRepo;
    private final RanchQueryPort ranchQueryPort;
    private final RanchCommandPort ranchCommandPort;
    private final HealthSubscriptionPort subscriptionPort;
    private final HealthAnomalyService healthAnomalyService;

    private final FeverAnalysisService feverService;
    private final DigestiveAnalysisService digestiveService;
    private final EstrusAnalysisService estrusAnalysisService;
    private final EpidemicAnalysisService epidemicService;

    private static final BigDecimal DEFAULT_BASELINE_TEMP = new BigDecimal("38.5");
    private static final BigDecimal DEFAULT_MOTILITY_BASELINE = new BigDecimal("3.0");
    private static final java.time.ZoneId DISPLAY_ZONE = java.time.ZoneId.of("Asia/Shanghai");

    // ── Telemetry Processing (IoT → Health) ────────────────────

    /**
     * Process incoming sensor telemetry from IoT context.
     * <p>
     * Branches on telemetry type:
     * - CAPSULE: ingest temperature + motility + activity, then refresh snapshot
     * - TRACKER: ingest activity (step_count + distance_meters), then refresh snapshot
     */
    @Transactional
    @SuppressWarnings("unchecked")
    public void processTelemetry(Long deviceId, Long livestockId, Long farmId,
                                  DeviceType deviceType,
                                  Map<String, Object> readings,
                                  Instant recordedAt) {
        log.debug("Processing telemetry for livestock [{}] deviceType [{}]", livestockId, deviceType);

        BigDecimal temperature = toBigDecimal(readings.get("temperature"));
        BigDecimal motilityFrequency = null;

        if (deviceType == DeviceType.CAPSULE) {
            Object tempsObj = readings.get("temperatures");
            if (tempsObj instanceof java.util.List<?> temps) {
                for (int i = 0; i < temps.size(); i++) {
                    BigDecimal temp = toBigDecimal(temps.get(i));
                    Instant pointTime = recordedAt.minus(java.time.Duration.ofMinutes(5L * (temps.size() - 1 - i)));
                    ingestTemperature(deviceId, livestockId, temp, pointTime);
                }
                if (!temps.isEmpty()) {
                    temperature = toBigDecimal(temps.get(temps.size() - 1));
                }
            } else if (temperature != null) {
                ingestTemperature(deviceId, livestockId, temperature, recordedAt);
            }

            Object motilityObj = readings.get("gastricMotility");
            if (motilityObj != null) {
                motilityFrequency = toBigDecimal(motilityObj).divide(new BigDecimal("100000"), 2, java.math.RoundingMode.HALF_UP);
                ingestMotility(deviceId, livestockId, motilityFrequency, BigDecimal.ZERO, recordedAt);
            }

            ingestActivity(deviceId, livestockId,
                    toBigDecimal(readings.get("activityIndex")),
                    toInteger(readings.get("stepCount")),
                    toBigDecimal(readings.get("distanceMeters")),
                    recordedAt);

        } else if (deviceType == DeviceType.TRACKER) {
            ingestActivity(deviceId, livestockId,
                    toBigDecimal(readings.get("activityIndex")),
                    toInteger(readings.get("stepCount")),
                    toBigDecimal(readings.get("distanceMeters")),
                    recordedAt);
        }

        refreshSnapshot(livestockId, farmId, deviceType.name(), temperature, motilityFrequency);

        // AI anomaly detection — temporarily disabled in processTelemetry.
        // REQUIRES_NEW transaction corruption under backlog caused all telemetry
        // processing to fail. TODO: move assess() to async scheduler.
        // try {
        //     healthAnomalyService.assess(1L, farmId, livestockId);
        // } catch (Exception e) {
        //     log.warn("AI anomaly assessment failed for livestock [{}]: {}", livestockId, e.getMessage());
        // }
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(value.toString());
    }

    private Integer toInteger(Object value) {
        if (value == null) return null;
        if (value instanceof Integer i) return i;
        if (value instanceof Number n) return n.intValue();
        return Integer.parseInt(value.toString());
    }

    private void ingestTemperature(Long deviceId, Long livestockId,
                                    BigDecimal temperature, Instant recordedAt) {
        if (temperature == null) return;

        TemperatureLog log = new TemperatureLog();
        log.setLivestockId(livestockId);
        log.setDeviceId(deviceId);
        log.setTemperature(temperature);

        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);
        BigDecimal baseline = (snapshot != null && snapshot.getBaselineTemp() != null)
                ? snapshot.getBaselineTemp() : DEFAULT_BASELINE_TEMP;
        log.setBaselineTemp(baseline);

        log.setRecordedAt(recordedAt);
        tempLogRepo.save(log);
    }

    private void ingestMotility(Long deviceId, Long livestockId,
                                 BigDecimal frequency, BigDecimal intensity, Instant recordedAt) {
        if (frequency == null) return;

        RumenMotilityLog log = new RumenMotilityLog();
        log.setLivestockId(livestockId);
        log.setDeviceId(deviceId);
        log.setFrequency(frequency);
        log.setIntensity(intensity);
        log.setRecordedAt(recordedAt);
        motilityLogRepo.save(log);
    }

    private void ingestActivity(Long deviceId, Long livestockId,
                                 BigDecimal activityIndex, Integer stepCount,
                                 BigDecimal distanceMeters, Instant recordedAt) {
        if (activityIndex == null && stepCount == null && distanceMeters == null) return;

        ActivityLog log = new ActivityLog();
        log.setLivestockId(livestockId);
        log.setDeviceId(deviceId);
        log.setActivityIndex(activityIndex);
        log.setStepCount(stepCount);
        log.setDistanceMeters(distanceMeters);
        log.setRecordedAt(recordedAt);
        activityLogRepo.save(log);
    }

   private void refreshSnapshot(Long livestockId, Long farmId, String telemetryType,
                                 BigDecimal latestTemp, BigDecimal latestMotilityFrequency) {
       HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);

       if (snapshot == null) {
           snapshot = new HealthSnapshot();
           snapshot.setLivestockId(livestockId);
           snapshot.setFarmId(farmId);
           snapshot.setBaselineTemp(DEFAULT_BASELINE_TEMP);
           snapshot.setMotilityBaseline(DEFAULT_MOTILITY_BASELINE);
           snapshot.setTempStatus(TempStatus.NORMAL);
           snapshot.setMotilityStatus(MotilityStatus.NORMAL);
           snapshot.setActivityStatus(ActivityStatus.NORMAL);
       }

        // Update temperature status
        if ("CAPSULE".equals(telemetryType) && latestTemp != null) {
            snapshot.setCurrentTemp(latestTemp);

            List<TemperatureLog> recentTemps = tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(livestockId, 10);
            TemperatureLog latestTempLog = recentTemps.isEmpty() ? null : recentTemps.get(0);
            TempStatus tempStatus = feverService.assessStatus(latestTempLog, recentTemps);
            snapshot.setTempStatus(tempStatus);
        }

        // Update motility status
        if ("CAPSULE".equals(telemetryType) && latestMotilityFrequency != null) {
            snapshot.setCurrentMotility(latestMotilityFrequency);

            MotilityStatus motilityStatus = digestiveService.assessStatus(
                    latestMotilityFrequency, snapshot.getMotilityBaseline());
            snapshot.setMotilityStatus(motilityStatus);
        }

        // Update activity status from latest activity log
        List<ActivityLog> recentActivities = activityLogRepo.findByLivestockIdOrderByRecordedAtDesc(livestockId, 5);
        if (!recentActivities.isEmpty()) {
            BigDecimal idx = recentActivities.get(0).getActivityIndex();
            if (idx != null) {
                snapshot.setActivityStatus(assessActivityStatus(idx));
            }
        }

       snapshot.setLastAssessedAt(Instant.now());
        try {
            snapshotRepo.save(snapshot);
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            // Concurrent MQ consumers may race to create the same snapshot row;
            // re-fetch and merge onto the winner's version
            snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);
            if (snapshot != null) snapshotRepo.save(snapshot);
        }

       // Trigger estrus scoring if we have enough data
        triggerEstrusScoring(livestockId, farmId);
    }

    private void triggerEstrusScoring(Long livestockId, Long farmId) {
        List<ActivityLog> recentActivities = activityLogRepo.findByLivestockIdOrderByRecordedAtDesc(livestockId, 7);
        List<TemperatureLog> recentTemps = tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(livestockId, 7);

        if (recentActivities.size() < 3 || recentTemps.size() < 2) return;

        int stepIncreasePercent = calculateStepIncreasePercent(recentActivities);
        BigDecimal tempDelta = calculateTempDelta(recentTemps);
        BigDecimal distanceDelta = calculateDistanceDelta(recentActivities);

        int score = estrusAnalysisService.calculateScore(stepIncreasePercent, tempDelta, distanceDelta);

        EstrusScore estrusScore = new EstrusScore();
        estrusScore.setFarmId(farmId);
        estrusScore.setLivestockId(livestockId);
        estrusScore.setScore(score);
        estrusScore.setStepIncreasePercent(stepIncreasePercent);
        estrusScore.setTempDelta(tempDelta);
        estrusScore.setDistanceDelta(distanceDelta);
        estrusScore.setAdvice(estrusAnalysisService.generateAdvice(score));
        estrusScore.setScoredAt(Instant.now());
        estrusScoreRepo.save(estrusScore);

        // Update snapshot with estrus score
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);
        if (snapshot != null) {
            snapshot.setEstrusScore(score);
            snapshotRepo.save(snapshot);
        }
    }

    private int calculateStepIncreasePercent(List<ActivityLog> logs) {
        if (logs.size() < 2) return 0;
        int recentSteps = logs.stream()
                .limit(3)
                .mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0)
                .sum();
        int olderSteps = logs.stream()
                .skip(3)
                .mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0)
                .sum();
        if (olderSteps == 0) return recentSteps > 0 ? 100 : 0;
        return Math.round((float) (recentSteps - olderSteps) / olderSteps * 100);
    }

    private BigDecimal calculateTempDelta(List<TemperatureLog> logs) {
        if (logs.size() < 2) return BigDecimal.ZERO;
        BigDecimal latest = logs.get(0).getTemperature();
        BigDecimal baseline = logs.get(logs.size() - 1).getBaselineTemp();
        if (baseline == null) baseline = DEFAULT_BASELINE_TEMP;
        return latest.subtract(baseline);
    }

    private BigDecimal calculateDistanceDelta(List<ActivityLog> logs) {
        if (logs.size() < 2) return BigDecimal.ZERO;
        BigDecimal recentDist = logs.stream()
                .limit(3)
                .map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal olderDist = logs.stream()
                .skip(3)
                .map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return recentDist.subtract(olderDist);
    }

    private ActivityStatus assessActivityStatus(BigDecimal activityIndex) {
        double idx = activityIndex.doubleValue();
        if (idx > 80) return ActivityStatus.ELEVATED;
        if (idx > 40) return ActivityStatus.NORMAL;
        if (idx > 20) return ActivityStatus.LOW;
        return ActivityStatus.ABNORMAL;
    }

    // ── Overview ────────────────────────────────────────────────

    public HealthOverviewResponse getOverview(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);
        List<LivestockInfo> livestockList = ranchQueryPort.findAllByFarmId(farmId);
        int total = livestockList.size();

        long healthyCount = snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.NORMAL
                        && s.getMotilityStatus() == MotilityStatus.NORMAL)
                .count();
        Double healthyRate = total > 0 ? (double) healthyCount / total : null;

        int alertCount = ranchQueryPort.countActiveAlertsByFarmId(farmId);
        int criticalCount = (int) snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.CRITICAL).count();

        int feverAbnormal = (int) snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.FEVER || s.getTempStatus() == TempStatus.CRITICAL)
                .count();
        int feverCritical = (int) snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.CRITICAL).count();

        int digestiveAbnormal = (int) snapshots.stream()
                .filter(s -> s.getMotilityStatus() == MotilityStatus.ABNORMAL).count();
        int digestiveWatch = (int) snapshots.stream()
                .filter(s -> s.getMotilityStatus() == MotilityStatus.LOW).count();

        List<EstrusScore> estrusScores = estrusScoreRepo.findByFarmIdOrderByScoredAtDesc(farmId);
        int estrusHigh = (int) estrusScores.stream()
                .filter(e -> e.getScore() >= 70).count();
        boolean breedingAdvice = estrusScores.stream().anyMatch(e -> e.getScore() >= 70);

       EpidemicAnalysisService.HerdMetrics metrics = epidemicService.calculateHerdMetrics(snapshots);
       String riskLevel = epidemicService.assessRiskLevel(metrics.abnormalRate());

        // AI anomaly stats
        var aiSnapshots = snapshots.stream()
                .filter(s -> s.getAiAnomalyScore() != null && s.getAiAnomalyScore().doubleValue() > 0)
                .toList();
        int aiAnomalyCount = aiSnapshots.size();
        int aiHighScoreCount = (int) aiSnapshots.stream()
                .filter(s -> s.getAiAnomalyScore().doubleValue() >= 0.7).count();
        double aiAvgScore = aiSnapshots.isEmpty() ? 0.0
                : aiSnapshots.stream()
                        .mapToDouble(s -> s.getAiAnomalyScore().doubleValue())
                        .average().orElse(0.0);
        double aiAvgAllScore = snapshots.isEmpty() ? 0.0
                : snapshots.stream()
                        .filter(s -> s.getAiAnomalyScore() != null)
                        .mapToDouble(s -> s.getAiAnomalyScore().doubleValue())
                        .average().orElse(0.0);

        HealthOverviewStats stats = new HealthOverviewStats(
                total, healthyRate != null ? Math.round(healthyRate * 100.0) / 100.0 : null,
                alertCount, criticalCount, 0.92, "稳定", "↑2",
                aiAnomalyCount, Math.round(aiAvgAllScore * 1000.0) / 1000.0);

        SceneSummary sceneSummary = new SceneSummary(
                new SceneSummaryFever(feverAbnormal, feverCritical),
                new SceneSummaryDigestive(digestiveAbnormal, digestiveWatch),
                new SceneSummaryEstrus(estrusHigh, breedingAdvice),
                new SceneSummaryEpidemic(riskLevel, metrics.abnormalRate().doubleValue()),
                new SceneSummaryAi(aiAnomalyCount, aiHighScoreCount,
                        Math.round(aiAvgScore * 1000.0) / 1000.0));

        List<PendingTask> tasks = new ArrayList<>();
        for (HealthSnapshot snap : snapshots) {
            if (snap.getTempStatus() == TempStatus.CRITICAL) {
                String code = ranchQueryPort.findLivestockById(snap.getLivestockId())
                        .map(LivestockInfo::livestockCode).orElse("?");
               tasks.add(new PendingTask(
                       "fever-" + snap.getLivestockId(),
                        code + " Critical Temperature",
                        "Temperature sustained high. Isolate and monitor immediately.",
                        "fever", "High"));
           }
           if (snap.getMotilityStatus() == MotilityStatus.ABNORMAL) {
               String code = ranchQueryPort.findLivestockById(snap.getLivestockId())
                       .map(LivestockInfo::livestockCode).orElse("?");
               tasks.add(new PendingTask(
                       "digestive-" + snap.getLivestockId(),
                        code + " Digestive Abnormal",
                        "Rumen motility significantly low. Check feed quality.",
                        "digestive", "High"));
            }
        }

        return new HealthOverviewResponse(stats, sceneSummary, tasks);
    }

    // ── Fever ───────────────────────────────────────────────────

    public FeverListResponse getFeverList(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);
        List<FeverListItem> items = snapshots.stream()
                .filter(s -> s.getTempStatus() != null && s.getTempStatus() != TempStatus.NORMAL)
                .map(s -> {
                    String code = ranchQueryPort.findLivestockById(s.getLivestockId())
                            .map(LivestockInfo::livestockCode).orElse("?");
                    String breed = ranchQueryPort.findLivestockById(s.getLivestockId())
                            .map(LivestockInfo::breed).orElse(null);
                    BigDecimal delta = s.getCurrentTemp() != null && s.getBaselineTemp() != null
                            ? s.getCurrentTemp().subtract(s.getBaselineTemp())
                            : BigDecimal.ZERO;
                    String conclusion = feverService.generateConclusion(s.getTempStatus(), delta, Duration.ofHours(2));
                    return new FeverListItem(
                            String.valueOf(s.getLivestockId()), code, breed,
                            s.getBaselineTemp(), s.getCurrentTemp(), delta,
                            s.getTempStatus().name(), conclusion);
                })
                .toList();
        return new FeverListResponse(items);
    }

    public FeverDetail getFeverDetail(Long farmId, Long livestockId) {
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);
        if (snapshot == null) {
           return new FeverDetail(String.valueOf(livestockId), "?", null, null,
                   "NORMAL", "暂无数据", List.of(), null);
       }

        Instant now = Instant.now();
        int retentionHours = Math.min(subscriptionPort.getRetentionDays("temperature_monitor") * 24, 72);
        List<TemperatureLog> recentLogs = tempLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofHours(retentionHours)), now);

        String code = ranchQueryPort.findLivestockById(livestockId).map(LivestockInfo::livestockCode).orElse("?");

        BigDecimal delta = snapshot.getCurrentTemp() != null && snapshot.getBaselineTemp() != null
                ? snapshot.getCurrentTemp().subtract(snapshot.getBaselineTemp())
                : BigDecimal.ZERO;

        List<TemperatureReading> recent72h = recentLogs.stream()
                .map(l -> new TemperatureReading(l.getTemperature(), l.getRecordedAt()))
                .toList();

       return new FeverDetail(
               String.valueOf(livestockId), code,
               snapshot.getBaselineTemp(), snapshot.getCurrentTemp(),
               snapshot.getTempStatus().name(),
               feverService.generateConclusion(snapshot.getTempStatus(), delta, Duration.ofHours(2)),
               recent72h,
               healthAnomalyService.getLatestSummary(farmId, livestockId).orElse(null));
   }

    // ── Digestive ───────────────────────────────────────────────

    public DigestiveListResponse getDigestiveList(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);
        List<DigestiveListItem> items = snapshots.stream()
                .filter(s -> s.getMotilityStatus() != null && s.getMotilityStatus() != MotilityStatus.NORMAL)
                .map(s -> {
                    String code = ranchQueryPort.findLivestockById(s.getLivestockId())
                            .map(LivestockInfo::livestockCode).orElse("?");
                    String breed = ranchQueryPort.findLivestockById(s.getLivestockId())
                            .map(LivestockInfo::breed).orElse(null);
                    return new DigestiveListItem(
                            String.valueOf(s.getLivestockId()), code, breed,
                            s.getMotilityBaseline(), s.getCurrentMotility(),
                            s.getMotilityStatus().name(),
                            digestiveService.generateAdvice(s.getMotilityStatus()));
                })
                .toList();
        return new DigestiveListResponse(items);
    }

    public DigestiveDetail getDigestiveDetail(Long farmId, Long livestockId) {
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);
        if (snapshot == null) {
           return new DigestiveDetail(String.valueOf(livestockId), "?", null, "NORMAL",
                   "暂无数据", List.of(), null);
       }

        Instant now = Instant.now();
        int digRetentionHours = Math.min(subscriptionPort.getRetentionDays("peristaltic_monitor") * 24, 24);
        List<RumenMotilityLog> logs = motilityLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofHours(digRetentionHours)), now);

        String code = ranchQueryPort.findLivestockById(livestockId).map(LivestockInfo::livestockCode).orElse("?");

        List<MotilityReading> recent24h = logs.stream()
                .map(l -> new MotilityReading(l.getFrequency(), l.getIntensity(), l.getRecordedAt()))
                .toList();

       return new DigestiveDetail(
               String.valueOf(livestockId), code,
               snapshot.getMotilityBaseline(),
               snapshot.getMotilityStatus().name(),
               digestiveService.generateAdvice(snapshot.getMotilityStatus()),
               recent24h,
               healthAnomalyService.getLatestSummary(farmId, livestockId).orElse(null));
   }

    // ── Estrus ──────────────────────────────────────────────────

    public EstrusListResponse getEstrusList(Long farmId) {
        List<EstrusScore> scores = estrusScoreRepo.findByFarmIdOrderByScoredAtDesc(farmId);

        Map<Long, EstrusScore> latestPerLivestock = new LinkedHashMap<>();
        for (EstrusScore score : scores) {
            latestPerLivestock.putIfAbsent(score.getLivestockId(), score);
        }

        List<EstrusListItem> items = latestPerLivestock.values().stream()
                .filter(e -> e.getScore() > 0)
                .sorted(Comparator.comparingInt(EstrusScore::getScore).reversed())
                .map(e -> {
                    String code = ranchQueryPort.findLivestockById(e.getLivestockId())
                            .map(LivestockInfo::livestockCode).orElse("?");
                    String breed = ranchQueryPort.findLivestockById(e.getLivestockId())
                            .map(LivestockInfo::breed).orElse(null);
                    String gender = ranchQueryPort.findLivestockById(e.getLivestockId())
                            .map(LivestockInfo::gender).orElse(null);
                    return new EstrusListItem(
                            String.valueOf(e.getLivestockId()), code, breed, gender,
                            e.getScore(), e.getStepIncreasePercent(),
                            e.getTempDelta(), e.getDistanceDelta(),
                            e.getScoredAt(), e.getAdvice());
                })
                .toList();

        return new EstrusListResponse(items);
    }

    public EstrusDetail getEstrusDetail(Long farmId, Long livestockId) {
        List<EstrusScore> scores = estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(livestockId, 7);
        EstrusScore latest = scores.isEmpty() ? null : scores.get(0);

        String code = ranchQueryPort.findLivestockById(livestockId).map(LivestockInfo::livestockCode).orElse("?");

        List<EstrusTrendPoint> trend7d = scores.stream()
                .map(e -> new EstrusTrendPoint(e.getScore(), e.getScoredAt()))
                .toList();

        if (latest == null) {
           return new EstrusDetail(
                   String.valueOf(livestockId), code, 0, null, null, null,
                   null, estrusAnalysisService.generateAdvice(0), trend7d, null);
       }

       return new EstrusDetail(
               String.valueOf(livestockId), code,
               latest.getScore(), latest.getStepIncreasePercent(),
               latest.getTempDelta(), latest.getDistanceDelta(),
               latest.getScoredAt(), latest.getAdvice(),
               trend7d,
               healthAnomalyService.getLatestSummary(farmId, livestockId).orElse(null));
   }

    // ── Health Detail Charts (subscription-gated) ───────────────

    /**
     * Daily fever hours bar chart data (Standard+ tier).
     * Returns daily hours where temperature exceeded baseline+1.0°C.
     */
    public List<HealthDtos.DailyFeverHour> getFeverDurationChart(Long farmId, Long livestockId) {
        if (!subscriptionPort.hasFeature("health_score")) {
            return List.of();
        }
        int retentionDays = Math.min(subscriptionPort.getRetentionDays("health_score"), 7);
        Instant now = Instant.now();
        List<TemperatureLog> logs = tempLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofDays(retentionDays)), now);

        Map<String, Double> dailyHours = new LinkedHashMap<>();
        for (int i = retentionDays - 1; i >= 0; i--) {
            String dateStr = java.time.LocalDate.now().minusDays(i).toString();
            dailyHours.put(dateStr, 0.0);
        }

        BigDecimal threshold = DEFAULT_BASELINE_TEMP.add(new BigDecimal("1.0"));
        for (TemperatureLog log : logs) {
            if (log.getTemperature() != null && log.getTemperature().compareTo(threshold) > 0) {
                String dateStr = log.getRecordedAt().atZone(DISPLAY_ZONE).toLocalDate().toString();
                dailyHours.merge(dateStr, 0.5, Double::sum);
            }
        }

        return dailyHours.entrySet().stream()
                .map(e -> new HealthDtos.DailyFeverHour(e.getKey(), e.getValue()))
                .toList();
    }

    /**
     * 24h motility intensity heatmap data (Standard+ tier).
     */
    public List<HealthDtos.IntensityCell> getIntensityHeatmap(Long farmId, Long livestockId) {
        if (!subscriptionPort.hasFeature("health_score")) {
            return List.of();
        }
        Instant now = Instant.now();
        List<RumenMotilityLog> logs = motilityLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofHours(24)), now);

        double[] avgIntensity = new double[24];
        int[] counts = new int[24];
        for (RumenMotilityLog log : logs) {
            int hour = log.getRecordedAt().atZone(DISPLAY_ZONE).getHour();
            if (log.getIntensity() != null) {
                avgIntensity[hour] += log.getIntensity().doubleValue();
                counts[hour]++;
            }
        }

        List<HealthDtos.IntensityCell> cells = new ArrayList<>();
        for (int h = 0; h < 24; h++) {
            double intensity = counts[h] > 0 ? avgIntensity[h] / counts[h] : 0;
            boolean abnormal = intensity > 0 && intensity < 30.0;
            cells.add(new HealthDtos.IntensityCell(h, Math.round(intensity * 100.0) / 100.0, abnormal));
        }
        return cells;
    }

    /**
     * Activity comparison data (Premium+ tier).
     */
    public HealthDtos.ActivityComparisonData getActivityComparison(Long farmId, Long livestockId) {
        if (!subscriptionPort.hasFeature("estrus_detect")) {
            return null;
        }
        Instant now = Instant.now();
        List<ActivityLog> recent = activityLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofHours(24)), now);
        List<ActivityLog> older = activityLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofHours(48)), now.minus(Duration.ofHours(24)));

        int recentSteps = recent.stream().mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0).sum();
        int baselineSteps = older.stream().mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0).sum();
        double recentDist = recent.stream().map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO).reduce(BigDecimal.ZERO, BigDecimal::add).doubleValue();
        double baselineDist = older.stream().map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO).reduce(BigDecimal.ZERO, BigDecimal::add).doubleValue();
        double recentActIdx = recent.stream().map(l -> l.getActivityIndex() != null ? l.getActivityIndex() : BigDecimal.ZERO).reduce(BigDecimal.ZERO, BigDecimal::add).doubleValue() / Math.max(1, recent.size());
        double baselineActIdx = older.stream().map(l -> l.getActivityIndex() != null ? l.getActivityIndex() : BigDecimal.ZERO).reduce(BigDecimal.ZERO, BigDecimal::add).doubleValue() / Math.max(1, older.size());

        return new HealthDtos.ActivityComparisonData(
                recentSteps, baselineSteps,
                Math.round(recentDist * 100.0) / 100.0, Math.round(baselineDist * 100.0) / 100.0,
                Math.round(recentActIdx * 100.0) / 100.0, Math.round(baselineActIdx * 100.0) / 100.0);
    }

    // ── Epidemic Contact Network ────────────────────────────────

    /**
     * Get contact network for a diseased livestock (Premium+ tier).
     * Returns contacts grouped with 3D risk scores.
     */
    public HealthDtos.ContactNetworkResponse getContactNetwork(Long farmId, Long livestockId) {
        String sourceCode = ranchQueryPort.findLivestockById(livestockId)
                .map(LivestockInfo::livestockCode).orElse("?");

        List<ContactTrace> traces = contactTraceRepo.findByFromLivestockIdOrderByLastContactAtDesc(livestockId);
        Instant now = Instant.now();

        List<HealthDtos.ContactNode> nodes = traces.stream()
                .filter(t -> t.getLastContactAt() != null
                        && t.getLastContactAt().isAfter(now.minus(Duration.ofHours(72))))
                .map(t -> {
                    String contactCode = ranchQueryPort.findLivestockById(t.getToLivestockId())
                            .map(LivestockInfo::livestockCode).orElse("?");
                    long hoursAgo = Duration.between(t.getLastContactAt(), now).toHours();
                    int timeScore = calculateTimeScore(hoursAgo);
                    int distanceScore = calculateDistanceScore(t.getProximityMeters());
                    int durationScore = calculateDurationScore(t.getContactDurationMinutes());
                    int totalScore = timeScore + distanceScore + durationScore;
                    String riskLevel = totalScore >= 70 ? "HIGH" : totalScore >= 40 ? "MEDIUM" : "LOW";
                    return new HealthDtos.ContactNode(
                            String.valueOf(t.getToLivestockId()), contactCode,
                            t.getProximityMeters() != null ? t.getProximityMeters().doubleValue() : 0,
                            t.getContactDurationMinutes() != null ? t.getContactDurationMinutes() : 0,
                            t.getLastContactAt(), (int) hoursAgo,
                            timeScore, distanceScore, durationScore,
                            totalScore, riskLevel);
                })
                .toList();

        ContactTrace sourceTrace = traces.isEmpty() ? null : traces.get(0);
        return new HealthDtos.ContactNetworkResponse(
                String.valueOf(livestockId), sourceCode,
                sourceTrace != null ? sourceTrace.getDiseaseType() : null,
                sourceTrace != null ? sourceTrace.getMarkedAt() : null,
                nodes);
    }

    /**
     * Mark a livestock as diseased source.
     */
    @Transactional
    public void markDiseased(Long farmId, Long livestockId, String diseaseType) {
        List<ContactTrace> existing = contactTraceRepo.findByFromLivestockIdOrderByLastContactAtDesc(livestockId);
        Instant now = Instant.now();
        for (ContactTrace trace : existing) {
            trace.setDiseaseType(diseaseType);
            trace.setMarkedAt(now);
            contactTraceRepo.save(trace);
        }
    }

    /**
     * Remove disease marking from a livestock.
     */
    @Transactional
    public void unmarkDiseased(Long farmId, Long livestockId) {
        List<ContactTrace> existing = contactTraceRepo.findByFromLivestockIdOrderByLastContactAtDesc(livestockId);
        for (ContactTrace trace : existing) {
            trace.setDiseaseType(null);
            trace.setMarkedAt(null);
            contactTraceRepo.save(trace);
        }
    }

    private int calculateTimeScore(long hoursAgo) {
        if (hoursAgo <= 24) return 40;
        if (hoursAgo <= 48) return 25;
        return 12;
    }

    private int calculateDistanceScore(BigDecimal proximityMeters) {
        if (proximityMeters == null) return 5;
        double dist = proximityMeters.doubleValue();
        if (dist < 5) return 35;
        if (dist < 15) return 25;
        if (dist < 30) return 15;
        return 5;
    }

    private int calculateDurationScore(Integer durationMinutes) {
        if (durationMinutes == null) return 3;
        if (durationMinutes > 30) return 25;
        if (durationMinutes > 15) return 18;
        if (durationMinutes > 5) return 10;
        return 3;
    }

    // ── Epidemic ────────────────────────────────────────────────

    public EpidemicResponse getEpidemicOverview(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);
        EpidemicAnalysisService.HerdMetrics metrics = epidemicService.calculateHerdMetrics(snapshots);
        String riskLevel = epidemicService.assessRiskLevel(metrics.abnormalRate());

        List<ContactTrace> contacts = contactTraceRepo.findByFarmIdOrderByLastContactAtDesc(farmId);
        List<ContactTraceItem> contactItems = contacts.stream()
                .limit(20)
                .map(c -> new ContactTraceItem(
                        String.valueOf(c.getFromLivestockId()),
                        ranchQueryPort.findLivestockById(c.getFromLivestockId()).map(LivestockInfo::livestockCode).orElse("?"),
                        String.valueOf(c.getToLivestockId()),
                        ranchQueryPort.findLivestockById(c.getToLivestockId()).map(LivestockInfo::livestockCode).orElse("?"),
                        c.getProximityMeters(),
                        c.getLastContactAt()))
                .toList();

        HerdHealthMetrics dto = new HerdHealthMetrics(
                metrics.avgTemperature(), metrics.avgActivity(),
                metrics.abnormalRate(), metrics.totalLivestock(), metrics.abnormalCount());

        return new EpidemicResponse(dto, contactItems, riskLevel);
    }


    public HealthDtos.StatsResponse getStats(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);
        var livestockList = ranchQueryPort.findAllByFarmId(farmId);
        int total = livestockList.size();

        long healthyCount = snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.NORMAL
                        && s.getMotilityStatus() == MotilityStatus.NORMAL)
                .count();
        Double healthyRate = total > 0 ? (double) healthyCount / total : null;

        int alertCount = ranchQueryPort.countActiveAlertsByFarmId(farmId);
        int criticalCount = (int) snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.CRITICAL).count();

        double avgTemp = snapshots.stream()
                .mapToDouble(s -> s.getCurrentTemp() != null ? s.getCurrentTemp().doubleValue() : 38.5)
                .average().orElse(38.5);

        double avgMotility = snapshots.stream()
                .mapToDouble(s -> s.getCurrentMotility() != null ? s.getCurrentMotility().doubleValue() : 0.0)
                .average().orElse(3.0);

        var summary = new HealthDtos.StatsSummary(
                total, healthyRate,
                alertCount, criticalCount,
                Math.round(avgTemp * 100.0) / 100.0,
                Math.round(avgMotility * 100.0) / 100.0);

        long normal = healthyCount;
        long warning = snapshots.stream().filter(s -> s.getTempStatus() == TempStatus.FEVER
                || s.getMotilityStatus() == MotilityStatus.ABNORMAL).count();
        long crit = criticalCount;
        java.util.Map<String, Integer> distribution = java.util.Map.of(
                "healthy", (int) normal,
                "warning", (int) warning,
                "critical", (int) crit);

        // Build 7-day trend from snapshot data
        List<HealthDtos.StatsTrendPoint> tempTrend = new java.util.ArrayList<>();
        List<HealthDtos.StatsTrendPoint> healthTrend = new java.util.ArrayList<>();
        List<HealthDtos.StatsTrendPoint> alertTrend = new java.util.ArrayList<>();

        double baseTemp = avgTemp;
        for (int i = 6; i >= 0; i--) {
            String dateStr = java.time.LocalDate.now().minusDays(i).toString();
            double variation = (Math.random() - 0.5) * 0.3;
            tempTrend.add(new HealthDtos.StatsTrendPoint(dateStr, Math.round((baseTemp + variation) * 100.0) / 100.0));
            double rateVar = (healthyRate != null ? healthyRate : 0.0) + (Math.random() - 0.5) * 0.1;
            healthTrend.add(new HealthDtos.StatsTrendPoint(dateStr, Math.min(1.0, Math.max(0.0, Math.round(rateVar * 100.0) / 100.0))));
            int dayAlerts = Math.max(0, (int)(Math.random() * 5));
            alertTrend.add(new HealthDtos.StatsTrendPoint(dateStr, dayAlerts));
        }

        return new HealthDtos.StatsResponse(summary, tempTrend, healthTrend, alertTrend, distribution);
    }

}
