package com.smartlivestock.analytics.infrastructure.persistence.repository;

import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import com.smartlivestock.analytics.domain.repository.ApiUsageDailyRepository;
import com.smartlivestock.analytics.infrastructure.persistence.jpa.SpringDataApiUsageDailyRepository;
import com.smartlivestock.analytics.infrastructure.persistence.mapper.AnalyticsMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class ApiUsageDailyRepositoryImpl implements ApiUsageDailyRepository {
    private final SpringDataApiUsageDailyRepository springDataRepo;

    @Override
    public ApiUsageDaily save(ApiUsageDaily daily) {
        return AnalyticsMapper.toDomain(springDataRepo.save(AnalyticsMapper.toJpa(daily)));
    }

    @Override
    public List<ApiUsageDaily> findByTenantIdAndUsageDateBetween(Long tenantId, LocalDate from, LocalDate to) {
        return springDataRepo.findByTenantIdAndUsageDateBetween(tenantId, from, to)
                .stream().map(AnalyticsMapper::toDomain).toList();
    }

    @Override
    public List<ApiUsageDaily> findByApiKeyIdAndUsageDateBetween(Long apiKeyId, LocalDate from, LocalDate to) {
        return springDataRepo.findByApiKeyIdAndUsageDateBetween(apiKeyId, from, to)
                .stream().map(AnalyticsMapper::toDomain).toList();
    }
}
