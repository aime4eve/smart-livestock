package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.infrastructure.persistence.FarmSignalRevisionJpaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SignalRevisionServiceTest {

    @Mock
    private FarmSignalRevisionJpaRepository revisionRepository;
    @Mock
    private NamedParameterJdbcTemplate jdbcTemplate;

    private SignalRevisionService service;

    @BeforeEach
    void setUp() {
        service = new SignalRevisionService(revisionRepository, jdbcTemplate);
    }

    @Test
    void bumpStatusUsesAtomicReturningUpdate() {
        when(revisionRepository.findById(1L)).thenReturn(Optional.empty());
        when(revisionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(jdbcTemplate.queryForObject(
                contains("status_revision"),
                any(org.springframework.jdbc.core.namedparam.MapSqlParameterSource.class),
                eq(Long.class)
        ))
                .thenReturn(42L);

        long revision = service.bumpStatus(1L);

        assertThat(revision).isEqualTo(42L);
        verify(jdbcTemplate).queryForObject(
                contains("RETURNING status_revision"),
                any(org.springframework.jdbc.core.namedparam.MapSqlParameterSource.class),
                eq(Long.class)
        );
    }

    @Test
    void rejectsAheadCursorWithDedicatedException() {
        SignalRevisionService.FarmSignalRevision revision = new SignalRevisionService.FarmSignalRevision(
                1L, 8L, 8L, 8L, Instant.now()
        );

        assertThatThrownBy(() -> service.validateListCursor(revision, 9L))
                .isInstanceOf(SignalCursorInvalidException.class);
    }

    @Test
    void rejectsStaleCursorWithDedicatedException() {
        Instant old = Instant.now().minusSeconds(25 * 3600);
        SignalRevisionService.FarmSignalRevision revision = new SignalRevisionService.FarmSignalRevision(
                1L, 8L, 8L, 8L, old
        );

        assertThatThrownBy(() -> service.validateListCursor(revision, 8L))
                .isInstanceOf(SignalCursorTooOldException.class);
    }
}
