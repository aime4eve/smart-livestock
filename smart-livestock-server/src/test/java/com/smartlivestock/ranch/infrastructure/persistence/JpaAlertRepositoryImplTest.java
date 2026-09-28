package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertJpaEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JpaAlertRepositoryImplTest {

    @Mock
    private SpringDataAlertRepository alertRepository;
    @Mock
    private SpringDataAlertReadStatusRepository readStatusRepository;

    private JpaAlertRepositoryImpl repository;

    @BeforeEach
    void setUp() {
        repository = new JpaAlertRepositoryImpl(alertRepository, readStatusRepository);
    }

    @Test
    void saveWritesGeneratedIdBackToCallerOwnedAggregate() {
        Alert alert = new Alert(
                1L, 14L, 3L, AlertType.FENCE_BREACH, Severity.CRITICAL, "outside fence"
        );
        AlertJpaEntity saved = new AlertJpaEntity();
        saved.setId(1703720L);
        saved.setType(AlertType.FENCE_BREACH.name());
        saved.setStatus(com.smartlivestock.ranch.domain.model.AlertStatus.ACTIVE.name());
        saved.setSeverity(Severity.CRITICAL.name());
        when(alertRepository.save(any(AlertJpaEntity.class))).thenReturn(saved);

        Alert result = repository.save(alert);

        assertThat(result.getId()).isEqualTo(1703720L);
        assertThat(alert.getId()).isEqualTo(1703720L);
    }
}
