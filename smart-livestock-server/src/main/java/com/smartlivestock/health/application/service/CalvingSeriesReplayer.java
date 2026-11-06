package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.service.CalvingPredictionService;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ActivitySample;
import com.smartlivestock.health.domain.service.CalvingPredictionService.AlertTransition;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ExclusionWindow;
import com.smartlivestock.health.domain.service.CalvingPredictionService.TempSample;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Reusable same-input calving-risk replayer (NIX-381 Task 4): ONE event-time
 * telemetry sequence is pushed through the production evaluation semantics —
 * the pure {@link CalvingPredictionService} kernel for the channel features
 * and the score, and the shared {@link AlertTransition} state machine for the
 * alert episodes — minus every write. The mirroring counterpart of
 * {@link EstrusSeriesReplayer} with one deliberate structural difference:
 * calving scoring consumes NO baseline (the features compare the animal
 * against its own same-phase reference windows), so there is a single side —
 * no DEFAULT/LEARNED dual replay.
 *
 * <h2>Replay cadence — the production poll grid</h2>
 * Evaluations happen at fixed grid points {@code now − k × pollMs}
 * (k = 0, 1, …, down to the earliest visible input instant), NOT at every
 * sample: the {@code alertPersistencePoints = 2} "consecutive evaluations"
 * semantics only mean something when the evaluation rhythm matches the
 * production scheduler ({@code smartlivestock.calving.poll-ms}, default 1h).
 * A denser cadence can fabricate a persistence raise from two high scores
 * that production would never observe back to back — the unit tests lock
 * that difference. {@code now} itself is always the final grid point (the
 * evaluation baseline).
 *
 * <h2>Event-time visibility (no look-ahead)</h2>
 * At grid point {@code t} only inputs stamped at or before {@code t} are
 * visible: samples with {@code at ≤ t}, drinking windows with
 * {@code start ≤ t} (belt-and-braces — a not-yet-started window could only
 * exclude samples after t, and the kernel's own half-open windows ignore
 * samples at/after the evaluation instant anyway). Samples after {@code now}
 * therefore never influence any point.
 *
 * <h2>Drinking exclusion</h2>
 * The caller passes RAW event windows {@code (eventStart, trough)}; the
 * replayer applies the production buffer rule itself (identical to
 * {@code CalvingPredictionService} orchestration):
 * {@code [eventStart, max(eventStart, trough) + drinkingExclusionBufferMinutes)} —
 * an inverted row (trough before start) is clipped to its start. Exclusion
 * applies to the temperature channel only; the activity series stays raw.
 *
 * <p>{@code breedingAtOrNull} feeds the breeding prior exactly like the
 * production gestation read: per grid point {@code gestationDays =
 * DAYS.between(breedingAt, t)}, null when {@code t} predates the breeding or
 * the gestation exceeds {@code MAX_GESTATION_DAYS} (400d). The simulation
 * evaluation's "record available" scenario passes a synthetic breeding
 * instant (true calving − 283d); passing null replays the no-record scenario.</p>
 */
@Service
public class CalvingSeriesReplayer {

    private final CalvingPredictionService kernel;
    private final CalvingPredictionProperties properties;

    public CalvingSeriesReplayer(CalvingPredictionService kernel, CalvingPredictionProperties properties) {
        this.kernel = kernel;
        this.properties = properties;
    }

    // ------------------------------------------------------------------
    // Result contracts
    // ------------------------------------------------------------------

    /** One grid-point evaluation: score plus the features that produced it. */
    public record ScorePoint(Instant at, int score, BigDecimal tempDrop, BigDecimal activityRatio,
                             boolean reboundDetected) {
    }

    /**
     * One raise→release alert episode. {@code raiseAt} is the grid point
     * where the shared state machine raised; {@code releaseAt} the grid point
     * where it released, null when the replay ended with the ticket still
     * active. {@code livestockId} is stamped by the caller for per-head
     * alignment (null on the anonymous overload).
     */
    public record AlertEpisode(Long livestockId, Instant raiseAt, Instant releaseAt) {
    }

    /** Outcome of one replay pass. */
    public record CalvingReplayResult(List<ScorePoint> points, List<AlertEpisode> episodes,
                                      Integer lastScore, BigDecimal lastTempDrop, BigDecimal lastActivityRatio,
                                      int tempChannelAvailablePoints, int totalPoints) {
    }

    // ------------------------------------------------------------------
    // Replay
    // ------------------------------------------------------------------

    /**
     * Replays the sequence through the production kernel and state machine.
     * Inputs may arrive in any order: they are filtered (null timestamps or
     * values dropped) and sorted ascending first, which makes the grid and
     * cursor walk order-independent and idempotent for already-sorted input.
     */
    public CalvingReplayResult replay(Long livestockId,
                                      List<TempSample> temps, List<ActivitySample> acts,
                                      List<ExclusionWindow> drinkingWindows,
                                      Instant breedingAtOrNull, Instant now) {
        List<TempSample> tempsAsc = temps == null ? List.of() : temps.stream()
                .filter(s -> s != null && s.at() != null && s.celsius() != null)
                .sorted(Comparator.comparing(TempSample::at))
                .toList();
        List<ActivitySample> actsAsc = acts == null ? List.of() : acts.stream()
                .filter(s -> s != null && s.at() != null && s.activityIndex() != null)
                .sorted(Comparator.comparing(ActivitySample::at))
                .toList();

        CalvingPredictionProperties p = properties;
        Duration poll = Duration.ofMillis(p.getPollMs());
        Duration buffer = Duration.ofMinutes(p.getDrinkingExclusionBufferMinutes());

        // Buffered exclusion windows, production rule verbatim (orchestration
        // drinkingExclusionWindows): [start, max(start, trough) + buffer).
        List<ExclusionWindow> windows = drinkingWindows == null ? List.of() : drinkingWindows.stream()
                .filter(w -> w != null && w.start() != null)
                .map(w -> {
                    Instant trough = w.end();
                    Instant end = trough == null || trough.isBefore(w.start()) ? w.start() : trough;
                    return new ExclusionWindow(w.start(), end.plus(buffer));
                })
                .toList();

        // Grid: fixed poll cadence anchored at now (the evaluation baseline),
        // down to the earliest visible input instant. A series that ends
        // before now still fills the gap with quiet points — the production
        // scheduler would have evaluated those instants the same way.
        Instant earliest = earliestInstant(tempsAsc, actsAsc);
        List<ScorePoint> points = new ArrayList<>();
        List<AlertEpisode> episodes = new ArrayList<>();
        int tempAvailable = 0;
        int total = 0;

        if (earliest != null && !earliest.isAfter(now)) {
            long steps = Duration.between(earliest, now).dividedBy(poll);

            // State-machine memory = the snapshot column discipline: prev is
            // the in-memory column value (null = cleared/released), the
            // ticket flag follows raise/release exactly like the bridge.
            Integer prevColumn = null;
            boolean hasActiveTicket = false;
            Instant openRaise = null;

            int tempCursor = 0;
            int actCursor = 0;
            int winCursor = 0;
            for (long k = steps; k >= 0; k--) {
                Instant t = now.minus(poll.multipliedBy(k));
                // Visibility: inputs stamped at or before t only (cursors over
                // the ascending lists give the visible prefixes).
                while (tempCursor < tempsAsc.size() && !tempsAsc.get(tempCursor).at().isAfter(t)) {
                    tempCursor++;
                }
                while (actCursor < actsAsc.size() && !actsAsc.get(actCursor).at().isAfter(t)) {
                    actCursor++;
                }
                while (winCursor < windows.size() && !windows.get(winCursor).start().isAfter(t)) {
                    winCursor++;
                }
                List<TempSample> visibleTemps = tempsAsc.subList(0, tempCursor);
                List<ActivitySample> visibleActs = actsAsc.subList(0, actCursor);
                List<ExclusionWindow> visibleWindows = windows.subList(0, winCursor);

                // Drinking exclusion applies to the temperature channel only
                // (production rule); activity stays raw.
                List<TempSample> cleanTemps = CalvingPredictionService.excludeWindows(visibleTemps, visibleWindows);
                BigDecimal tempDrop = kernel.computeTempDrop(cleanTemps, t, p);
                BigDecimal activityRatio = kernel.computeActivityRatio(visibleActs, t, p);
                boolean rebound = kernel.isReboundDetected(cleanTemps, t, p);
                int score = kernel.score(tempDrop, activityRatio,
                        gestationDaysAt(t, breedingAtOrNull), rebound, p);

                points.add(new ScorePoint(t, score, tempDrop, activityRatio, rebound));
                total++;
                if (tempDrop != null) {
                    tempAvailable++;
                }

                // Shared production state machine — same function the
                // orchestration commits with (Task 4 extraction, the whole
                // point of the replayer).
                AlertTransition transition = kernel.transition(prevColumn, score, hasActiveTicket, p);
                if (transition.raise()) {
                    openRaise = t;
                }
                if (transition.release()) {
                    episodes.add(new AlertEpisode(livestockId, openRaise, t));
                    openRaise = null;
                }
                hasActiveTicket = hasActiveTicket ? !transition.release() : transition.raise();
                prevColumn = transition.newColumnValue();
            }
            if (openRaise != null) {
                // Replay ended with the ticket still active: releaseAt null.
                episodes.add(new AlertEpisode(livestockId, openRaise, null));
            }
        }

        ScorePoint last = points.isEmpty() ? null : points.get(points.size() - 1);
        return new CalvingReplayResult(List.copyOf(points), List.copyOf(episodes),
                last == null ? null : last.score(),
                last == null ? null : last.tempDrop(),
                last == null ? null : last.activityRatio(),
                tempAvailable, total);
    }

    /** Anonymous variant of {@link #replay} (no livestock stamp). */
    public CalvingReplayResult replay(List<TempSample> temps, List<ActivitySample> acts,
                                      List<ExclusionWindow> drinkingWindows,
                                      Instant breedingAtOrNull, Instant now) {
        return replay(null, temps, acts, drinkingWindows, breedingAtOrNull, now);
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------

    /** Earliest visible input instant (grid start); null for an empty series. */
    private static Instant earliestInstant(List<TempSample> tempsAsc, List<ActivitySample> actsAsc) {
        Instant earliest = null;
        if (!tempsAsc.isEmpty()) {
            earliest = tempsAsc.get(0).at();
        }
        if (!actsAsc.isEmpty() && (earliest == null || actsAsc.get(0).at().isBefore(earliest))) {
            earliest = actsAsc.get(0).at();
        }
        return earliest;
    }

    /**
     * Production gestation read semantics, per grid point: null when there is
     * no breeding record, when the evaluation instant predates it (a future
     * record is ignored) or when the gestation exceeds the 400-day horizon
     * (same constant as the orchestration service — it no longer describes
     * the current gestation).
     */
    private static Integer gestationDaysAt(Instant t, Instant breedingAt) {
        if (breedingAt == null || t.isBefore(breedingAt)) {
            return null;
        }
        long days = ChronoUnit.DAYS.between(breedingAt, t);
        return days > CalvingPredictionApplicationService.MAX_GESTATION_DAYS ? null : (int) days;
    }
}
