package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.DatagenFarmAccessService;
import com.smartlivestock.datagen.application.DatagenOperatorContext;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorBoundaryMetrics;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorDominantMetrics;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorEvaluationReport;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorEvaluationRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorEventMetrics;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorFacetMetrics;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorDominant;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFacet;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorDatasetJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorEpisodeJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorEpisodeSplitAssignmentJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorPredictionJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorWindowJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorWindowLabelJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorDatasetJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorPredictionJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowLabelJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BehaviorEvaluationService {
    private final DatagenFarmAccessService farmAccessService;
    private final BehaviorDatasetJpaRepository datasetRepository;
    private final BehaviorEpisodeJpaRepository episodeRepository;
    private final BehaviorEpisodeSplitAssignmentJpaRepository episodeSplitRepository;
    private final BehaviorWindowJpaRepository windowRepository;
    private final BehaviorWindowLabelJpaRepository labelRepository;
    private final BehaviorPredictionJpaRepository predictionRepository;

    @Transactional(readOnly = true)
    public BehaviorEvaluationReport evaluate(
            BehaviorEvaluationRequest request,
            DatagenOperatorContext operator) {
        if (request == null || request.datasetIds() == null || request.datasetIds().isEmpty()) {
            throw new ApiException(
                    ErrorCode.VALIDATION_ERROR,
                    "error.datagen.behaviorEvaluationRequestInvalid");
        }
        List<BehaviorDatasetJpaEntity> datasets = request.datasetIds().stream()
                .distinct()
                .map(datasetId -> datasetRepository.findById(datasetId)
                        .orElseThrow(() -> new ApiException(
                                ErrorCode.RESOURCE_NOT_FOUND,
                                "error.datagen.behaviorDatasetNotFound",
                                new Object[]{datasetId})))
                .toList();
        List<String> sources = datasets.stream()
                .map(BehaviorDatasetJpaEntity::getDataSource)
                .distinct()
                .toList();
        if (sources.size() > 1 && !request.allowMixedDebug()) {
            throw new ApiException(
                    ErrorCode.STATE_CONFLICT,
                    "error.datagen.behaviorMixedSource");
        }

        Map<UUID, BehaviorDatasetJpaEntity> datasetById = datasets.stream()
                .collect(Collectors.toMap(
                        BehaviorDatasetJpaEntity::getId,
                        dataset -> dataset,
                        (first, second) -> first,
                        LinkedHashMap::new));
        List<BehaviorEpisodeJpaEntity> episodes = datasets.stream()
                .flatMap(dataset -> episodeRepository
                        .findByDatasetIdOrderByStartAtAsc(dataset.getId())
                        .stream())
                .toList();
        episodes.stream().map(BehaviorEpisodeJpaEntity::getFarmId).distinct()
                .forEach(farmId -> farmAccessService.requireAccessibleFarm(farmId, operator));
        Map<UUID, String> episodeSplits = datasets.stream()
                .flatMap(dataset -> episodeSplitRepository
                        .findByIdDatasetId(dataset.getId())
                        .stream())
                .collect(Collectors.toMap(
                        assignment -> assignment.getId().getEpisodeId(),
                        assignment -> assignment.getDatasetSplit()));

        List<BehaviorWindowJpaEntity> selectedWindows = datasets.stream()
                .flatMap(dataset -> windowRepository
                        .findByDatasetIdOrderByWindowStartAsc(dataset.getId())
                        .stream())
                .filter(window -> splitMatches(request.datasetSplit(), episodeSplits.get(window.getEpisodeId())))
                .toList();
        List<BehaviorWindowLabelJpaEntity> labels = labelsFor(selectedWindows);
        Map<UUID, List<BehaviorWindowLabelJpaEntity>> labelsByWindow = labels.stream()
                .collect(Collectors.groupingBy(BehaviorWindowLabelJpaEntity::getWindowId));
        List<BehaviorPredictionJpaEntity> predictions = predictionsFor(selectedWindows);
        Map<UUID, BehaviorPredictionJpaEntity> predictionByWindow = predictions.stream()
                .collect(Collectors.groupingBy(
                        BehaviorPredictionJpaEntity::getWindowId,
                        Collectors.collectingAndThen(
                                Collectors.maxBy(this::latestPrediction),
                                Optional::get)));

        String state = selectedWindows.isEmpty()
                ? "NO_WINDOWS"
                : predictions.isEmpty() ? "NO_PREDICTIONS"
                : evaluatedWindowCount(selectedWindows, predictionByWindow) == selectedWindows.size()
                        ? "COMPLETE"
                        : "PARTIAL_PREDICTIONS";
        List<BehaviorWindowJpaEntity> evaluatedWindows = selectedWindows.stream()
                .filter(window -> predictionByWindow.containsKey(window.getId()))
                .toList();
        List<BehaviorFacetMetrics> facetMetrics = facetMetrics(
                selectedWindows, evaluatedWindows, labelsByWindow, predictionByWindow);
        return new BehaviorEvaluationReport(
                state,
                sources.contains("DATAGEN") ? "PIPELINE_ONLY" : "EVALUATION",
                request.allowMixedDebug() && sources.size() > 1,
                selectedWindows.size() - evaluatedWindows.size(),
                datasets.stream().map(BehaviorDatasetJpaEntity::getId).toList(),
                sources,
                datasets.stream().map(BehaviorDatasetJpaEntity::getGeneratorVersion).distinct().toList(),
                predictions.stream()
                        .map(prediction -> prediction.getModelName() + ":" + prediction.getModelVersion())
                        .distinct()
                        .toList(),
                countBy(selectedWindows, window -> datasetById.get(window.getDatasetId()).getDataSource()),
                countBy(selectedWindows, BehaviorWindowJpaEntity::getInputQuality),
                countBy(selectedWindows, window -> episodeSplits.getOrDefault(window.getEpisodeId(), "UNASSIGNED")),
                countBy(selectedWindows, window -> window.getDatasetId() + ":" + window.getLivestockId()),
                dominantMetrics(evaluatedWindows, predictionByWindow),
                facetMetrics,
                boundaryMetrics(evaluatedWindows, predictionByWindow),
                eventMetrics(evaluatedWindows, labelsByWindow, predictionByWindow));
    }

    private boolean splitMatches(String requested, String actual) {
        return requested == null || requested.isBlank() || "ALL".equals(requested)
                || requested.equals(actual);
    }

    private int evaluatedWindowCount(
            List<BehaviorWindowJpaEntity> windows,
            Map<UUID, BehaviorPredictionJpaEntity> predictions) {
        return (int) windows.stream()
                .filter(window -> predictions.containsKey(window.getId()))
                .count();
    }

    private int latestPrediction(
            BehaviorPredictionJpaEntity first,
            BehaviorPredictionJpaEntity second) {
        int byTime = first.getPredictedAt().compareTo(second.getPredictedAt());
        if (byTime != 0) {
            return byTime;
        }
        int byName = first.getModelName().compareTo(second.getModelName());
        if (byName != 0) {
            return byName;
        }
        return first.getModelVersion().compareTo(second.getModelVersion());
    }

    private BehaviorDominantMetrics dominantMetrics(
            List<BehaviorWindowJpaEntity> windows,
            Map<UUID, BehaviorPredictionJpaEntity> predictions) {
        Map<String, Map<String, Long>> confusion = new LinkedHashMap<>();
        for (BehaviorDominant actual : BehaviorDominant.values()) {
            Map<String, Long> row = new LinkedHashMap<>();
            for (BehaviorDominant predicted : BehaviorDominant.values()) {
                row.put(predicted.name(), 0L);
            }
            confusion.put(actual.name(), row);
        }
        long correct = 0;
        long top2Correct = 0;
        for (BehaviorWindowJpaEntity window : windows) {
            BehaviorPredictionJpaEntity prediction = predictions.get(window.getId());
            confusion.get(window.getDominantBehavior())
                    .merge(prediction.getPredictedDominantBehavior(), 1L, Long::sum);
            if (window.getDominantBehavior().equals(prediction.getPredictedDominantBehavior())) {
                correct++;
            }
            if (top2(prediction).contains(window.getDominantBehavior())) {
                top2Correct++;
            }
        }

        List<BehaviorDominantMetrics.BehaviorClassMetric> classMetrics = new ArrayList<>();
        double macroPrecision = 0;
        double macroRecall = 0;
        double macroF1 = 0;
        double weightedF1 = 0;
        long minSupport = Long.MAX_VALUE;
        long maxSupport = 0;
        for (BehaviorDominant label : BehaviorDominant.values()) {
            long support = windows.stream()
                    .filter(window -> window.getDominantBehavior().equals(label.name()))
                    .count();
            long predictedCount = windows.stream()
                    .filter(window -> predictions.get(window.getId())
                            .getPredictedDominantBehavior().equals(label.name()))
                    .count();
            long tp = confusion.get(label.name()).get(label.name());
            double precision = rate(tp, predictedCount);
            double recall = rate(tp, support);
            double f1 = f1(precision, recall);
            classMetrics.add(new BehaviorDominantMetrics.BehaviorClassMetric(
                    label.name(), support, predictedCount, precision, recall, f1));
            macroPrecision += precision;
            macroRecall += recall;
            macroF1 += f1;
            weightedF1 += support * f1;
            minSupport = Math.min(minSupport, support);
            maxSupport = Math.max(maxSupport, support);
        }
        int classCount = BehaviorDominant.values().length;
        long windowCount = windows.size();
        Map<String, Long> nearClass = new LinkedHashMap<>();
        nearClass.put("RUMINATING_AS_FEEDING",
                confusion.get(BehaviorDominant.RUMINATING.name()).get(BehaviorDominant.FEEDING.name()));
        nearClass.put("FEEDING_AS_RUMINATING",
                confusion.get(BehaviorDominant.FEEDING.name()).get(BehaviorDominant.RUMINATING.name()));
        return new BehaviorDominantMetrics(
                (int) windowCount,
                rate(correct, windowCount),
                rate(top2Correct, windowCount),
                macroPrecision / classCount,
                macroRecall / classCount,
                macroF1 / classCount,
                windowCount == 0 ? 0 : weightedF1 / windowCount,
                minSupport == Long.MAX_VALUE || minSupport == 0
                        ? maxSupport
                        : (double) maxSupport / minSupport,
                confusion,
                nearClass,
                classMetrics);
    }

    private List<BehaviorFacetMetrics> facetMetrics(
            List<BehaviorWindowJpaEntity> selectedWindows,
            List<BehaviorWindowJpaEntity> evaluatedWindows,
            Map<UUID, List<BehaviorWindowLabelJpaEntity>> labelsByWindow,
            Map<UUID, BehaviorPredictionJpaEntity> predictions) {
        List<BehaviorFacetMetrics> result = new ArrayList<>();
        for (BehaviorFacet facet : BehaviorFacet.values()) {
            Map<UUID, Set<String>> actualByWindow = new LinkedHashMap<>();
            for (BehaviorWindowJpaEntity window : selectedWindows) {
                Set<String> values = labelsByWindow.getOrDefault(window.getId(), List.of()).stream()
                        .filter(label -> label.getFacet().equals(facet.name()))
                        .map(BehaviorWindowLabelJpaEntity::getLabelValue)
                        .collect(Collectors.toCollection(LinkedHashSet::new));
                actualByWindow.put(window.getId(), values);
            }
            List<BehaviorFacetMetrics.BehaviorFacetLabelMetric> labelMetrics = new ArrayList<>();
            long mismatches = 0;
            long comparable = 0;
            for (BehaviorLabelValue labelValue : facet.allowedValues()) {
                long tp = 0;
                long fp = 0;
                long fn = 0;
                long tn = 0;
                long support = 0;
                for (BehaviorWindowJpaEntity window : evaluatedWindows) {
                    Set<String> actual = actualByWindow.get(window.getId());
                    if (actual.isEmpty()) {
                        continue;
                    }
                    Set<String> predicted = predictedLabels(
                            predictions.get(window.getId()), facet);
                    boolean actualPositive = actual.contains(labelValue.name());
                    boolean predictedPositive = predicted.contains(labelValue.name());
                    if (actualPositive) support++;
                    if (actualPositive && predictedPositive) tp++;
                    else if (!actualPositive && predictedPositive) fp++;
                    else if (actualPositive) fn++;
                    else tn++;
                }
                double precision = rate(tp, tp + fp);
                double recall = rate(tp, tp + fn);
                labelMetrics.add(new BehaviorFacetMetrics.BehaviorFacetLabelMetric(
                        labelValue.name(), tp, fp, fn, tn, support,
                        precision, recall, f1(precision, recall)));
            }
            for (BehaviorWindowJpaEntity window : evaluatedWindows) {
                Set<String> actual = actualByWindow.get(window.getId());
                if (actual.isEmpty()) continue;
                Set<String> predicted = predictedLabels(predictions.get(window.getId()), facet);
                long symmetricDifference = new LinkedHashSet<>(actual) {{
                    addAll(predicted);
                    removeAll(actual.stream().filter(predicted::contains).toList());
                }}.size();
                mismatches += symmetricDifference;
                comparable += facet.allowedValues().size();
            }
            int missing = (int) selectedWindows.stream()
                    .filter(window -> actualByWindow.get(window.getId()).isEmpty())
                    .count();
            result.add(new BehaviorFacetMetrics(
                    facet.name(),
                    comparable == 0 ? 0 : (double) mismatches / comparable,
                    missing,
                    labelMetrics));
        }
        return result;
    }

    private BehaviorBoundaryMetrics boundaryMetrics(
            List<BehaviorWindowJpaEntity> windows,
            Map<UUID, BehaviorPredictionJpaEntity> predictions) {
        long groundTruth = 0;
        long predicted = 0;
        long matched = 0;
        for (List<BehaviorWindowJpaEntity> sequence : sequences(windows)) {
            List<Integer> truthIndexes = new ArrayList<>();
            List<Integer> predictedIndexes = new ArrayList<>();
            for (int i = 1; i < sequence.size(); i++) {
                if (!sequence.get(i - 1).getDominantBehavior()
                        .equals(sequence.get(i).getDominantBehavior())) {
                    truthIndexes.add(i);
                }
                String previous = predictions.get(sequence.get(i - 1).getId())
                        .getPredictedDominantBehavior();
                String current = predictions.get(sequence.get(i).getId())
                        .getPredictedDominantBehavior();
                if (!previous.equals(current)) predictedIndexes.add(i);
            }
            groundTruth += truthIndexes.size();
            predicted += predictedIndexes.size();
            for (int truthIndex : truthIndexes) {
                for (int candidateIndex : predictedIndexes) {
                    if (Math.abs(candidateIndex - truthIndex) <= 1) {
                        matched++;
                        break;
                    }
                }
            }
        }
        double precision = rate(matched, predicted);
        double recall = rate(matched, groundTruth);
        return new BehaviorBoundaryMetrics(
                groundTruth, predicted, matched, precision, recall, f1(precision, recall));
    }

    private BehaviorEventMetrics eventMetrics(
            List<BehaviorWindowJpaEntity> windows,
            Map<UUID, List<BehaviorWindowLabelJpaEntity>> labelsByWindow,
            Map<UUID, BehaviorPredictionJpaEntity> predictions) {
        long groundTruth = 0;
        long predicted = 0;
        long matched = 0;
        long missed = 0;
        List<Long> latencies = new ArrayList<>();
        for (List<BehaviorWindowJpaEntity> sequence : sequences(windows)) {
            List<EventInterval> truthEvents = eventIntervals(sequence, window -> {
                List<BehaviorWindowLabelJpaEntity> labels = labelsByWindow.getOrDefault(
                        window.getId(), List.of());
                return labels.stream().anyMatch(label ->
                        label.getFacet().equals(BehaviorFacet.EVENT.name())
                                && !label.getLabelValue().equals("NONE"));
            });
            List<EventInterval> predictedEvents = eventIntervals(sequence, window -> {
                Set<String> values = predictedLabels(
                        predictions.get(window.getId()), BehaviorFacet.EVENT);
                return values.stream().anyMatch(value -> !value.equals("NONE"));
            });
            groundTruth += truthEvents.size();
            predicted += predictedEvents.size();
            for (EventInterval truth : truthEvents) {
                EventInterval match = predictedEvents.stream()
                        .filter(candidate -> overlapsOrAdjacent(candidate, truth))
                        .findFirst()
                        .orElse(null);
                if (match == null) {
                    missed++;
                } else {
                    matched++;
                    latencies.add(Duration.between(truth.startAt(), match.startAt()).toSeconds() / 300);
                }
            }
        }
        double precision = rate(matched, predicted);
        double recall = rate(matched, groundTruth);
        return new BehaviorEventMetrics(
                groundTruth, predicted, matched, precision, recall, f1(precision, recall),
                latencies, missed);
    }

    private Collection<List<BehaviorWindowJpaEntity>> sequences(List<BehaviorWindowJpaEntity> windows) {
        return windows.stream()
                .collect(Collectors.groupingBy(
                        window -> window.getDatasetId() + ":" + window.getDeviceId(),
                        LinkedHashMap::new,
                        Collectors.collectingAndThen(
                                Collectors.toList(),
                                list -> {
                                    list.sort(Comparator.comparing(BehaviorWindowJpaEntity::getWindowStart));
                                    return list;
                                })))
                .values();
    }

    private List<EventInterval> eventIntervals(
            List<BehaviorWindowJpaEntity> sequence,
            java.util.function.Predicate<BehaviorWindowJpaEntity> positive) {
        List<EventInterval> events = new ArrayList<>();
        int start = -1;
        for (int i = 0; i < sequence.size(); i++) {
            if (positive.test(sequence.get(i))) {
                if (start < 0) start = i;
            } else if (start >= 0) {
                events.add(new EventInterval(
                        sequence.get(start).getWindowStart(),
                        sequence.get(i - 1).getWindowEnd()));
                start = -1;
            }
        }
        if (start >= 0) {
            events.add(new EventInterval(
                    sequence.get(start).getWindowStart(),
                    sequence.get(sequence.size() - 1).getWindowEnd()));
        }
        return events;
    }

    private boolean overlapsOrAdjacent(EventInterval first, EventInterval second) {
        return !first.startAt().isAfter(second.endAt().plusSeconds(300))
                && !second.startAt().isAfter(first.endAt().plusSeconds(300));
    }

    private Set<String> top2(BehaviorPredictionJpaEntity prediction) {
        return prediction.getProbabilityVector().entrySet().stream()
                .sorted((first, second) -> Double.compare(
                        ((Number) second.getValue()).doubleValue(),
                        ((Number) first.getValue()).doubleValue()))
                .limit(2)
                .map(Map.Entry::getKey)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private Set<String> predictedLabels(
            BehaviorPredictionJpaEntity prediction,
            BehaviorFacet facet) {
        Object value = prediction.getPredictedLabels().get(facet.name());
        if (value == null) return Set.of();
        if (value instanceof Collection<?> collection) {
            return collection.stream().map(Object::toString).collect(Collectors.toSet());
        }
        return Set.of(value.toString());
    }

    private <T> Map<String, Long> countBy(
            List<BehaviorWindowJpaEntity> windows,
            java.util.function.Function<BehaviorWindowJpaEntity, String> classifier) {
        return windows.stream().collect(Collectors.groupingBy(
                classifier, LinkedHashMap::new, Collectors.counting()));
    }

    private List<BehaviorWindowLabelJpaEntity> labelsFor(
            List<BehaviorWindowJpaEntity> windows) {
        if (windows.isEmpty()) return List.of();
        return labelRepository.findByWindowIdIn(windows.stream()
                .map(BehaviorWindowJpaEntity::getId)
                .toList());
    }

    private List<BehaviorPredictionJpaEntity> predictionsFor(
            List<BehaviorWindowJpaEntity> windows) {
        if (windows.isEmpty()) return List.of();
        return predictionRepository.findByWindowIdIn(windows.stream()
                .map(BehaviorWindowJpaEntity::getId)
                .toList());
    }

    private double rate(long numerator, long denominator) {
        return denominator == 0 ? 0 : (double) numerator / denominator;
    }

    private double f1(double precision, double recall) {
        return precision + recall == 0 ? 0 : 2 * precision * recall / (precision + recall);
    }

    private record EventInterval(Instant startAt, Instant endAt) {
    }
}
