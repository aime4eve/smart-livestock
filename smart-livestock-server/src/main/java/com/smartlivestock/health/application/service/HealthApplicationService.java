package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.*;
import com.smartlivestock.health.domain.model.*;
import com.smartlivestock.health.domain.repository.*;
import com.smartlivestock.health.domain.service.*;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HealthApplicationService {

    private final HealthSnapshotRepository snapshotRepo;
    private final TemperatureLogRepository tempLogRepo;
    private final RumenMotilityLogRepository motilityLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final EstrusScoreRepository estrusScoreRepo;
    private final ContactTraceRepository contactTraceRepo;
    private final LivestockRepository livestockRepo;
    private final AlertRepository alertRepo;

    private final FeverAnalysisService feverService;
    private final DigestiveAnalysisService digestiveService;
    private final EstrusAnalysisService estrusAnalysisService;
    private final EpidemicAnalysisService epidemicService;

    // ── Overview ────────────────────────────────────────────────

    public HealthOverviewResponse getOverview(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);
        List<Livestock> livestockList = livestockRepo.findByFarmId(farmId);
        int total = livestockList.size();

        long healthyCount = snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.NORMAL
                        && s.getMotilityStatus() == MotilityStatus.NORMAL)
                .count();
        double healthyRate = total > 0 ? (double) healthyCount / total : 1.0;

        int alertCount = (int) alertRepo.findByFarmIdAndStatus(farmId, AlertStatus.PENDING).stream()
                .filter(a -> a.getType() == AlertType.TEMPERATURE_ABNORMAL
                        || a.getType() == AlertType.ESTRUS
                        || a.getType() == AlertType.EPIDEMIC)
                .count();
        int criticalCount = (int) snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.CRITICAL).count();

        // Scene summaries
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

        HealthOverviewStats stats = new HealthOverviewStats(
                total, Math.round(healthyRate * 100.0) / 100.0,
                alertCount, criticalCount, 0.92, "稳定", "↑2");

        SceneSummary sceneSummary = new SceneSummary(
                new SceneSummaryFever(feverAbnormal, feverCritical),
                new SceneSummaryDigestive(digestiveAbnormal, digestiveWatch),
                new SceneSummaryEstrus(estrusHigh, breedingAdvice),
                new SceneSummaryEpidemic(riskLevel, metrics.abnormalRate().doubleValue()));

        // Pending tasks from critical/warning snapshots
        List<PendingTask> tasks = new ArrayList<>();
        for (HealthSnapshot snap : snapshots) {
            if (snap.getTempStatus() == TempStatus.CRITICAL) {
                String code = livestockRepo.findById(snap.getLivestockId())
                        .map(Livestock::getLivestockCode).orElse("?");
                tasks.add(new PendingTask(
                        "fever-" + snap.getLivestockId(),
                        code + " 体温危急",
                        "体温 " + snap.getCurrentTemp() + "°C",
                        "/twin/fever/" + snap.getLivestockId(),
                        "CRITICAL"));
            }
        }

        return new HealthOverviewResponse(stats, sceneSummary, tasks);
    }

    // ── Fever ───────────────────────────────────────────────────

    public FeverListResponse getFeverList(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);

        List<FeverListItem> items = snapshots.stream()
                .filter(s -> s.getTempStatus() != TempStatus.NORMAL && s.getCurrentTemp() != null)
                .sorted(Comparator.comparing((HealthSnapshot s) -> s.getTempStatus() == TempStatus.CRITICAL ? 0 : 1)
                        .thenComparing(s -> s.getCurrentTemp() != null ? s.getCurrentTemp().negate() : BigDecimal.ZERO))
                .map(s -> {
                    String code = livestockRepo.findById(s.getLivestockId())
                            .map(Livestock::getLivestockCode).orElse("?");
                    String breed = livestockRepo.findById(s.getLivestockId())
                            .map(Livestock::getBreed).orElse(null);
                    BigDecimal delta = s.getCurrentTemp().subtract(s.getBaselineTemp());
                    String conclusion = feverService.generateConclusion(s.getTempStatus(), delta, null);
                    return new FeverListItem(
                            String.valueOf(s.getLivestockId()), code, breed,
                            s.getBaselineTemp(), s.getCurrentTemp(), delta,
                            s.getTempStatus().name(), conclusion);
                })
                .toList();

        return new FeverListResponse(items);
    }

    public FeverDetail getFeverDetail(Long farmId, Long livestockId) {
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElseThrow();
        Instant now = Instant.now();
        List<TemperatureLog> logs = tempLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofHours(72)), now);

        String code = livestockRepo.findById(livestockId).map(Livestock::getLivestockCode).orElse("?");

        List<TemperatureReading> recent72h = logs.stream()
                .map(l -> new TemperatureReading(l.getTemperature(), l.getRecordedAt()))
                .toList();

        BigDecimal threshold = snapshot.getBaselineTemp().add(new BigDecimal("1.0"));
        BigDecimal delta = snapshot.getCurrentTemp() != null
                ? snapshot.getCurrentTemp().subtract(snapshot.getBaselineTemp()) : BigDecimal.ZERO;

        return new FeverDetail(
                String.valueOf(livestockId), code,
                snapshot.getBaselineTemp(), threshold,
                snapshot.getTempStatus().name(),
                feverService.generateConclusion(snapshot.getTempStatus(), delta, null),
                recent72h);
    }

    // ── Digestive ───────────────────────────────────────────────

    public DigestiveListResponse getDigestiveList(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId);

        List<DigestiveListItem> items = snapshots.stream()
                .filter(s -> s.getCurrentMotility() != null)
                .filter(s -> s.getMotilityStatus() != MotilityStatus.NORMAL)
                .sorted(Comparator.comparing(s -> s.getCurrentMotility() != null ? s.getCurrentMotility() : BigDecimal.valueOf(999)))
                .map(s -> {
                    String code = livestockRepo.findById(s.getLivestockId())
                            .map(Livestock::getLivestockCode).orElse("?");
                    String breed = livestockRepo.findById(s.getLivestockId())
                            .map(Livestock::getBreed).orElse(null);
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
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElseThrow();
        Instant now = Instant.now();
        List<RumenMotilityLog> logs = motilityLogRepo.findByLivestockIdAndTimeRange(
                livestockId, now.minus(Duration.ofHours(24)), now);

        String code = livestockRepo.findById(livestockId).map(Livestock::getLivestockCode).orElse("?");

        List<MotilityReading> recent24h = logs.stream()
                .map(l -> new MotilityReading(l.getFrequency(), l.getIntensity(), l.getRecordedAt()))
                .toList();

        return new DigestiveDetail(
                String.valueOf(livestockId), code,
                snapshot.getMotilityBaseline(),
                snapshot.getMotilityStatus().name(),
                digestiveService.generateAdvice(snapshot.getMotilityStatus()),
                recent24h);
    }

    // ── Estrus ──────────────────────────────────────────────────

    public EstrusListResponse getEstrusList(Long farmId) {
        List<EstrusScore> scores = estrusScoreRepo.findByFarmIdOrderByScoredAtDesc(farmId);

        // Get latest score per livestock
        Map<Long, EstrusScore> latestPerLivestock = new LinkedHashMap<>();
        for (EstrusScore score : scores) {
            latestPerLivestock.putIfAbsent(score.getLivestockId(), score);
        }

        List<EstrusListItem> items = latestPerLivestock.values().stream()
                .filter(e -> e.getScore() > 0)
                .sorted(Comparator.comparingInt(EstrusScore::getScore).reversed())
                .map(e -> {
                    String code = livestockRepo.findById(e.getLivestockId())
                            .map(Livestock::getLivestockCode).orElse("?");
                    String breed = livestockRepo.findById(e.getLivestockId())
                            .map(Livestock::getBreed).orElse(null);
                    String gender = livestockRepo.findById(e.getLivestockId())
                            .map(Livestock::getGender).orElse(null);
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

        String code = livestockRepo.findById(livestockId).map(Livestock::getLivestockCode).orElse("?");

        List<EstrusTrendPoint> trend7d = scores.stream()
                .map(e -> new EstrusTrendPoint(e.getScore(), e.getScoredAt()))
                .toList();

        if (latest == null) {
            return new EstrusDetail(
                    String.valueOf(livestockId), code, 0, null, null, null,
                    null, estrusAnalysisService.generateAdvice(0), trend7d);
        }

        return new EstrusDetail(
                String.valueOf(livestockId), code,
                latest.getScore(), latest.getStepIncreasePercent(),
                latest.getTempDelta(), latest.getDistanceDelta(),
                latest.getScoredAt(), latest.getAdvice(),
                trend7d);
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
                        livestockRepo.findById(c.getFromLivestockId()).map(Livestock::getLivestockCode).orElse("?"),
                        String.valueOf(c.getToLivestockId()),
                        livestockRepo.findById(c.getToLivestockId()).map(Livestock::getLivestockCode).orElse("?"),
                        c.getProximityMeters(),
                        c.getLastContactAt()))
                .toList();

        HerdHealthMetrics dto = new HerdHealthMetrics(
                metrics.avgTemperature(), metrics.avgActivity(),
                metrics.abnormalRate(), metrics.totalLivestock(), metrics.abnormalCount());

        return new EpidemicResponse(dto, contactItems, riskLevel);
    }
}
