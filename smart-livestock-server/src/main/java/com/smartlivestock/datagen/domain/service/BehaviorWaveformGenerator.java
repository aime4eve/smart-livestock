package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorDominant;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeature;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorRealismProfile;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Random;

public class BehaviorWaveformGenerator {
    public static final int SAMPLING_RATE_HZ = 25;
    public static final int WINDOW_SECONDS = 300;
    public static final int EXPECTED_SAMPLES = SAMPLING_RATE_HZ * WINDOW_SECONDS;

    private final BehaviorFeatureValidator featureValidator;

    public BehaviorWaveformGenerator(BehaviorFeatureValidator featureValidator) {
        this.featureValidator = featureValidator;
    }

    public BehaviorFeature generateMissing() {
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("sample_count", 0);
        values.put("expected_sample_count", EXPECTED_SAMPLES);
        values.put("missing_feature_mask", (1 << 25) - 1);
        return featureValidator.validate(
                BehaviorFeatureContract.v1(), values, InputQuality.UNKNOWN);
    }

    public BehaviorFeature generate(
            BehaviorScenarioDefinition scenario,
            BehaviorSubject subject,
            BehaviorDominant dominant,
            BehaviorLabelValue event,
            Random random) {
        BehaviorRealismProfile profile = scenario.realismProfile();
        int droppedSamples = (int) Math.round(
                EXPECTED_SAMPLES * profile.sampleDropoutRate() * random.nextDouble());
        int sampleCount = EXPECTED_SAMPLES - droppedSamples;

        double sumX = 0;
        double sumY = 0;
        double sumZ = 0;
        double squareX = 0;
        double squareY = 0;
        double squareZ = 0;
        double sumRoll = 0;
        double squareRoll = 0;
        double sumPitch = 0;
        double squarePitch = 0;
        int rest = 0;
        int light = 0;
        int active = 0;
        int intense = 0;
        int zeroCrossings = 0;
        int burstCount = 0;
        boolean previousAbove = false;
        double previousDynamicX = 0;
        double previousZeroTime = -1;
        double intervalSum = 0;
        double intervalSquareSum = 0;
        int intervalCount = 0;
        double currentBurstStart = -1;
        double currentBurstEnd = -1;
        double nextBurstStart = 0;

        for (int i = 0; i < sampleCount; i++) {
            double time = i / (double) SAMPLING_RATE_HZ;
            double roll = subject.baselineRollDegrees() + rollOffset(dominant);
            double pitch = subject.baselinePitchDegrees() + pitchOffset(dominant);
            double dynamicX;
            double dynamicY = 0;

            switch (dominant) {
                case RUMINATING -> dynamicX = 0.04 * Math.sin(2 * Math.PI * 1.25 * time);
                case FEEDING -> {
                    if (time >= nextBurstStart) {
                        currentBurstStart = nextBurstStart;
                        currentBurstEnd = currentBurstStart + 0.15 + random.nextDouble() * 0.35;
                        nextBurstStart = currentBurstEnd + 0.10 + random.nextDouble() * 0.35;
                    }
                    boolean biting = time >= currentBurstStart && time < currentBurstEnd;
                    dynamicX = biting
                            ? 0.09 * Math.sin(2 * Math.PI * 2.2 * time)
                            : 0.0;
                    dynamicY = biting ? 0.025 * Math.cos(2 * Math.PI * 1.7 * time) : 0.0;
                }
                case WALKING -> {
                    dynamicX = 0.10 * Math.sin(2 * Math.PI * 2.0 * time);
                    dynamicY = 0.035 * Math.sin(2 * Math.PI * 1.9 * time + 0.4);
                }
                case OTHER -> {
                    dynamicX = 0.025 * Math.sin(2 * Math.PI * 0.7 * time);
                    dynamicY = 0.012 * Math.sin(2 * Math.PI * 0.4 * time);
                }
                default -> dynamicX = 0.0;
            }

            dynamicX += random.nextGaussian() * profile.noiseStdDevG();
            dynamicY += random.nextGaussian() * profile.noiseStdDevG();
            double dynamicZ = random.nextGaussian() * profile.noiseStdDevG();
            double rollRadians = Math.toRadians(roll);
            double pitchRadians = Math.toRadians(pitch);
            double x = Math.sin(rollRadians) + dynamicX;
            double y = Math.sin(pitchRadians) + dynamicY;
            double z = Math.cos(rollRadians) * Math.cos(pitchRadians) + dynamicZ;

            sumX += x;
            sumY += y;
            sumZ += z;
            squareX += x * x;
            squareY += y * y;
            squareZ += z * z;
            sumRoll += roll;
            squareRoll += roll * roll;
            sumPitch += pitch;
            squarePitch += pitch * pitch;

            double dynamicMagnitude = Math.sqrt(
                    dynamicX * dynamicX + dynamicY * dynamicY + dynamicZ * dynamicZ);
            if (dynamicMagnitude < 0.04) {
                rest++;
            } else if (dynamicMagnitude < 0.10) {
                light++;
            } else if (dynamicMagnitude < 0.25) {
                active++;
            } else {
                intense++;
            }

            boolean above = dynamicMagnitude >= 0.04;
            if (above && !previousAbove) burstCount++;
            previousAbove = above;

            if (i > 0 && (previousDynamicX < 0 && dynamicX >= 0
                    || previousDynamicX > 0 && dynamicX <= 0)) {
                zeroCrossings++;
                if (previousZeroTime >= 0) {
                    double interval = time - previousZeroTime;
                    intervalSum += interval;
                    intervalSquareSum += interval * interval;
                    intervalCount++;
                }
                previousZeroTime = time;
            }
            previousDynamicX = dynamicX;
        }

        double duration = sampleCount / (double) SAMPLING_RATE_HZ;
        double meanX = sumX / sampleCount;
        double meanY = sumY / sampleCount;
        double meanZ = sumZ / sampleCount;
        double meanRoll = sumRoll / sampleCount;
        double meanPitch = sumPitch / sampleCount;
        double dominantFrequency = duration > 0 ? zeroCrossings / (2 * duration) : 0;
        double dynamicVariance = dominant == BehaviorDominant.LYING
                ? profile.noiseStdDevG() * profile.noiseStdDevG()
                : dynamicAmplitudeSquared(dominant) + profile.noiseStdDevG() * profile.noiseStdDevG();
        double powerRatio = dynamicVariance == 0 ? 0
                : dynamicVariance / (dynamicVariance + 0.0004);
        double intervalMean = intervalCount == 0 ? 0 : intervalSum / intervalCount;
        double intervalVariance = intervalCount == 0 ? 0
                : Math.max(0, intervalSquareSum / intervalCount - intervalMean * intervalMean);
        double intervalCv = intervalMean == 0 ? 0 : Math.sqrt(intervalVariance) / intervalMean;
        double spectralEntropy = Math.min(1.0, intervalCv);
        double speed = switch (dominant) {
            case FEEDING -> 0.05;
            case WALKING -> 0.8;
            case OTHER -> 0.1;
            default -> 0.0;
        };
        int stepCount = switch (dominant) {
            case FEEDING -> 5;
            case WALKING -> 600;
            case OTHER -> 20;
            default -> 0;
        };
        int postureTransitions = switch (dominant) {
            case FEEDING -> 2;
            case WALKING -> 3;
            case OTHER -> 1;
            default -> 0;
        } + (event == BehaviorLabelValue.CALVING_RISK ? 8 : 0);

        Map<String, Object> values = new LinkedHashMap<>();
        values.put("sample_count", sampleCount);
        values.put("expected_sample_count", EXPECTED_SAMPLES);
        values.put("missing_feature_mask", 0);
        values.put("accel_mean_x", meanX);
        values.put("accel_mean_y", meanY);
        values.put("accel_mean_z", meanZ);
        values.put("accel_std_x", std(sumX, squareX, sampleCount));
        values.put("accel_std_y", std(sumY, squareY, sampleCount));
        values.put("accel_std_z", std(sumZ, squareZ, sampleCount));
        values.put("roll_mean", meanRoll);
        values.put("roll_std", std(sumRoll, squareRoll, sampleCount));
        values.put("pitch_mean", meanPitch);
        values.put("pitch_std", std(sumPitch, squarePitch, sampleCount));
        values.put("dominant_freq_hz", dominantFrequency);
        values.put("spectral_power_ratio", powerRatio);
        values.put("spectral_entropy", spectralEntropy);
        values.put("burst_count", burstCount);
        values.put("zero_crossing_rate", sampleCount > 1 ? zeroCrossings / (double) (sampleCount - 1) : 0);
        values.put("step_count", stepCount);
        values.put("distance_meters", speed * WINDOW_SECONDS);
        values.put("mean_speed_mps", speed);
        values.put("activity_class_counts.rest", rest);
        values.put("activity_class_counts.light", light);
        values.put("activity_class_counts.active", active);
        values.put("activity_class_counts.intense", intense);
        values.put("capsule_motility_mean", capsuleMean(subject, dominant));
        values.put("capsule_motility_std", Math.max(0.1, subject.capsuleMotilityBaseline() * 0.1));
        values.put("posture_transition_count", postureTransitions);
        return featureValidator.validate(
                BehaviorFeatureContract.v1(), values, InputQuality.FULL_0X40);
    }

    private double rollOffset(BehaviorDominant dominant) {
        return dominant == BehaviorDominant.LYING ? 65 : dominant == BehaviorDominant.RUMINATING ? 8 : 0;
    }

    private double pitchOffset(BehaviorDominant dominant) {
        return dominant == BehaviorDominant.FEEDING ? 28 : 0;
    }

    private double dynamicAmplitudeSquared(BehaviorDominant dominant) {
        return switch (dominant) {
            case RUMINATING -> 0.002;
            case FEEDING -> 0.008;
            case WALKING -> 0.011;
            case OTHER -> 0.0006;
            case LYING -> 0;
        };
    }

    private double capsuleMean(BehaviorSubject subject, BehaviorDominant dominant) {
        double baseline = subject.capsuleMotilityBaseline();
        return switch (dominant) {
            case RUMINATING -> baseline * 0.8;
            case FEEDING -> baseline * 1.1;
            case WALKING -> baseline * 1.05;
            case OTHER -> baseline;
            case LYING -> baseline * 0.7;
        };
    }

    private double std(double sum, double squareSum, int count) {
        if (count == 0) {
            return 0;
        }
        double mean = sum / count;
        return Math.sqrt(Math.max(0, squareSum / count - mean * mean));
    }
}
