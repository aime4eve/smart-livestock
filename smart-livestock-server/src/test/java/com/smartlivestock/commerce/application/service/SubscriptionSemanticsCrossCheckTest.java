package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.identity.application.SubscriptionExportPolicy;
import com.smartlivestock.identity.application.TenantSubscriptionResolver;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * NIX-324 Task 1 mechanical cross-check: the SAME state samples are fed to
 * the three consumers of termination semantics — SubscriptionHealthEvaluator
 * (this feature), TenantSubscriptionResolver (NIX-323 request context) and
 * SubscriptionExportPolicy (NIX-325 export channel) — and their verdicts are
 * asserted consistent: evaluator.degraded == resolver tier fallback to
 * basic, and evaluator.terminatedAt present == policy eligible (inside the
 * window). Any divergence is a design break, not a test flake.
 */
@ExtendWith(MockitoExtension.class)
class SubscriptionSemanticsCrossCheckTest {

    private static final Long TENANT_ID = 42L;
    private static final Instant NOW = Instant.parse("2026-10-27T00:00:00Z");
    private static final long WINDOW_DAYS = 30;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    private record Sample(String name, Subscription subscription) {}

    private static Subscription activeExpiringAt(Instant end) {
        Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                NOW.minusSeconds(120 * 24 * 3600), NOW);
        sub.activate(SubscriptionTier.PREMIUM, "monthly", end);
        return sub;
    }

    /** One sample per matrix state + boundary cases, all as (name, subscription). */
    private static Stream<Sample> samples() {
        Subscription trialActive = Subscription.startTrial(TENANT_ID, "direct",
                NOW.minusSeconds(5 * 24 * 3600), NOW.plusSeconds(20 * 24 * 3600));
        Subscription trialLapsed = Subscription.startTrial(TENANT_ID, "direct",
                NOW.minusSeconds(50 * 24 * 3600), NOW.minusSeconds(10 * 24 * 3600));
        Subscription freeLapsed = Subscription.startTrial(TENANT_ID, "direct",
                NOW.minusSeconds(50 * 24 * 3600), NOW.minusSeconds(10 * 24 * 3600));
        freeLapsed.expireTrial();
        Subscription expired = activeExpiringAt(NOW.minusSeconds(10 * 24 * 3600));
        expired.markExpired();
        Subscription cancelled = activeExpiringAt(NOW.plusSeconds(300 * 24 * 3600));
        cancelled.cancel(NOW.minusSeconds(5 * 24 * 3600));
        Subscription activeLapsed = activeExpiringAt(NOW.minusSeconds(2 * 24 * 3600));
        Subscription renewalFailed = activeExpiringAt(NOW.plusSeconds(10 * 24 * 3600));
        renewalFailed.markRenewalFailed();
        Subscription suspended = activeExpiringAt(NOW.plusSeconds(10 * 24 * 3600));
        suspended.suspend();
        Subscription expiringSoon = activeExpiringAt(NOW.plusSeconds(5 * 24 * 3600));
        Subscription healthy = activeExpiringAt(NOW.plusSeconds(90 * 24 * 3600));

        return Stream.of(
                new Sample("trial-active", trialActive),
                new Sample("trial-lapsed", trialLapsed),
                new Sample("free-lapsed", freeLapsed),
                new Sample("expired-status", expired),
                new Sample("cancelled", cancelled),
                new Sample("active-lapsed", activeLapsed),
                new Sample("renewal-failed", renewalFailed),
                new Sample("suspended", suspended),
                new Sample("expiring-soon", expiringSoon),
                new Sample("healthy", healthy));
    }

    @Nested
    class EvaluatorMatrix {

        @Test
        void everySampleLandsOnItsMatrixState() {
            var evaluator = new SubscriptionHealthEvaluator(new TerminationAnchorResolver());
            samples().forEach(sample -> {
                var verdict = evaluator.evaluate(sample.subscription(), NOW);
                String expected = switch (sample.name()) {
                    case "trial-active" -> "TRIAL";
                    case "trial-lapsed", "free-lapsed", "expired-status", "active-lapsed" -> "EXPIRED";
                    case "cancelled" -> "CANCELLED";
                    case "renewal-failed" -> "RENEWAL_FAILED";
                    case "suspended" -> "SUSPENDED";
                    case "expiring-soon" -> "EXPIRING_SOON";
                    default -> "HEALTHY";
                };
                assertThat(verdict.healthStatus().name())
                        .as("sample %s", sample.name())
                        .isEqualTo(expected);
            });
        }

        @Test
        void trialLapsedDoesNotShowAsTrial() {
            var evaluator = new SubscriptionHealthEvaluator(new TerminationAnchorResolver());
            Subscription trialLapsed = Subscription.startTrial(TENANT_ID, "direct",
                    NOW.minusSeconds(50 * 24 * 3600), NOW.minusSeconds(10 * 24 * 3600));
            var verdict = evaluator.evaluate(trialLapsed, NOW);
            assertThat(verdict.trialActive()).isFalse();
            assertThat(verdict.healthStatus()).isEqualTo(
                    com.smartlivestock.commerce.application.service.SubscriptionHealthEvaluator.HealthStatus.EXPIRED);
        }

        @Test
        void expiringSoonLevels() {
            var evaluator = new SubscriptionHealthEvaluator(new TerminationAnchorResolver());
            assertThat(evaluator.evaluate(activeExpiringAt(NOW.plusSeconds(10 * 24 * 3600)), NOW).level()).isEqualTo(14);
            assertThat(evaluator.evaluate(activeExpiringAt(NOW.plusSeconds(5 * 24 * 3600)), NOW).level()).isEqualTo(7);
            assertThat(evaluator.evaluate(activeExpiringAt(NOW.plusSeconds(2 * 24 * 3600)), NOW).level()).isEqualTo(3);
        }
    }

    @Nested
    class ThreeComponentConsistency {

        @Test
        void degradedAndExportEligibilityAgreeOnEverySample() {
            var evaluator = new SubscriptionHealthEvaluator(new TerminationAnchorResolver());
            var anchor = new TerminationAnchorResolver();
            var resolver = new TenantSubscriptionResolver(subscriptionRepository, anchor);
            var policy = new SubscriptionExportPolicy(subscriptionRepository, anchor, WINDOW_DAYS);

            samples().forEach(sample -> {
                lenient().when(subscriptionRepository.findByTenantId(TENANT_ID))
                        .thenReturn(Optional.of(sample.subscription()));
                // All samples share one tenant id — evict the resolver's 60s
                // cache so each sample is resolved fresh (first failure here
                // was cache carry-over, a useful reminder the cache exists).
                resolver.evictTenant(TENANT_ID);

                var verdict = evaluator.evaluate(sample.subscription(), NOW);
                var resolverSnapshot = resolver.resolve(TENANT_ID);
                var policyDecision = policy.assess(TENANT_ID, NOW);

                // Degraded (terminated) ⇔ resolver hands out the basic tier.
                assertThat(resolverSnapshot.tier())
                        .as("resolver tier for %s", sample.name())
                        .isEqualTo(verdict.degraded() ? "basic"
                                : verdict.effectiveTier());

                // Terminated ⇔ export channel eligible (inside 30d window).
                // Samples use anchors ≤10 days past, so all eligible.
                assertThat(policyDecision.isEligible())
                        .as("policy eligible for %s", sample.name())
                        .isEqualTo(verdict.terminatedAt() != null);
            });
        }
    }
}
