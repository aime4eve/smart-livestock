package com.smartlivestock.commerce.application.job;

import com.smartlivestock.commerce.application.service.RevenueApplicationService;
import com.smartlivestock.commerce.application.service.SubscriptionApplicationService;
import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.model.ContractStatus;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionService;
import com.smartlivestock.commerce.domain.model.SubscriptionServiceStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionServiceRepository;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionRepository;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionServiceRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.EnumConverters;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

/**
 * Scheduled jobs for the Commerce bounded context.
 *
 * <table>
 *   <tr><th>Job</th><th>Frequency</th><th>Logic</th></tr>
 *   <tr><td>TrialExpiryJob</td><td>hourly</td><td>TRIAL &amp; trialEndsAt &lt; now → expireTrial</td></tr>
 *   <tr><td>SubscriptionExpiryJob</td><td>hourly</td><td>ACTIVE &amp; expiresAt &lt; now → markRenewalFailed</td></tr>
 *   <tr><td>RenewalFailedExpiryJob</td><td>daily 02:00</td><td>RENEWAL_FAILED &gt; 7d → downgrade</td></tr>
 *   <tr><td>HeartbeatCheckJob</td><td>6-hourly</td><td>Reserved MVP no-op</td></tr>
 *   <tr><td>LicenseExpiryJob</td><td>daily 04:00</td><td>ACTIVE license expired → expire</td></tr>
 *   <tr><td>ContractExpiryJob</td><td>daily 05:00</td><td>ACTIVE &amp; expiresAt &lt; now → markExpired</td></tr>
 *   <tr><td>RevenueCalculationJob</td><td>monthly 1st 03:00</td><td>ACTIVE contracts → calculatePeriod</td></tr>
 * </table>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class CommerceScheduler {

    private final SpringDataSubscriptionRepository springDataSubscriptionRepo;
    private final SpringDataSubscriptionServiceRepository springDataSubscriptionServiceRepo;
    private final SubscriptionRepository subscriptionRepository;
    private final SubscriptionServiceRepository subscriptionServiceRepository;
    private final ContractRepository contractRepository;
    private final SubscriptionApplicationService subscriptionAppService;
    private final RevenueApplicationService revenueAppService;
    private final DomainEventPublisher domainEventPublisher;

    // ── 1. TrialExpiryJob — every hour ──────────────────────────────────

    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void expireTrials() {
        List<Subscription> trials = subscriptionRepository.findByStatus(SubscriptionStatus.TRIAL);
        int count = 0;
        for (Subscription sub : trials) {
            if (sub.getTrialEndsAt() != null && sub.getTrialEndsAt().isBefore(Instant.now())) {
                subscriptionAppService.expireTrial(sub.getTenantId());
                count++;
            }
        }
        if (count > 0) {
            log.info("TrialExpiryJob: expired {} trial subscriptions", count);
        }
    }

    // ── 2. SubscriptionExpiryJob — every hour ───────────────────────────

    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void markExpiredSubscriptions() {
        List<Subscription> activeSubs = subscriptionRepository.findByStatus(SubscriptionStatus.ACTIVE);
        int count = 0;
        for (Subscription sub : activeSubs) {
            if (sub.getExpiresAt() != null && sub.getExpiresAt().isBefore(Instant.now())) {
                sub.markRenewalFailed();
                subscriptionRepository.save(sub);
                domainEventPublisher.publishDomainEvents(sub);
                count++;
            }
        }
        if (count > 0) {
            log.info("SubscriptionExpiryJob: marked {} subscriptions as RENEWAL_FAILED", count);
        }
    }

    // ── 3. RenewalFailedExpiryJob — daily at 02:00 ─────────────────────

    @Scheduled(cron = "0 0 2 * * *")
    @Transactional
    public void downgradeAfterRenewalFailure() {
        Instant cutoff = Instant.now().minusSeconds(7 * 86400L);
        var expired = springDataSubscriptionRepo.findByStatusAndUpdatedAtBefore(
                EnumConverters.toDb(SubscriptionStatus.RENEWAL_FAILED), cutoff);
        int count = 0;
        for (var jpaEntity : expired) {
            Subscription sub = subscriptionRepository.findByTenantId(jpaEntity.getTenantId())
                    .orElse(null);
            if (sub == null) {
                continue;
            }
            sub.downgradeAfterRenewalFailure();
            subscriptionRepository.save(sub);
            domainEventPublisher.publishDomainEvents(sub);
            count++;
        }
        if (count > 0) {
            log.info("RenewalFailedExpiryJob: downgraded {} subscriptions to FREE", count);
        }
    }

    // ── 4. HeartbeatCheckJob — every 6 hours (MVP no-op) ───────────────

    @Scheduled(cron = "0 0 */6 * * *")
    public void checkHeartbeats() {
        log.debug("HeartbeatCheckJob: MVP no-op — reserved for future implementation");
    }

    // ── 5. LicenseExpiryJob — daily at 04:00 ────────────────────────────

    @Scheduled(cron = "0 0 4 * * *")
    @Transactional
    public void expireLicenses() {
        var activeServices = springDataSubscriptionServiceRepo.findByStatus(
                EnumConverters.toDb(SubscriptionServiceStatus.ACTIVE));
        int count = 0;
        for (var jpaEntity : activeServices) {
            if (jpaEntity.getExpiresAt() != null && jpaEntity.getExpiresAt().isBefore(Instant.now())) {
                SubscriptionService svc = subscriptionServiceRepository.findById(jpaEntity.getId())
                        .orElse(null);
                if (svc == null) {
                    continue;
                }
                svc.expire();
                subscriptionServiceRepository.save(svc);
                domainEventPublisher.publishDomainEvents(svc);
                count++;
            }
        }
        if (count > 0) {
            log.info("LicenseExpiryJob: expired {} licensed services", count);
        }
    }

    // ── 6. ContractExpiryJob — daily at 05:00 ───────────────────────────

    @Scheduled(cron = "0 0 5 * * *")
    @Transactional
    public void expireContracts() {
        List<Contract> activeContracts = contractRepository.findByStatus(ContractStatus.ACTIVE);
        int count = 0;
        for (Contract contract : activeContracts) {
            if (contract.getExpiresAt() != null && contract.getExpiresAt().isBefore(Instant.now())) {
                contract.markExpired();
                contractRepository.save(contract);
                domainEventPublisher.publishDomainEvents(contract);
                count++;
            }
        }
        if (count > 0) {
            log.info("ContractExpiryJob: expired {} contracts", count);
        }
    }

    // ── 7. RevenueCalculationJob — monthly on the 1st at 03:00 ──────────

    @Scheduled(cron = "0 0 3 1 * *")
    @Transactional
    public void calculateMonthlyRevenue() {
        List<Contract> activeContracts = contractRepository.findByStatus(ContractStatus.ACTIVE);
        YearMonth lastMonth = YearMonth.now().minusMonths(1);
        LocalDate periodStart = lastMonth.atDay(1);
        LocalDate periodEnd = lastMonth.atEndOfMonth();

        int count = 0;
        for (Contract contract : activeContracts) {
            // MVP: gross amount is 0; actual billing integration will provide real amounts
            revenueAppService.calculatePeriod(contract.getId(), periodStart, periodEnd, 0);
            count++;
        }
        if (count > 0) {
            log.info("RevenueCalculationJob: calculated {} revenue periods for {}", count, lastMonth);
        }
    }
}
